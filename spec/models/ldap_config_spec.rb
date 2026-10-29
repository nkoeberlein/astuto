require 'rails_helper'

RSpec.describe LdapConfig, type: :model do
  let(:config) do
    described_class.new(
      tenant: Current.tenant, enabled: true, host: ENV.fetch('LDAP_TEST_HOST', 'ldap.example.com'), port: ENV.fetch('LDAP_TEST_PORT', 389).to_i,
      encryption: 'plain', base_dn: 'ou=people,dc=example,dc=com',
      bind_dn: 'cn=service,ou=people,dc=example,dc=com', bind_password: 'servicesecret'
    )
  end

  it 'keeps the service password encrypted' do
    expect(config.bind_password).to eq('servicesecret')
    expect(config.bind_password_ciphertext).not_to include('servicesecret')
  end

  it 'needs %{login} in a valid filter' do
    config.user_filter = '(uid=ada)'
    expect(config).not_to be_valid
    config.user_filter = '(uid=%{login}'
    expect(config).not_to be_valid
  end

  it 'refuses empty passwords without asking the directory (anonymous bind)' do
    expect(Net::LDAP).not_to receive(:new)
    expect(config.authenticate('ada', '')).to be_nil
    expect(config.authenticate(' ', 'secret')).to be_nil
  end

  it 'escapes the login in the filter' do
    service = instance_double(Net::LDAP)
    allow(Net::LDAP).to receive(:new).and_return(service)
    expect(service).to receive(:search) do |options|
      expect(options[:filter].to_s).to include('(uid=\\2A\\29\\28uid=\\2A)')
      []
    end
    expect(config.authenticate('*)(uid=*', 'secret')).to be_nil
  end

  # Against a real directory: see spec/fixtures/ldap/README.md
  context 'with a test directory', if: ENV['LDAP_TEST_HOST'].present? do
    it 'signs in with the right password only' do
      expect(config.authenticate('ada', 'adasecret')).to have_attributes(email: 'ada@example.com', name: 'Ada Lovelace')
      expect(config.authenticate('ada@example.com', 'adasecret')&.dn).to eq('uid=ada,ou=people,dc=example,dc=com')
      expect(config.authenticate('ada', 'wrong')).to be_nil
      expect(config.authenticate('*', 'adasecret')).to be_nil
    end

    it 'falls back to cn for the name and reports lookups for the settings page' do
      result, error = config.test_lookup('bob')
      expect(error).to be_nil
      expect(result).to have_attributes(email: 'bob@example.com', name: 'Bob Builder')

      config.bind_password = 'wrong'
      expect(config.test_lookup('bob').last).to be_present
    end
  end
end
