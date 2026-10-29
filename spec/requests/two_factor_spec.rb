require 'rails_helper'

RSpec.describe 'Two-factor authentication', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:password) { 'password123' }
  let(:user) { FactoryBot.create(:moderator, password: password, password_confirmation: password).tap(&:confirm) }

  def code_for(user, at: Time.current)
    ROTP::TOTP.new(user.reload.otp_secret).at(at)
  end

  def enable_two_factor(user)
    user.start_two_factor_setup!
    user.enable_two_factor!(code_for(user))
  end

  def login
    post '/api/app/v1/session', params: { email: user.email, password: password }, as: :json
  end

  def session_user
    get '/api/app/v1/session'
    response.parsed_body['user']
  end

  describe 'setup in the profile' do
    before { sign_in user }

    it 'needs the password, shows a QR code, and turns on with a valid code' do
      post '/api/app/v1/profile/two_factor', params: { currentPassword: 'wrong' }, as: :json
      expect(response).to have_http_status(:unprocessable_content)

      post '/api/app/v1/profile/two_factor', params: { currentPassword: password }, as: :json
      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body['otpauthUri']).to start_with('otpauth://totp/')
      expect(body['qrCode']).to start_with('data:image/svg+xml;base64,')
      expect(user.reload).not_to be_two_factor_enabled

      post '/api/app/v1/profile/two_factor/confirm', params: { code: '000000' }, as: :json
      expect(response).to have_http_status(:unprocessable_content)

      post '/api/app/v1/profile/two_factor/confirm', params: { code: code_for(user) }, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['backupCodes'].size).to eq(10)
      expect(user.reload).to be_two_factor_enabled
      expect(user.otp_secret_ciphertext).not_to include(user.otp_secret)
      expect(AuditEvent.last.action).to eq('user.two_factor_enable')
    end

    it 'turns off with the password' do
      enable_two_factor(user)
      delete '/api/app/v1/profile/two_factor', params: { currentPassword: password }, as: :json
      expect(response).to have_http_status(:no_content)
      expect(user.reload).not_to be_two_factor_enabled
    end
  end

  describe 'login' do
    let!(:backup_codes) { enable_two_factor(user) }

    it 'asks for the code after the password and signs in only with it' do
      login
      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body).to eq('twoFactorRequired' => true)
      expect(session_user).to be_nil

      post '/api/app/v1/session/two_factor', params: { code: '123456' }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(session_user).to be_nil

      travel 31.seconds do
        post '/api/app/v1/session/two_factor', params: { code: code_for(user) }, as: :json
      end
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('user', 'id')).to eq(user.id)
    end

    it 'accepts each backup code once' do
      login
      post '/api/app/v1/session/two_factor', params: { code: backup_codes.first.upcase }, as: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.backup_codes_left).to eq(9)

      delete '/api/app/v1/session'
      login
      post '/api/app/v1/session/two_factor', params: { code: backup_codes.first }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'does not accept the same app code twice' do
      code = nil
      travel_to(1.minute.from_now) do
        code = code_for(user)
        login
        post '/api/app/v1/session/two_factor', params: { code: code }, as: :json
        expect(response).to have_http_status(:ok)
        delete '/api/app/v1/session'

        login
        post '/api/app/v1/session/two_factor', params: { code: code }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'locks the account after too many wrong codes' do
      login
      Devise.maximum_attempts.times do
        post '/api/app/v1/session/two_factor', params: { code: '000000' }, as: :json
      end
      expect(user.reload).to be_access_locked
    end

    it 'expires the second step after a few minutes' do
      login
      travel 6.minutes do
        post '/api/app/v1/session/two_factor', params: { code: code_for(user) }, as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['error']).to eq(I18n.t('two_factor.login_expired'))
      end
    end

    it 'does not sign in after a password reset' do
      token = user.send(:set_reset_password_token)
      patch '/api/app/v1/password', params: { resetPasswordToken: token, password: 'newpassword1', passwordConfirmation: 'newpassword1' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('session', 'user')).to be_nil
    end

    it 'asks for the code after an OAuth login too' do
      token = user.generate_oauth_token
      get "/o_auths/sign_in_from_oauth_token?user_id=#{user.id}&token=#{token}&return_to=/roadmap"
      expect(response).to redirect_to('/login?redirect=%2Froadmap&two_factor=1')
      expect(session_user).to be_nil

      post '/api/app/v1/session/two_factor', params: { code: backup_codes.last }, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'required for staff' do
    before { Current.tenant.tenant_setting.update!(require_two_factor_for_staff: true) }

    it 'keeps moderators out of moderation until they set it up' do
      sign_in user
      get '/api/app/v1/moderation/users'
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body['error']).to eq(I18n.t('two_factor.setup_required'))
      expect(session_user['twoFactorSetupRequired']).to be(true)

      enable_two_factor(user)
      get '/api/app/v1/moderation/users'
      expect(response).to have_http_status(:ok)
      expect(session_user['twoFactorSetupRequired']).to be(false)
    end

    it 'does not affect normal users' do
      sign_in FactoryBot.create(:user).tap(&:confirm)
      expect(session_user['twoFactorSetupRequired']).to be(false)
    end
  end
end
