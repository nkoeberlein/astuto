require 'swagger_helper'

RSpec.describe 'api/app/v1/site_settings/general', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:admin) { FactoryBot.create(:admin).tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:setting) { Current.tenant.tenant_setting }

  path '/api/app/v1/site_settings/general' do
    get('General site settings (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'current values') do
        schema '$ref' => '#/components/schemas/GeneralSettings'
        before { sign_in admin }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('siteName' => Current.tenant.site_name, 'roadmapEnabled' => true, 'multiTenancy' => false)
          expect(body['availableLocales']).to include('en', 'de')
        end
      end

      response(403, 'moderators are not admins') do
        schema '$ref' => '#/components/schemas/Error'
        before { sign_in moderator }

        run_test!
      end

      response(401, 'not signed in') do
        schema '$ref' => '#/components/schemas/Error'

        run_test!
      end
    end

    patch('Update general site settings (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :changes, in: :body, schema: { '$ref' => '#/components/schemas/UpdateGeneralSettings' }

      response(200, 'saves tenant and settings fields, leaves the rest alone') do
        schema '$ref' => '#/components/schemas/GeneralSettings'
        let(:changes) do
          {
            siteName: 'Acme Feedback', locale: 'de', siteFavicon: '',
            isPrivate: true, feedbackApprovalPolicy: 'always_require_approval', mailLogoSize: 48,
            customLinks: [{ label: 'Docs', url: 'https://example.com/docs' }]
          }
        end
        before { sign_in admin }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('siteName' => 'Acme Feedback', 'locale' => 'de', 'siteFavicon' => nil, 'isPrivate' => true)
          expect(body['customLinks']).to eq([{ 'label' => 'Docs', 'url' => 'https://example.com/docs' }])
          expect(setting.reload).to have_attributes(feedback_approval_policy: 'always_require_approval', mail_logo_size: 48, roadmap_enabled: true)
        end
      end

      response(422, 'unknown enum value') do
        schema '$ref' => '#/components/schemas/Error'
        let(:changes) { { brandDisplay: 'giant_logo', siteName: 'Not saved' } }
        before { sign_in admin }

        run_test! { expect(Current.tenant.reload.site_name).not_to eq('Not saved') }
      end

      response(422, 'validation error, nothing saved') do
        schema '$ref' => '#/components/schemas/Error'
        let(:changes) { { siteName: '', isPrivate: true } }
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to be_present
          expect(setting.reload.is_private).to be(false)
        end
      end

      response(422, 'unsafe custom link') do
        schema '$ref' => '#/components/schemas/Error'
        let(:changes) { { customLinks: [{ label: 'x', url: 'javascript:alert(1)' }] } }
        before { sign_in admin }

        run_test!
      end

      response(403, 'moderators cannot change site settings') do
        schema '$ref' => '#/components/schemas/Error'
        let(:changes) { { siteName: 'Hijacked' } }
        before { sign_in moderator }

        run_test! { expect(Current.tenant.reload.site_name).not_to eq('Hijacked') }
      end
    end
  end
end
