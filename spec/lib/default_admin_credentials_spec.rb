require 'rails_helper'

RSpec.describe DefaultAdminCredentials do
  it 'uses ADMIN_EMAIL and ADMIN_PASSWORD when set' do
    credentials = described_class.new(env: { 'ADMIN_EMAIL' => ' owner@corp.example ', 'ADMIN_PASSWORD' => 'S3cret-pass' }, rails_env: 'production')

    expect(credentials.email).to eq('owner@corp.example')
    expect(credentials.password).to eq('S3cret-pass')
    expect(credentials.password_from_env?).to be(true)
  end

  it 'keeps the documented password in development' do
    credentials = described_class.new(env: {}, rails_env: 'development')

    expect(credentials.email).to eq('admin@example.com')
    expect(credentials.password).to eq('password')
  end

  it 'generates a random password everywhere else' do
    first = described_class.new(env: {}, rails_env: 'production')
    second = described_class.new(env: {}, rails_env: 'production')

    expect(first.password).not_to eq('password')
    expect(first.password.length).to eq(20)
    expect(first.password).not_to eq(second.password)
    expect(first.password_from_env?).to be(false)
  end
end
