require 'rails_helper'

# Logins go through the app API (the Devise HTML form is gone); Lockable counts wrong passwords
# and wrong two-factor codes alike
RSpec.describe 'Account lockout (Devise :lockable)', type: :request do
  let(:password) { 'password123' }
  let(:user) do
    FactoryBot.create(:user, password: password, password_confirmation: password).tap(&:confirm)
  end

  def sign_in_with(given_password)
    post '/api/app/v1/session', params: { email: user.email, password: given_password }, as: :json
    user.reload
  end

  def fail_sign_in!
    sign_in_with('wrong-password')
  end

  def lock!
    (Devise.maximum_attempts - user.reload.failed_attempts).times do
      user.valid_for_authentication? { false }
    end
    user.reload
  end

  describe 'login (/api/app/v1/session)' do
    it 'does not lock before maximum_attempts failed attempts' do
      (Devise.maximum_attempts - 1).times { fail_sign_in! }

      expect(user).not_to be_access_locked
    end

    it 'locks the account at maximum_attempts failed attempts' do
      Devise.maximum_attempts.times { fail_sign_in! }

      expect(user).to be_access_locked
    end

    it 'rejects the correct password with the locked message' do
      lock!
      sign_in_with(password)

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error']).to eq(I18n.t('devise.failure.locked'))
    end

    it 'does not count a successful sign-in towards the lock' do
      (Devise.maximum_attempts - 1).times { fail_sign_in! }
      sign_in_with(password)

      expect(response).to have_http_status(:ok)
      expect(user.failed_attempts).to eq(0)
    end

    it 'no longer accepts passwords at the old Devise form' do
      post '/users/sign_in', params: { user: { email: user.email, password: password } }

      expect(response).to redirect_to('/login')
      get '/api/app/v1/session'
      expect(response.parsed_body['user']).to be_nil
    end
  end

  describe 'unlock via emailed link (/users/unlock)' do
    before { lock! }

    it 'unlocks the account using the token from the unlock email' do
      # send_unlock_instructions returns the raw token the email link contains
      # (only its digest is stored on the user record)
      raw_token = user.send_unlock_instructions

      get "/users/unlock?unlock_token=#{raw_token}"
      follow_redirect!

      expect(flash[:notice]).to eq(I18n.t('devise.unlocks.unlocked'))
      expect(user.reload).not_to be_access_locked
      expect(user.reload.failed_attempts).to eq(0)
    end

    it 'does not unlock with an invalid token' do
      get '/users/unlock?unlock_token=no-such-token'

      expect(user.reload).to be_access_locked
    end
  end

  describe 'unlock by time' do
    it 'allows sign-in again once the lock has expired' do
      Devise.maximum_attempts.times { fail_sign_in! }
      user.update_column(:locked_at, Devise.unlock_in.ago - 1.minute)

      sign_in_with(password)

      expect(response).to have_http_status(:ok)
      expect(user).not_to be_access_locked
    end
  end
end
