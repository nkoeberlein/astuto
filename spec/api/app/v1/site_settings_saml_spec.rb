require 'swagger_helper'

RSpec.describe 'api/app/v1/site_settings/saml', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:admin) { FactoryBot.create(:admin).tap(&:confirm) }
  let(:metadata) do
    <<~XML
      <EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" entityID="https://idp.example.com/saml">
        <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
          <KeyDescriptor use="signing"><KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#"><X509Data><X509Certificate>#{Base64.strict_encode64(SamlHelper.certificate.to_der)}</X509Certificate></X509Data></KeyInfo></KeyDescriptor>
          <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://idp.example.com/sso"/>
        </IDPSSODescriptor>
      </EntityDescriptor>
    XML
  end

  path '/api/app/v1/site_settings/saml' do
    get('SAML single sign-on settings (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'settings') do
        schema '$ref' => '#/components/schemas/SamlSettings'
        before { sign_in admin }

        run_test! { |response| expect(JSON.parse(response.body)['acsUrl']).to end_with('/saml/acs') }
      end
    end

    patch('Change SAML settings (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :changes, in: :body, schema: { '$ref' => '#/components/schemas/UpdateSamlSettings' }

      response(200, 'saved') do
        schema '$ref' => '#/components/schemas/SamlSettings'
        let(:changes) do
          { enabled: true, label: 'Company login', idpEntityId: 'https://idp.example.com/saml', idpSsoUrl: 'https://idp.example.com/sso', idpCert: SamlHelper.certificate.to_pem }
        end
        before { sign_in admin }

        run_test! do
          expect(SamlConfig.sole).to be_usable
          expect(AuditEvent.sole.action).to eq('saml.update')
        end
      end

      response(422, 'switched on without a valid certificate') do
        schema '$ref' => '#/components/schemas/Error'
        let(:changes) { { enabled: true, idpEntityId: 'x', idpSsoUrl: 'https://idp.example.com/sso', idpCert: 'not a certificate' } }
        before { sign_in admin }

        run_test!
      end
    end
  end

  path '/api/app/v1/site_settings/saml/parse_metadata' do
    post('Read entity ID, SSO URL and certificate from IdP metadata (not saved)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :input, in: :body, schema: { '$ref' => '#/components/schemas/SamlMetadataInput' }

      response(200, 'fields') do
        schema '$ref' => '#/components/schemas/SamlIdpFields'
        let(:input) { { xml: metadata } }
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body)).to include('idpEntityId' => 'https://idp.example.com/saml', 'idpSsoUrl' => 'https://idp.example.com/sso')
        end
      end

      response(422, 'not metadata') do
        schema '$ref' => '#/components/schemas/Error'
        let(:input) { { xml: '<nope/>' } }
        before { sign_in admin }

        run_test!
      end
    end
  end
end
