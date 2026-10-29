require 'swagger_helper'

# OpenAPI documentation of the LDAP endpoints; behaviour in spec/requests/ldap_login_spec.rb
RSpec.describe 'api/app/v1 LDAP', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:admin) { FactoryBot.create(:admin).tap(&:confirm) }
  let!(:config) { LdapConfig.create!(enabled: true, host: 'ldap.example.com', base_dn: 'dc=example,dc=com') }
  let(:ada) { LdapConfig::Result.new(email: 'ada@example.com', name: 'Ada Lovelace', dn: 'uid=ada,dc=example,dc=com') }

  path '/api/app/v1/session/ldap' do
    post('Log in with the company directory (LDAP / Active Directory)') do
      tags 'Session'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :login_input, in: :body, schema: { '$ref' => '#/components/schemas/LdapLoginInput' }

      response(200, 'signed in') do
        schema '$ref' => '#/components/schemas/Session'
        let(:login_input) { { login: 'ada', password: 'adasecret' } }
        before { allow_any_instance_of(LdapConfig).to receive(:authenticate).and_return(ada) }

        run_test!
      end

      response(401, 'wrong login or password') do
        schema '$ref' => '#/components/schemas/Error'
        let(:login_input) { { login: 'ada', password: 'wrong' } }
        before { allow_any_instance_of(LdapConfig).to receive(:authenticate).and_return(nil) }

        run_test!
      end
    end
  end

  path '/api/app/v1/site_settings/ldap' do
    get('LDAP settings (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'settings') do
        schema '$ref' => '#/components/schemas/LdapSettings'
        before { sign_in admin }

        run_test!
      end
    end

    patch('Change LDAP settings (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :changes, in: :body, schema: { '$ref' => '#/components/schemas/UpdateLdapSettings' }

      response(200, 'saved') do
        schema '$ref' => '#/components/schemas/LdapSettings'
        let(:changes) { { label: 'Acme account', port: 636, encryption: 'simple_tls' } }
        before { sign_in admin }

        run_test!
      end

      response(422, 'invalid filter') do
        schema '$ref' => '#/components/schemas/Error'
        let(:changes) { { userFilter: '(uid=nobody)' } }
        before { sign_in admin }

        run_test!
      end
    end
  end

  path '/api/app/v1/site_settings/ldap/test' do
    post('Look up a login with the service account (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :input, in: :body, schema: { '$ref' => '#/components/schemas/LdapTestInput' }

      response(200, 'found') do
        schema '$ref' => '#/components/schemas/LdapTestResult'
        let(:input) { { login: 'ada' } }
        before do
          sign_in admin
          allow_any_instance_of(LdapConfig).to receive(:test_lookup).and_return([ada, nil])
        end

        run_test!
      end

      response(422, 'not found or no connection') do
        schema '$ref' => '#/components/schemas/Error'
        let(:input) { { login: 'nobody' } }
        before do
          sign_in admin
          allow_any_instance_of(LdapConfig).to receive(:test_lookup).and_return([nil, 'No unique entry'])
        end

        run_test!
      end
    end
  end
end
