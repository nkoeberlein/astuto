require 'swagger_helper'

# OpenAPI documentation of the 2FA endpoints; behaviour in spec/requests/two_factor_spec.rb
RSpec.describe 'api/app/v1 two-factor authentication', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:user) { FactoryBot.create(:moderator, password: 'password123', password_confirmation: 'password123').tap(&:confirm) }

  def enable!
    user.start_two_factor_setup!
    user.enable_two_factor!(ROTP::TOTP.new(user.reload.otp_secret).now)
  end

  path '/api/app/v1/session/two_factor' do
    post('Second login step: code from the authenticator app or a backup code') do
      tags 'Session'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :code_input, in: :body, schema: { '$ref' => '#/components/schemas/TwoFactorCodeInput' }

      response(200, 'signed in') do
        schema '$ref' => '#/components/schemas/Session'
        let!(:backup_codes) { enable! }
        let(:code_input) { { code: backup_codes.first } }
        before { post '/api/app/v1/session', params: { email: user.email, password: 'password123' }, as: :json }

        run_test!
      end

      response(401, 'wrong code or no login in progress') do
        schema '$ref' => '#/components/schemas/Error'
        let(:code_input) { { code: '000000' } }

        run_test!
      end
    end
  end

  path '/api/app/v1/profile/two_factor' do
    post('Start setting up 2FA: new secret and QR code (not active until confirmed)') do
      tags 'Profile'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :password_input, in: :body, schema: { '$ref' => '#/components/schemas/DeleteProfile' }

      response(201, 'secret') do
        schema '$ref' => '#/components/schemas/TwoFactorSetup'
        let(:password_input) { { currentPassword: 'password123' } }
        before { sign_in user }

        run_test!
      end
    end

    delete('Turn 2FA off (password, or a code for accounts without password)') do
      tags 'Profile'
      consumes 'application/json'
      parameter name: :disable_input, in: :body, schema: { '$ref' => '#/components/schemas/TwoFactorDisableInput' }

      response(204, 'off') do
        let(:disable_input) { { currentPassword: 'password123' } }
        before do
          enable!
          sign_in user
        end

        run_test!
      end
    end
  end

  path '/api/app/v1/profile/two_factor/confirm' do
    post('Turn 2FA on with a code from the app; returns the backup codes once') do
      tags 'Profile'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :code_input, in: :body, schema: { '$ref' => '#/components/schemas/TwoFactorCodeInput' }

      response(200, 'on') do
        schema '$ref' => '#/components/schemas/TwoFactorBackupCodes'
        let(:code_input) { { code: ROTP::TOTP.new(user.reload.otp_secret).now } }
        before do
          sign_in user
          user.start_two_factor_setup!
        end

        run_test!
      end

      response(422, 'wrong code') do
        schema '$ref' => '#/components/schemas/Error'
        let(:code_input) { { code: '000000' } }
        before do
          sign_in user
          user.start_two_factor_setup!
        end

        run_test!
      end
    end
  end

  path '/api/app/v1/profile/two_factor/backup_codes' do
    post('New backup codes (the old ones stop working)') do
      tags 'Profile'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :code_input, in: :body, schema: { '$ref' => '#/components/schemas/TwoFactorCodeInput' }

      response(200, 'new codes') do
        schema '$ref' => '#/components/schemas/TwoFactorBackupCodes'
        let!(:backup_codes) { enable! }
        let(:code_input) { { code: backup_codes.first } }
        before { sign_in user }

        run_test! { |response| expect(JSON.parse(response.body)['backupCodes']).not_to include(backup_codes.first) }
      end
    end
  end
end
