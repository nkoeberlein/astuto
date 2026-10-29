# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OAuth token_state cookie (#472, #478)', type: :request do
  let(:tenant) { Tenant.first || FactoryBot.create(:tenant) }
  let(:o_auth) do
    Current.tenant = tenant
    FactoryBot.create(
      :o_auth,
      tenant: tenant,
      is_enabled: true,
      authorize_url: 'https://idp.example.com/oauth/authorize'
    )
  end

  before do
    Current.tenant = tenant
  end

  it 'omits domain attribute in single-tenant mode and sets HttpOnly and SameSite=Lax (#472)' do
    allow(Rails.application).to receive(:multi_tenancy?).and_return(false)

    get o_auth_start_path(o_auth)

    expect(response).to have_http_status(:found)
    set_cookie_header = Array(response.headers['Set-Cookie']).join("\n")
    expect(set_cookie_header).to include('token_state=')
    expect(set_cookie_header).to match(/httponly/i)
    expect(set_cookie_header).to match(/samesite=lax/i)
    expect(set_cookie_header).not_to match(/domain=/i)
  end

  it 'generates an https callback_url when ASSUME_SSL=true behind a reverse proxy (#478)' do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ASSUME_SSL', 'false').and_return('true')

    expect(o_auth.callback_url).to start_with('https://')
  end

  describe 'return_to after OAuth login' do
    let(:user) { FactoryBot.create(:user).tap(&:confirm) }

    def set_cookies
      Array(response.headers['Set-Cookie']).join("\n")
    end

    it 'keeps a local return_to in a cookie and ignores other hosts' do
      get o_auth_start_path(o_auth, reason: 'login', return_to: '/posts/1')
      expect(set_cookies).to include('oauth_return_to=%2Fposts%2F1')

      get o_auth_start_path(o_auth, reason: 'login', return_to: 'evil.com')
      expect(set_cookies).not_to include('oauth_return_to=evil.com')
      expect(session[:return_to]).to be_nil
    end

    it 'hands the cookie target to sign_in_from_oauth_token after the callback' do
      state = "login,#{tenant.subdomain},abc123"
      cookies[:token_state] = state
      cookies[:oauth_return_to] = '/posts/1'
      exchange = instance_double(OAuthExchangeAuthCodeForProfileWorkflow, run: {})
      allow(OAuthExchangeAuthCodeForProfileWorkflow).to receive(:new).and_return(exchange)
      allow(OAuthSignInUserWorkflow).to receive(:new).and_return(instance_double(OAuthSignInUserWorkflow, run: user))

      get o_auth_callback_path(o_auth, state: state, code: 'code')

      expect(response).to have_http_status(:found)
      expect(response.location).to include('return_to=%2Fposts%2F1')
    end

    it 'redirects to a local return_to after signing in, and never to another host' do
      token = user.generate_oauth_token
      get o_auth_sign_in_from_oauth_token_path(user_id: user.id, token: token, return_to: '/posts/1')
      expect(response).to redirect_to('/posts/1')

      token = user.reload.generate_oauth_token
      get o_auth_sign_in_from_oauth_token_path(user_id: user.id, token: token, return_to: 'https://evil.com')
      expect(response.location).not_to include('evil.com')
    end
  end

  describe 'multi-tenancy and custom domains (#472)' do
    let(:acme) { Tenant.create!(site_name: 'Acme', subdomain: 'acme', status: 'active', custom_domain: 'ideas.acme.co.uk') }
    let(:acme_o_auth) do
      Current.set(tenant: acme) do
        FactoryBot.create(:o_auth, tenant: acme, is_enabled: true, authorize_url: 'https://idp.example.com/oauth/authorize')
      end
    end
    let(:user) { Current.set(tenant: acme) { FactoryBot.create(:user, tenant: acme).tap(&:confirm) } }

    before do
      allow(Rails.application).to receive(:multi_tenancy?).and_return(true)
      allow(Rails.application).to receive(:base_url).and_return('https://feedback.example.com')
      Current.set(tenant: acme) { TenantSetting.create!(tenant: acme) }
    end

    def set_cookies
      Array(response.headers['Set-Cookie']).join("\n")
    end

    it 'shares the cookie with the BASE_URL host on subdomains and keeps it host-only on custom domains' do
      host! 'acme.feedback.example.com'
      get o_auth_start_path(acme_o_auth, reason: 'login')
      expect(set_cookies).to match(/token_state=.*domain=\.feedback\.example\.com/i)

      host! 'ideas.acme.co.uk'
      get o_auth_start_path(acme_o_auth, reason: 'login')
      expect(set_cookies).to include('token_state=')
      expect(set_cookies).not_to match(/domain=/i)
    end

    it 'finishes a login started on the custom domain there' do
      state = "login,acme,abc123"

      # The provider calls back on the subdomain, where the browser has no cookie
      host! 'acme.feedback.example.com'
      get o_auth_callback_path(acme_o_auth, state: state, code: 'the-code')
      expect(response.location).to start_with("https://ideas.acme.co.uk/o_auths/#{acme_o_auth.to_param}/callback?")
      expect(response.location).to include('code=the-code', "state=#{CGI.escape(state)}")

      # On the custom domain the cookie is there and the login goes on
      exchange = instance_double(OAuthExchangeAuthCodeForProfileWorkflow, run: {})
      allow(OAuthExchangeAuthCodeForProfileWorkflow).to receive(:new).and_return(exchange)
      allow(OAuthSignInUserWorkflow).to receive(:new).and_return(instance_double(OAuthSignInUserWorkflow, run: user))
      host! 'ideas.acme.co.uk'
      get o_auth_callback_path(acme_o_auth, state: state, code: 'the-code'), headers: { 'Cookie' => "token_state=#{CGI.escape(state)}" }
      expect(response.location).to start_with('https://ideas.acme.co.uk/o_auths/sign_in_from_oauth_token')
    end

    it 'sends a callback with a foreign state back to the login page, without a loop' do
      host! 'ideas.acme.co.uk'
      get o_auth_callback_path(acme_o_auth, state: 'login,acme,abc123', code: 'the-code'), headers: { 'Cookie' => 'token_state=login%2Cacme%2Cother' }
      expect(response.location).to eq('https://ideas.acme.co.uk/users/sign_in')
      expect(flash[:alert]).to be_present
    end
  end
end
