require 'swagger_helper'

RSpec.describe 'api/app/v1/session', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  path '/api/app/v1/session' do
    get('Current session') do
      tags 'Session'
      description 'Current user (or null), CSRF token, tenant branding and public settings.'
      produces 'application/json'

      response(200, 'anonymous visitor') do
        schema '$ref' => '#/components/schemas/Session'

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['user']).to be_nil
          expect(body['csrfToken']).to be_present
          expect(body['tenant']['siteName']).to eq(Tenant.first.site_name)
          expect(body['tenant']['settings']).to include(
            'roadmapEnabled' => true,
            'defaultPostSorting' => 'trending',
            'customLinks' => [],
            'loginOnlyWithOauth' => false
          )
        end
      end

      response(200, 'signed-in user') do
        schema '$ref' => '#/components/schemas/Session'

        let(:user) { FactoryBot.create(:user).tap(&:confirm) }
        before { sign_in user }

        run_test! do |response|
          expect(JSON.parse(response.body)['user']).to include('id' => user.id, 'email' => user.email, 'role' => 'user')
        end
      end
    end
  end

  path '/api/app/v1/translations/{locale}' do
    parameter name: :locale, in: :path, type: :string

    get('Frontend translations') do
      tags 'Session'
      description 'Translations of the frontend for a locale, English as fallback.'
      produces 'application/json'

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/Translations'
        let(:locale) { 'de' }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig('board', 'sort_by_box', 'newest')).to be_present
          expect(body).not_to have_key('mailers') # backend-only keys stay out
        end
      end

      response(404, 'unknown locale') do
        schema '$ref' => '#/components/schemas/Error'
        let(:locale) { 'xx' }

        run_test!
      end
    end
  end
end
