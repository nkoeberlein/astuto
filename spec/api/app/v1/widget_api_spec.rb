require 'swagger_helper'

RSpec.describe 'api/app/v1 widget', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:admin) { FactoryBot.create(:admin).tap(&:confirm) }
  let!(:config) { WidgetConfig.create!(enabled: true) }

  path '/api/app/v1/widget/session' do
    post('Trade a visitor token from your app for a widget access token') do
      tags 'Widget'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :input, in: :body, schema: { '$ref' => '#/components/schemas/WidgetSessionInput' }

      response(200, 'access token') do
        schema '$ref' => '#/components/schemas/WidgetSession'
        let(:input) { { token: WidgetToken.encode({ email: 'ann@example.com', exp: 1.hour.from_now.to_i }, config.secret) } }

        run_test! { |response| expect(JSON.parse(response.body)['accessToken']).to be_present }
      end

      response(401, 'invalid or expired visitor token') do
        schema '$ref' => '#/components/schemas/Error'
        let(:input) { { token: WidgetToken.encode({ email: 'ann@example.com', exp: 1.hour.from_now.to_i }, 'wrong') } }

        run_test!
      end
    end
  end

  path '/api/app/v1/site_settings/widget' do
    get('Widget settings with the secret (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'settings') do
        schema '$ref' => '#/components/schemas/WidgetSettings'
        before { sign_in admin }

        run_test! { |response| expect(JSON.parse(response.body)['secret']).to start_with('wsk_') }
      end
    end

    patch('Change widget settings (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :changes, in: :body, schema: { '$ref' => '#/components/schemas/UpdateWidgetSettings' }

      response(200, 'saved') do
        schema '$ref' => '#/components/schemas/WidgetSettings'
        let(:changes) { { allowedOrigins: "https://app.example.com\n", autoCreateUsers: false } }
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body)).to include('allowedOrigins' => 'https://app.example.com', 'autoCreateUsers' => false)
          expect(AuditEvent.last.field_changes.keys).to include('widget_config.allowed_origins')
        end
      end

      response(422, 'invalid origin') do
        schema '$ref' => '#/components/schemas/Error'
        let(:changes) { { allowedOrigins: 'javascript:alert(1)' } }
        before { sign_in admin }

        run_test!
      end
    end
  end

  path '/api/app/v1/site_settings/widget/rotate_secret' do
    post('New widget secret; tokens signed with the old one stop working (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'new secret') do
        schema '$ref' => '#/components/schemas/WidgetSettings'
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body)['secret']).not_to eq(config.secret)
          expect(AuditEvent.last.field_changes).to eq({})
        end
      end
    end
  end
end
