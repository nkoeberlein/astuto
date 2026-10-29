require 'rails_helper'

RSpec.describe 'SAML single sign-on', type: :request do
  include SamlHelper

  let(:base) { 'http://www.example.com' }
  let(:acs) { "#{base}/saml/acs" }
  let(:entity) { "#{base}/saml/metadata" }
  let!(:config) do
    SamlConfig.create!(
      enabled: true, label: 'Company login', idp_entity_id: SamlHelper::ISSUER,
      idp_sso_url: 'https://idp.example.com/sso', idp_cert: SamlHelper.certificate.to_pem
    )
  end

  before { allow(Rails.application).to receive(:base_url).and_return(base) }

  def start_login(return_to: nil)
    get '/saml/start', params: { return_to: return_to }.compact
    expect(response.location).to start_with('https://idp.example.com/sso?')
    saml_request_id(response.location)
  end

  def post_response(request_id, relay_state, **options)
    post '/saml/acs', params: {
      SAMLResponse: saml_response(destination: acs, audience: entity, in_response_to: request_id, email: 'ada@example.com', **options),
      RelayState: relay_state
    }
  end

  def signed_in_email
    get '/api/app/v1/session'
    response.parsed_body.dig('user', 'email')
  end

  it 'publishes the service provider metadata' do
    get '/saml/metadata'
    expect(response.body).to include(entity, "Location='#{acs}'")
  end

  it 'creates the account on the first login and returns to the page' do
    request_id, relay = start_login(return_to: '/roadmap')
    post_response(request_id, relay)
    expect(response.location).to start_with("#{base}/saml/finish?token=")

    get response.location
    expect(response).to redirect_to('/roadmap')
    expect(signed_in_email).to eq('ada@example.com')
    expect(User.find_by(email: 'ada@example.com')).to have_attributes(full_name: 'Ada Lovelace', has_set_password: false)
  end

  it 'refuses responses signed by another key' do
    request_id, relay = start_login
    post_response(request_id, relay, sign_with: OpenSSL::PKey::RSA.new(2048))

    expect(response).to redirect_to('/login')
    expect(signed_in_email).to be_nil
  end

  it 'refuses responses to another request, expired ones and foreign audiences' do
    _request_id, relay = start_login
    post_response('_other', relay)
    expect(response).to redirect_to('/login')

    request_id, relay = start_login
    post_response(request_id, relay, expires_at: 5.minutes.ago)
    expect(response).to redirect_to('/login')

    request_id, relay = start_login
    post '/saml/acs', params: {
      SAMLResponse: saml_response(destination: acs, audience: 'https://other.example', in_response_to: request_id, email: 'ada@example.com'),
      RelayState: relay
    }
    expect(response).to redirect_to('/login')
    expect(signed_in_email).to be_nil
  end

  it 'does not sign in a browser that did not start the login (login CSRF)' do
    request_id, relay = start_login
    post_response(request_id, relay)
    finish = response.location

    reset!
    allow(Rails.application).to receive(:base_url).and_return(base)
    get finish
    expect(response).to redirect_to('/login')
    expect(signed_in_email).to be_nil
  end

  it 'only signs in existing accounts without automatic creation, and never blocked ones' do
    config.update!(auto_create_users: false)
    request_id, relay = start_login
    post_response(request_id, relay)
    expect(response).to redirect_to('/login')

    FactoryBot.create(:user, email: 'ada@example.com', status: 'blocked').tap(&:confirm)
    request_id, relay = start_login
    post_response(request_id, relay)
    expect(response).to redirect_to('/login')
  end

  it 'asks for the two-factor code when the account has it' do
    user = FactoryBot.create(:user, email: 'ada@example.com').tap(&:confirm)
    user.start_two_factor_setup!
    codes = user.enable_two_factor!(ROTP::TOTP.new(user.reload.otp_secret).now)

    request_id, relay = start_login
    post_response(request_id, relay)
    get response.location
    expect(response).to redirect_to('/login?two_factor=1')
    expect(signed_in_email).to be_nil

    post '/api/app/v1/session/two_factor', params: { code: codes.first }, as: :json
    expect(response).to have_http_status(:ok)
  end

  it 'is listed as a sign-in provider and can be switched off' do
    get '/api/app/v1/session'
    expect(response.parsed_body.dig('tenant', 'oauthProviders')).to include(include('name' => 'Company login', 'startUrl' => '/saml/start'))

    config.update!(enabled: false)
    get '/saml/start'
    expect(response).to have_http_status(:not_found)
  end
end
