require 'swagger_helper'

RSpec.describe 'api/app/v1/site_settings/o_auths', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:admin) { FactoryBot.create(:admin).tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let!(:github) { FactoryBot.create(:o_auth, name: 'GitHub', client_secret: 'top-secret') }
  let!(:default_google) { FactoryBot.create(:default_o_auth, name: 'Google', is_enabled: true) }

  path '/api/app/v1/site_settings/o_auths' do
    get('OAuth providers (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'own and default providers, never the client secret') do
        schema type: :array, items: { '$ref' => '#/components/schemas/OAuthSettings' }
        before { sign_in admin }

        run_test! do |response|
          expect(response.body).not_to include('top-secret')
          body = JSON.parse(response.body)
          own = body.find { |o| o['name'] == 'GitHub' }
          default = body.find { |o| o['name'] == 'Google' }
          expect(own).to include('isDefault' => false, 'clientId' => '123456', 'testUrl' => "/o_auths/#{github.id}/start?reason=test")
          expect(own['callbackUrl']).to end_with("/o_auths/#{github.slug}/callback")
          expect(default).to include('isDefault' => true, 'isEnabled' => false, 'clientId' => nil)
        end
      end

      response(403, 'moderators are not admins') do
        schema '$ref' => '#/components/schemas/Error'
        before { sign_in moderator }

        run_test!
      end
    end

    post('Create an OAuth provider (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :o_auth, in: :body, schema: { '$ref' => '#/components/schemas/OAuthInput' }

      response(201, 'created') do
        schema '$ref' => '#/components/schemas/OAuthSettings'
        let(:o_auth) do
          {
            name: 'Keycloak', isEnabled: true, clientId: 'astuto', clientSecret: 's3cret',
            authorizeUrl: 'https://sso.example/auth', tokenUrl: 'https://sso.example/token',
            profileUrl: 'https://sso.example/userinfo', scope: 'openid email profile',
            jsonUserNamePath: 'name', jsonUserEmailPath: 'email'
          }
        end
        before { sign_in admin }

        run_test! do |response|
          created = OAuth.find(JSON.parse(response.body)['id'])
          expect(created).to have_attributes(name: 'Keycloak', client_secret: 's3cret', is_enabled: true)
        end
      end

      response(422, 'missing required fields') do
        schema '$ref' => '#/components/schemas/Error'
        let(:o_auth) { { name: 'Incomplete' } }
        before { sign_in admin }

        run_test!
      end
    end
  end

  path '/api/app/v1/site_settings/o_auths/{id}' do
    parameter name: :id, in: :path, type: :integer

    patch('Update an OAuth provider (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :o_auth, in: :body, schema: { '$ref' => '#/components/schemas/OAuthInput' }

      response(200, 'blank secret keeps the current one') do
        schema '$ref' => '#/components/schemas/OAuthSettings'
        let(:id) { github.id }
        let(:o_auth) { { isEnabled: true, scope: 'read:user', clientSecret: '', profileHeaders: [{ key: 'User-Agent', value: 'Astuto' }] } }
        before { sign_in admin }

        run_test! do |response|
          expect(github.reload).to have_attributes(is_enabled: true, scope: 'read:user', client_secret: 'top-secret')
          expect(JSON.parse(response.body)['profileHeaders']).to eq([{ 'key' => 'User-Agent', 'value' => 'Astuto' }])
        end
      end

      response(404, 'default providers cannot be edited') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { default_google.id }
        let(:o_auth) { { name: 'Hijacked' } }
        before { sign_in admin }

        run_test! { expect(default_google.reload.name).to eq('Google') }
      end
    end

    delete('Delete an OAuth provider (admins)') do
      tags 'Site settings'

      response(204, 'deleted') do
        let(:id) { github.id }
        before { sign_in admin }

        run_test! { expect(OAuth.exists?(github.id)).to be(false) }
      end
    end
  end

  path '/api/app/v1/site_settings/o_auths/{id}/default' do
    parameter name: :id, in: :path, type: :integer

    put('Switch a default provider on or off for this feedback space (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :state, in: :body, schema: { type: :object, properties: { enabled: { type: :boolean } }, required: ['enabled'] }

      response(200, 'switched on') do
        schema '$ref' => '#/components/schemas/OAuthSettings'
        let(:id) { default_google.id }
        let(:state) { { enabled: true } }
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body)['isEnabled']).to be(true)
          expect(TenantDefaultOAuth.where(o_auth_id: default_google.id).count).to eq(1)
        end
      end

      response(404, 'not a default provider') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { github.id }
        let(:state) { { enabled: true } }
        before { sign_in admin }

        run_test!
      end
    end
  end
end
