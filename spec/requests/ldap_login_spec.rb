require 'rails_helper'

RSpec.describe 'LDAP login', type: :request do
  let!(:config) do
    LdapConfig.create!(enabled: true, label: 'Acme account', host: 'ldap.example.com', base_dn: 'dc=example,dc=com')
  end
  let(:ada) { LdapConfig::Result.new(email: 'ada@example.com', name: 'Ada Lovelace', dn: 'uid=ada,dc=example,dc=com') }

  def login(password: 'adasecret')
    post '/api/app/v1/session/ldap', params: { login: 'ada', password: password }, as: :json
  end

  before do
    allow_any_instance_of(LdapConfig).to receive(:authenticate) { |_config, _login, password| password == 'adasecret' ? ada : nil }
  end

  it 'is announced in the session and creates the account on the first login' do
    get '/api/app/v1/session'
    expect(response.parsed_body.dig('tenant', 'ldapLabel')).to eq('Acme account')

    login
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('user', 'email')).to eq('ada@example.com')
    expect(User.find_by(email: 'ada@example.com')).to have_attributes(full_name: 'Ada Lovelace', has_set_password: false)
  end

  it 'gives one message for wrong credentials' do
    login(password: 'wrong')
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body['error']).to eq(I18n.t('ldap.invalid_login', label: 'Acme account'))
  end

  it 'confirms existing unconfirmed accounts, refuses blocked ones and asks for the 2FA code' do
    user = FactoryBot.create(:user, email: 'ada@example.com', confirmed_at: nil)
    login
    expect(response).to have_http_status(:ok)
    expect(user.reload).to be_confirmed
    delete '/api/app/v1/session'

    user.update!(status: 'blocked')
    login
    expect(response).to have_http_status(:forbidden)

    user.update!(status: 'active')
    user.start_two_factor_setup!
    user.enable_two_factor!(ROTP::TOTP.new(user.reload.otp_secret).now)
    login
    expect(response).to have_http_status(:accepted)
  end

  it 'only admits existing accounts without automatic creation' do
    config.update!(auto_create_users: false)
    login
    expect(response).to have_http_status(:unauthorized)
  end

  it 'does not exist while switched off' do
    config.update!(enabled: false)
    login
    expect(response).to have_http_status(:not_found)
  end

  describe 'settings' do
    let(:admin) { FactoryBot.create(:admin).tap(&:confirm) }
    before { sign_in admin }

    it 'never sends the service password and keeps it when left blank' do
      patch '/api/app/v1/site_settings/ldap', params: { bindDn: 'cn=service,dc=example,dc=com', bindPassword: 'servicesecret' }, as: :json
      expect(response.parsed_body).to include('bindPasswordSet' => true)
      expect(response.body).not_to include('servicesecret')

      patch '/api/app/v1/site_settings/ldap', params: { port: 636, encryption: 'simple_tls', bindPassword: '' }, as: :json
      expect(config.reload.bind_password).to eq('servicesecret')
      expect(AuditEvent.where(action: 'ldap.update').pluck(:field_changes).to_json).not_to include('servicesecret')
    end
  end
end
