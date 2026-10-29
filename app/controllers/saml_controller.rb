# SAML 2.0 single sign-on (docs/sso.md). Astuto is the service provider:
#   GET  /saml/metadata  SP metadata for the identity provider (entity ID, ACS URL)
#   GET  /saml/start     sends the browser to the IdP with a signed RelayState
#   POST /saml/acs       the IdP posts the signed response here (cross-site, so without the
#                        session cookie); a valid response turns into a short-lived login token
#   GET  /saml/finish    on the host where the login started: checks the nonce in the session
#                        and signs in (or asks for the two-factor code)
# Entity ID and ACS URL use the subdomain host, like OAuth callbacks, so they stay stable when a
# custom domain is added; a login started on the custom domain finishes there.
class SamlController < ApplicationController
  include TwoFactorLogin
  include Devise::Controllers::Rememberable

  skip_forgery_protection only: :acs

  before_action :require_saml, except: :metadata

  TOKEN_LIFETIME = 2.minutes

  def metadata
    settings = saml_config.saml_settings(sp_entity_id: sp_entity_id, acs_url: acs_url)
    render xml: OneLogin::RubySaml::Metadata.new.generate(settings, true)
  end

  def start
    nonce = SecureRandom.urlsafe_base64(24)
    session[:saml_nonce] = nonce
    request_object = OneLogin::RubySaml::Authrequest.new
    relay_state = verifier.generate(
      { 'nonce' => nonce, 'request_id' => request_object.uuid, 'host' => request.host,
        'return_to' => (params[:return_to] if SafeUrl.local_path?(params[:return_to])) },
      purpose: :saml_relay_state, expires_in: 15.minutes
    )
    redirect_to request_object.create(settings, RelayState: relay_state), allow_other_host: true
  end

  def acs
    relay = verifier.verified(params[:RelayState].to_s, purpose: :saml_relay_state)
    return login_failed('invalid relay state') unless relay.is_a?(Hash)

    response = OneLogin::RubySaml::Response.new(
      params[:SAMLResponse].to_s, settings: settings, matches_request_id: relay['request_id'], allowed_clock_drift: 60.seconds
    )
    return login_failed(response.errors.join('; ')) unless response.is_valid?

    user = SamlSignInWorkflow.new(config: saml_config, response: response).run
    return login_failed('no matching account') unless user

    token = verifier.generate(
      { 'user_id' => user.id, 'nonce' => relay['nonce'], 'return_to' => relay['return_to'] },
      purpose: :saml_login, expires_in: TOKEN_LIFETIME
    )
    redirect_to finish_url_for(relay['host'], token), allow_other_host: true
  end

  def finish
    payload = verifier.verified(params[:token].to_s, purpose: :saml_login)
    nonce = session.delete(:saml_nonce)
    # The nonce binds the login to the browser that started it (no login CSRF)
    unless payload.is_a?(Hash) && nonce.present? && ActiveSupport::SecurityUtils.secure_compare(nonce, payload['nonce'].to_s)
      return login_failed('login not started in this browser')
    end

    user = User.find_by(id: payload['user_id'])
    return login_failed('account gone') unless user&.active_for_authentication?

    return_to = payload['return_to'] if SafeUrl.local_path?(payload['return_to'])
    if user.two_factor_enabled?
      start_two_factor_login(user, remember: true)
      return redirect_to spa_login_path({ two_factor: 1, redirect: return_to }.compact)
    end

    sign_in(:user, user)
    remember_me(user)
    flash[:notice] = I18n.t('devise.sessions.signed_in')
    redirect_to return_to || root_path
  end

  private

    def saml_config
      @saml_config ||= SamlConfig.current
    end

    def require_saml
      head :not_found unless saml_config.usable?
    end

    def settings
      saml_config.saml_settings(sp_entity_id: sp_entity_id, acs_url: acs_url)
    end

    def sp_entity_id
      get_url_for(method(:saml_metadata_url), disallow_custom_domain: true)
    end

    def acs_url
      get_url_for(method(:saml_acs_url), disallow_custom_domain: true)
    end

    # Back to the host the login started on: the custom domain if it was that, else the subdomain
    def finish_url_for(host, token)
      custom = Current.tenant&.custom_domain.present? && host == Current.tenant.custom_domain
      get_url_for(method(:saml_finish_url), disallow_custom_domain: !custom, options: { token: token })
    end

    def verifier
      Rails.application.message_verifier(:saml)
    end

    def login_failed(reason)
      Rails.logger.warn { "[saml] login failed for #{Current.tenant&.subdomain}: #{reason}" }
      flash[:alert] = I18n.t('errors.o_auth_login_error', name: saml_config.label)
      redirect_to spa_login_path
    end
end
