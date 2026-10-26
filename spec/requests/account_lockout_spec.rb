require 'rails_helper'

RSpec.describe 'Account lockout (Devise :lockable)', type: :request do
  let(:password) { 'password123' }
  let(:user) do
    FactoryBot.create(:user, password: password, password_confirmation: password).tap(&:confirm)
  end

  # Signs in with a wrong password through the legacy form and reloads,
  # so the request-level Lockable logic (Warden strategy) is exercised.
  def fail_sign_in!
    post '/users/sign_in', params: { user: { email: user.email, password: 'wrong-password' } }
    user.reload
  end

  # Locks the user directly at model level, to set up state for HTTP assertions
  def lock!
    (Devise.maximum_attempts - user.reload.failed_attempts).times do
      user.valid_for_authentication? { false }
    end
    user.reload
  end

  describe 'legacy sign-in (/users/sign_in)' do
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

      # Lockable's unauthenticated_message → Devise failure app recalls the
      # sign-in form (200) and shows the locked message via flash
      post '/users/sign_in', params: { user: { email: user.email, password: password } }

      expect(response.status).to eq(200)
      expect(flash[:alert]).to eq(I18n.t('devise.failure.locked'))
    end

    it 'does not count a successful sign-in towards the lock' do
      (Devise.maximum_attempts - 1).times { fail_sign_in! }

      post '/users/sign_in', params: { user: { email: user.email, password: password } }

      expect(user.reload.failed_attempts).to eq(0)
      expect(user).not_to be_access_locked
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

      post '/users/sign_in', params: { user: { email: user.email, password: password } }

      expect(user.reload).not_to be_access_locked
      expect(flash[:notice]).to eq(I18n.t('devise.sessions.signed_in'))
    end
  end
end