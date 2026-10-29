require 'swagger_helper'

RSpec.describe 'api/app/v1/profile', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:user) { FactoryBot.create(:user, full_name: 'Ada', email: 'ada@example.com', password: 'password1').tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }

  path '/api/app/v1/profile' do
    get('Profile settings of the signed-in user') do
      tags 'Profile'
      produces 'application/json'

      response(200, 'current settings') do
        schema '$ref' => '#/components/schemas/Profile'
        before { sign_in user }

        run_test! do |response|
          expect(JSON.parse(response.body)).to include(
            'fullName' => 'Ada', 'email' => 'ada@example.com', 'canHaveApiKey' => false, 'apiKey' => nil,
            'recapNotificationFrequency' => 'never'
          )
        end
      end

      response(401, 'not signed in') do
        schema '$ref' => '#/components/schemas/Error'

        run_test!
      end
    end

    patch('Update profile settings') do
      tags 'Profile'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :changes, in: :body, schema: { '$ref' => '#/components/schemas/UpdateProfile' }

      response(200, 'name and notifications without the current password') do
        schema '$ref' => '#/components/schemas/Profile'
        let(:changes) { { fullName: 'Ada Lovelace', notificationsEnabled: false, recapNotificationFrequency: 'weekly' } }
        before { sign_in user }

        run_test! do
          expect(user.reload).to have_attributes(full_name: 'Ada Lovelace', notifications_enabled: false, recap_notification_frequency: 'weekly')
        end
      end

      response(200, 'new password with the current one, still signed in') do
        schema '$ref' => '#/components/schemas/Profile'
        let(:changes) { { password: 'new-password', passwordConfirmation: 'new-password', currentPassword: 'password1' } }
        before { sign_in user }

        run_test! do
          expect(user.reload.valid_password?('new-password')).to be(true)
          get '/api/app/v1/profile'
          expect(response).to have_http_status(:ok)
        end
      end

      response(422, 'email change with a wrong current password') do
        schema '$ref' => '#/components/schemas/Error'
        let(:changes) { { email: 'evil@example.com', currentPassword: 'wrong' } }
        before { sign_in user }

        run_test! do
          expect(user.reload.email).to eq('ada@example.com')
          expect(user.unconfirmed_email).to be_nil
        end
      end

      response(422, 'email domain not allowed') do
        schema '$ref' => '#/components/schemas/Error'
        let(:changes) { { email: 'ada@other.example', currentPassword: 'password1' } }
        before do
          Current.tenant.tenant_setting.update!(email_registration_policy: 'custom_domains_allowed', allowed_email_domains: 'example.com')
          sign_in user
        end

        run_test!
      end

      response(403, 'OAuth accounts set a password first') do
        schema '$ref' => '#/components/schemas/Error'
        let(:changes) { { password: 'new-password', passwordConfirmation: 'new-password' } }
        before do
          user.update_columns(has_set_password: false)
          sign_in user
        end

        run_test!
      end
    end

    delete('Delete the own account (soft delete)') do
      tags 'Profile'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :confirmation, in: :body, schema: { '$ref' => '#/components/schemas/DeleteProfile' }

      response(200, 'deleted and signed out') do
        schema '$ref' => '#/components/schemas/Session'
        let(:confirmation) { { currentPassword: 'password1' } }
        before { sign_in user }

        run_test! do |response|
          expect(JSON.parse(response.body)['user']).to be_nil
          expect(user.reload).to have_attributes(status: 'deleted', full_name: 'Deleted User')
          expect(user.email).to end_with('@deleted.com')
        end
      end

      response(422, 'wrong password') do
        schema '$ref' => '#/components/schemas/Error'
        let(:confirmation) { { currentPassword: 'nope' } }
        before { sign_in user }

        run_test! { expect(user.reload.status).to eq('active') }
      end
    end
  end

  path '/api/app/v1/profile/api_key' do
    post('Generate a new API key (moderators)') do
      tags 'Profile'
      produces 'application/json'

      response(201, 'new key, the old one stops working') do
        schema '$ref' => '#/components/schemas/NewApiKey'
        let!(:old_key) { FactoryBot.create(:api_key, user: moderator) }
        before { sign_in moderator }

        run_test! do |response|
          token = JSON.parse(response.body)['apiKey']
          expect(ApiKey.find_by_token(token).user).to eq(moderator)
          expect(ApiKey.exists?(old_key.id)).to be(false)
        end
      end

      response(403, 'users cannot have API keys') do
        schema '$ref' => '#/components/schemas/Error'
        before { sign_in user }

        run_test! { expect(ApiKey.where(user_id: user.id)).to be_empty }
      end
    end
  end

  path '/api/app/v1/profile/export' do
    get('Everything stored about the signed-in person, as a JSON download (GDPR)') do
      tags 'Profile'
      produces 'application/json'

      response(200, 'data') do
        schema '$ref' => '#/components/schemas/UserDataExport'
        before { sign_in user }

        run_test! { |response| expect(JSON.parse(response.body)['profile']).to include('email' => user.email) }
      end
    end
  end
end
