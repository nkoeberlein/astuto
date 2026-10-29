require 'rails_helper'

RSpec.describe OAuthExchangeAuthCodeForProfileWorkflow do
  let(:o_auth) { FactoryBot.create(:o_auth, profile_url: 'https://api.example.com/me') }
  let(:token_response) { { 'access_token' => 'tok' } }

  before do
    allow(HTTParty).to receive(:post).and_return(token_response)
    allow(HTTParty).to receive(:get).and_return(instance_double(HTTParty::Response, parsed_response: { 'email' => 'a@b.c' }))
  end

  def run
    described_class.new(authorization_code: 'code', o_auth: o_auth).run
  end

  it 'asks for the profile with the bearer token' do
    expect(run).to eq('email' => 'a@b.c')
    expect(HTTParty).to have_received(:get).with('https://api.example.com/me', hash_including(headers: { 'Authorization' => 'Bearer tok' }))
  end

  it 'adds the configured headers; an own Authorization header replaces the bearer token (#485)' do
    o_auth.update!(profile_headers: [
      { key: 'User-Agent', value: 'Astuto' },
      { key: 'authorization', value: 'token tok' },
      { key: '', value: 'dropped' }
    ])

    run

    expect(HTTParty).to have_received(:get).with(
      'https://api.example.com/me',
      hash_including(headers: { 'User-Agent' => 'Astuto', 'authorization' => 'token tok' })
    )
  end
end
