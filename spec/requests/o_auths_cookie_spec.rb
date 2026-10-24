# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OAuth token_state cookie (#472, #478)', type: :request do
  let(:tenant) { Tenant.first || FactoryBot.create(:tenant) }
  let(:o_auth) do
    Current.tenant = tenant
    FactoryBot.create(
      :o_auth,
      tenant: tenant,
      is_enabled: true,
      authorize_url: 'https://idp.example.com/oauth/authorize'
    )
  end

  before do
    Current.tenant = tenant
  end

  it 'omits domain attribute in single-tenant mode and sets HttpOnly and SameSite=Lax (#472)' do
    allow(Rails.application).to receive(:multi_tenancy?).and_return(false)

    get o_auth_start_path(o_auth)

    expect(response).to have_http_status(:found)
    set_cookie_header = Array(response.headers['Set-Cookie']).join("\n")
    expect(set_cookie_header).to include('token_state=')
    expect(set_cookie_header).to match(/httponly/i)
    expect(set_cookie_header).to match(/samesite=lax/i)
    expect(set_cookie_header).not_to match(/domain=/i)
  end

  it 'generates an https callback_url when ASSUME_SSL=true behind a reverse proxy (#478)' do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ASSUME_SSL', 'false').and_return('true')

    expect(o_auth.callback_url).to start_with('https://')
  end
end
