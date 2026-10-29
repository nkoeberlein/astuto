require 'swagger_helper'

RSpec.describe 'api/app/v1 authentication (Devise JSON & OAuth)', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:user) { FactoryBot.create(:user, password: 'password123', password_confirmation: 'password123').tap(&:confirm) }

  path '/api/app/v1/session' do
    post('Log in with email and password') do
      tags 'Session'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :login_input, in: :body, schema: { '$ref' => '#/components/schemas/LoginInput' }

      response(200, 'signed in successfully') do
        schema '$ref' => '#/components/schemas/Session'
        let(:login_input) { { email: user.email, password: 'password123', rememberMe: true } }
        let!(:oauth) { FactoryBot.create(:o_auth, name: 'GitHub', is_enabled: true) }

        # OAuth must start on the base host, never on the custom domain, or the
        # callback cannot read the token_state cookie
        before { Current.tenant.update_column(:custom_domain, 'feedback.example.org') }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig('user', 'id')).to eq(user.id)
          expect(body.dig('tenant', 'oauthProviders')).to contain_exactly(
            a_hash_including('id' => oauth.id, 'name' => 'GitHub')
          )
          start_url = body.dig('tenant', 'oauthProviders', 0, 'startUrl')
          expect(start_url).to match(%r{\Ahttps?://[^/]+/o_auths/#{oauth.id}/start\?reason=login\z})
          expect(start_url).not_to include('feedback.example.org')
        end
      end

      response(202, 'password correct, two-factor code needed (POST /api/app/v1/session/two_factor)') do
        schema '$ref' => '#/components/schemas/TwoFactorRequired'
        let(:login_input) { { email: user.email, password: 'password123' } }
        before do
          user.start_two_factor_setup!
          user.enable_two_factor!(ROTP::TOTP.new(user.reload.otp_secret).now)
        end

        run_test!
      end

      response(401, 'invalid email or password') do
        schema '$ref' => '#/components/schemas/Error'
        let(:login_input) { { email: user.email, password: 'wrong' } }

        run_test!
      end

      response(401, 'last attempt before the account is locked') do
        schema '$ref' => '#/components/schemas/Error'
        let(:login_input) { { email: user.email, password: 'wrong' } }

        before do
          (Devise.maximum_attempts - 2).times { user.valid_for_authentication? { false } }
        end

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq(I18n.t('devise.failure.last_attempt'))
        end
      end

      response(401, 'account is locked (too many failed attempts)') do
        schema '$ref' => '#/components/schemas/Error'
        let(:locked) { FactoryBot.create(:user, password: 'password123', password_confirmation: 'password123').tap(&:confirm) }
        let(:login_input) { { email: locked.email, password: 'password123' } }

        before do
          Devise.maximum_attempts.times { locked.valid_for_authentication? { false } }
        end

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq(I18n.t('devise.failure.locked'))
        end
      end

      response(200, 'signed in successfully, failed attempts counter reset') do
        schema '$ref' => '#/components/schemas/Session'
        let(:login_input) { { email: user.email, password: 'password123' } }

        before do
          (Devise.maximum_attempts - 1).times { user.valid_for_authentication? { false } }
        end

        run_test! do
          expect(user.reload.failed_attempts).to eq(0)
        end
      end

      response(403, 'unconfirmed account') do
        schema '$ref' => '#/components/schemas/Error'
        let(:unconfirmed) { FactoryBot.create(:user, password: 'password123', password_confirmation: 'password123') }
        let(:login_input) { { email: unconfirmed.email, password: 'password123' } }

        run_test!
      end

      response(403, 'blocked account') do
        schema '$ref' => '#/components/schemas/Error'
        let(:blocked) { FactoryBot.create(:user, password: 'password123', password_confirmation: 'password123', status: :blocked).tap(&:confirm) }
        let(:login_input) { { email: blocked.email, password: 'password123' } }

        run_test!
      end
    end

    delete('Sign out') do
      tags 'Session'
      produces 'application/json'

      response(200, 'signed out') do
        schema '$ref' => '#/components/schemas/Session'
        before { sign_in user }

        run_test! do |response|
          expect(JSON.parse(response.body)['user']).to be_nil
        end
      end
    end
  end

  path '/api/app/v1/registration' do
    post('Register a new user account') do
      tags 'Session'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :register_input, in: :body, schema: { '$ref' => '#/components/schemas/RegisterInput' }

      response(201, 'registered, confirmation email sent') do
        schema '$ref' => '#/components/schemas/RegistrationResult'
        let(:register_input) do
          {
            fullName: 'Grace Hopper',
            email: 'grace@example.com',
            password: 'password123',
            passwordConfirmation: 'password123'
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['confirmationRequired']).to be(true)
          expect(body.dig('session', 'user')).to be_nil
        end
      end

      response(201, 'confirmation required in production without SMTP too') do
        schema '$ref' => '#/components/schemas/RegistrationResult'
        let(:register_input) do
          {
            fullName: 'Grace Hopper',
            email: 'grace@example.com',
            password: 'password123',
            passwordConfirmation: 'password123'
          }
        end

        before do
          allow(Rails.env).to receive(:production?).and_return(true)
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('EMAIL_DELIVERY_METHOD').and_return(nil)
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['confirmationRequired']).to be(true)
          expect(body.dig('session', 'user')).to be_nil
          Current.tenant = Tenant.first
          expect(User.find_by(email: 'grace@example.com').confirmed?).to be(false)
        end
      end

      response(201, 'registered via invitation, immediately confirmed and signed in') do
        schema '$ref' => '#/components/schemas/RegistrationResult'
        let(:raw_token) { 'invite-secret-token' }
        let!(:invitation) do
          Invitation.create!(
            email: 'invited@example.com',
            token_digest: Digest::SHA256.hexdigest(raw_token)
          )
        end
        let(:register_input) do
          {
            fullName: 'Invited User',
            email: 'invited@example.com',
            password: 'password123',
            passwordConfirmation: 'password123',
            invitationToken: raw_token
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['confirmationRequired']).to be(false)
          expect(body.dig('session', 'user', 'email')).to eq('invited@example.com')
        end
      end

      response(403, 'email registration disabled by policy') do
        schema '$ref' => '#/components/schemas/Error'
        let(:register_input) do
          {
            fullName: 'Grace Hopper',
            email: 'grace@example.com',
            password: 'password123',
            passwordConfirmation: 'password123'
          }
        end
        before { Current.tenant.tenant_setting.update!(email_registration_policy: 'none_allowed') }

        run_test!
      end

      response(422, 'validation error (password mismatch)') do
        schema '$ref' => '#/components/schemas/Error'
        let(:register_input) do
          {
            fullName: 'Grace Hopper',
            email: 'grace@example.com',
            password: 'password123',
            passwordConfirmation: 'different'
          }
        end

        run_test!
      end
    end
  end
end
