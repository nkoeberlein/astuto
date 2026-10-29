class OAuthsController < ApplicationController
  include HTTParty
  include OAuthsHelper
  include ApplicationHelper
  include Devise::Controllers::Rememberable

  TOKEN_STATE_SEPARATOR = ','

  # [subdomain.]base_url/o_auths/:id/start?reason=login|test[&return_to=/local/path]
  # Generates authorize url with required parameters and redirects to provider
  def start
    @o_auth = OAuth.include_defaults.friendly.find(params[:id])

    return oauth_login_failed(@o_auth.name) if params[:reason] != 'test' and not @o_auth.is_enabled?

    # Generate random state + other query params
    tenant_domain = Current.tenant ? Current.tenant_or_raise!.subdomain : "null"
    token_state = "#{params[:reason]}#{TOKEN_STATE_SEPARATOR}#{tenant_domain}#{TOKEN_STATE_SEPARATOR}#{Devise.friendly_token(30)}"
    unless params[:reason] == 'test'
      cookie_options = {
        value: token_state,
        httponly: true,
        secure: request.ssl?,
        same_site: :lax
      }
      cookie_options[:domain] = oauth_cookie_domain if oauth_cookie_domain
      cookies[:token_state] = cookie_options

      # Page to return to after sign-in. It travels in a cookie (like token_state)
      # because the callback may run on another host than this request.
      if params[:reason] == 'login' && SafeUrl.local_path?(params[:return_to])
        cookies[:oauth_return_to] = cookie_options.merge(value: params[:return_to])
      else
        # Drop a target left over from an abandoned earlier attempt
        cookies.delete(:oauth_return_to, domain: cookie_options[:domain])
      end
    end
    @o_auth.state = token_state

    redirect_to @o_auth.authorize_url_with_query_params, allow_other_host: true
  end

  # [subdomain.]base_url/o_auths/:id/callback
  # Exchange authorization code for access token, fetch user info and sign in/up
  def callback
    reason, tenant_domain, token_state = params[:state].split(TOKEN_STATE_SEPARATOR, 3)

    unless reason == "test"
      # Started on a custom domain: the callback runs on the subdomain (or login.) host, where
      # the browser has no token_state cookie. Finish on the custom domain, which has it.
      return redirect_to_custom_domain_callback(tenant_domain) if cookies[:token_state] != params[:state] && custom_domain_callback?(tenant_domain)
      return oauth_login_failed unless cookies[:token_state] == params[:state]
      cookies.delete(:token_state, domain: oauth_cookie_domain)
      return_to = cookies[:oauth_return_to]
      cookies.delete(:oauth_return_to, domain: oauth_cookie_domain)
    end

    # if it is a default oauth, tenant is not yet set
    Current.tenant ||= Tenant.find_by(subdomain: tenant_domain)

    @o_auth = OAuth.include_defaults.friendly.find(params[:id])

    return oauth_login_failed(@o_auth.name) if reason != 'test' and not @o_auth.is_enabled?

    user_profile = OAuthExchangeAuthCodeForProfileWorkflow.new(
      authorization_code: params[:code],
      o_auth: @o_auth
    ).run

    if reason == 'login'

      user = OAuthSignInUserWorkflow.new(
        user_profile: user_profile,
        o_auth: @o_auth
      ).run

      if user
        oauth_token = user.generate_oauth_token
        options = { user_id: user.id, token: oauth_token }
        options[:return_to] = return_to if SafeUrl.local_path?(return_to)
        redirect_to get_url_for(method(:o_auth_sign_in_from_oauth_token_url), options: options), allow_other_host: true
      else
        flash[:alert] = I18n.t('errors.o_auth_login_error', name: @o_auth.name)
        redirect_to get_url_for(method(:new_user_session_url)), allow_other_host: true
      end

    elsif reason == 'test'

      unless user_signed_in? and current_user.admin?
        flash[:alert] = I18n.t('errors.unauthorized')
        redirect_to get_url_for(method(:root_url)), allow_other_host: true
        return
      end

      @user_profile = user_profile
      @user_email = query_path_from_object(user_profile, @o_auth.json_user_email_path)
      @email_valid = URI::MailTo::EMAIL_REGEXP.match?(@user_email)
      if not @o_auth.json_user_name_path.blank?
        @user_name = query_path_from_object(user_profile, @o_auth.json_user_name_path)
        @name_valid = !@user_name.nil?
      end

      render 'o_auths/test', layout: false

    else

      flash[:alert] = I18n.t('errors.unknown')
      redirect_to root_url

    end
  end

  # [subdomain.]base_url/o_auths/sign_in_from_oauth_token?user_id=<id>&token=<token>[&return_to=/local/path]
  # Used for OAuth with reason 'login'
  # It has been introduced because of default OAuth providers,
  # since they must redirect to a common domain for all tenants.
  def sign_in_from_oauth_token
    return unless params[:user_id] and params[:token]

    user = User.find(params[:user_id])

    if user.oauth_token == params[:token]
      sign_in user
      remember_me user
      user.invalidate_oauth_token
      flash[:notice] = I18n.t('devise.sessions.signed_in')

      redirect_to SafeUrl.local_path?(params[:return_to]) ? params[:return_to] : after_sign_in_path_for(user)
    else
      flash[:alert] = I18n.t('errors.o_auth_login_error', name: 'OAuth')
      redirect_to new_user_session_path
    end
  end

  private

    # Wrong or missing state (an old or foreign link, cookies blocked) or a disabled provider
    def oauth_login_failed(name = 'OAuth')
      flash[:alert] = I18n.t('errors.o_auth_login_error', name: name)
      redirect_to get_url_for(method(:new_user_session_url)), allow_other_host: true
    end

    # Subdomains share the cookies with login.<BASE_URL host>, where default providers call back.
    # A custom domain gets a host-only cookie (".#{request.domain}" could be ".co.uk").
    def oauth_cookie_domain
      return unless Rails.application.multi_tenancy?

      base_host = Rails.application.base_url_host.downcase
      host = request.host.to_s.downcase
      ".#{base_host}" if host == base_host || host.end_with?(".#{base_host}")
    end

    def custom_domain_callback?(tenant_domain)
      tenant = Tenant.find_by(subdomain: tenant_domain)
      tenant&.custom_domain.present? && request.host.to_s.downcase != tenant.custom_domain
    end

    # Same path and query (code, state) on the custom domain. The provider's redirect_uri stays
    # the subdomain URL (OAuth#callback_url), so the code exchange there still matches.
    def redirect_to_custom_domain_callback(tenant_domain)
      tenant = Tenant.find_by(subdomain: tenant_domain)
      url = Current.set(tenant: tenant) do
        get_url_for(method(:o_auth_callback_url), resource: params[:id], options: request.query_parameters.symbolize_keys)
      end
      redirect_to url, allow_other_host: true
    end
end
