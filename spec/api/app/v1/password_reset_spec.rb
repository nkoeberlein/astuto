require 'swagger_helper'

RSpec.describe 'api/app/v1 password reset', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:user) { FactoryBot.create(:user, password: 'password123', password_confirmation: 'password123').tap(&:confirm) }

  path '/api/app/v1/password' do
    post('Send password reset instructions') do
      tags 'Session'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :forgot_input, in: :body, schema: { '$ref' => '#/components/schemas/ForgotPasswordInput' }

      response(200, 'instructions sent (paranoid mode)') do
        schema '$ref' => '#/components/schemas/MessageResponse'
        let(:forgot_input) { { email: user.email } }

        run_test! do |response|
          expect(JSON.parse(response.body)['message']).to be_present
        end
      end

      response(422, 'invalid email format') do
        schema '$ref' => '#/components/schemas/Error'
        let(:forgot_input) { { email: 'not-an-email' } }

        run_test!
      end
    end

    patch('Reset password with token') do
      tags 'Session'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :reset_input, in: :body, schema: { '$ref' => '#/components/schemas/ResetPasswordInput' }

      response(200, 'password updated and user signed in') do
        schema '$ref' => '#/components/schemas/PasswordResetResponse'
        let(:raw_token) { user.send(:set_reset_password_token) }
        let(:reset_input) do
          {
            resetPasswordToken: raw_token,
            password: 'newpassword123',
            passwordConfirmation: 'newpassword123'
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig('session', 'user', 'id')).to eq(user.id)
          Current.tenant = Tenant.first
          expect(user.reload.valid_password?('newpassword123')).to be(true)
          expect(user.has_set_password).to be(true)
        end
      end

      response(200, 'password reset unlocks a locked account') do
        schema '$ref' => '#/components/schemas/PasswordResetResponse'
        let(:raw_token) { user.send(:set_reset_password_token) }
        let(:reset_input) do
          {
            resetPasswordToken: raw_token,
            password: 'newpassword123',
            passwordConfirmation: 'newpassword123'
          }
        end

        before { user.lock_access!(send_instructions: false) }

        run_test! do |response|
          expect(JSON.parse(response.body).dig('session', 'user', 'id')).to eq(user.id)
          Current.tenant = Tenant.first
          expect(user.reload.access_locked?).to be(false)
        end
      end

      response(422, 'invalid or expired token') do
        schema '$ref' => '#/components/schemas/Error'
        let(:reset_input) do
          {
            resetPasswordToken: 'invalid-token',
            password: 'newpassword123',
            passwordConfirmation: 'newpassword123'
          }
        end

        run_test!
      end
    end
  end
end
