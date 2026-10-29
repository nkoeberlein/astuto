require 'rails_helper'

RSpec.describe 'Instance admin', type: :request do
  let(:base_host) { 'feedback.example.com' }
  let(:password) { 'correct horse battery staple' }
  let(:auth) { { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('admin', password) } }
  let!(:acme) { Tenant.create!(site_name: 'Acme', subdomain: 'acme', status: 'active') }

  before do
    allow(Rails.application).to receive(:multi_tenancy?).and_return(true)
    allow(Rails.application).to receive(:base_url).and_return("https://#{base_host}")
    stub_const('ENV', ENV.to_h.merge('INSTANCE_ADMIN_PASSWORD' => password))
    host! base_host
  end

  describe 'access' do
    it 'asks for the password and refuses a wrong one' do
      get '/instance/tenants'
      expect(response).to have_http_status(:unauthorized)

      get '/instance/tenants', headers: { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'wrong') }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'does not exist on feedback spaces, without a password or without multi-tenancy' do
      host! "acme.#{base_host}"
      get '/instance/tenants', headers: auth
      expect(response).to have_http_status(:not_found)

      host! base_host
      stub_const('ENV', ENV.to_h.merge('INSTANCE_ADMIN_PASSWORD' => ''))
      get '/instance/tenants', headers: auth
      expect(response).to have_http_status(:not_found)

      stub_const('ENV', ENV.to_h.merge('INSTANCE_ADMIN_PASSWORD' => password))
      allow(Rails.application).to receive(:multi_tenancy?).and_return(false)
      get '/instance/tenants', headers: auth
      expect(response).to have_http_status(:not_found)
    end

    it 'lists feedback spaces with their addresses' do
      get '/instance/tenants', headers: auth
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Acme', "https://acme.#{base_host}")
    end
  end

  it 'creates a feedback space and shows the owner password once' do
    post '/instance/tenants', headers: auth, params: { tenant: { site_name: 'Initech', subdomain: 'Initech', owner_email: 'owner@initech.example', locale: 'de' } }

    expect(response).to have_http_status(:created)
    tenant = Tenant.find_by!(subdomain: 'initech')
    expect(tenant.locale).to eq('de')
    password = response.body[%r{<p class="secret">([^<]+)</p>}, 1]
    Current.set(tenant: tenant) { expect(User.sole.valid_password?(password)).to be(true) }
  end

  it 'shows the error when the subdomain is taken' do
    post '/instance/tenants', headers: auth, params: { tenant: { site_name: 'Again', subdomain: 'acme', owner_email: 'x@acme.example' } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Subdomain')
    expect(Tenant.where(subdomain: 'acme').count).to eq(1)
  end

  it 'edits name, custom domain and language' do
    patch "/instance/tenants/#{acme.id}", headers: auth, params: { tenant: { site_name: 'Acme Ideas', custom_domain: ' Ideas.Acme.Example ', locale: 'fr' } }

    expect(response).to redirect_to('/instance/tenants')
    expect(acme.reload).to have_attributes(site_name: 'Acme Ideas', custom_domain: 'ideas.acme.example', locale: 'fr')

    patch "/instance/tenants/#{acme.id}", headers: auth, params: { tenant: { custom_domain: '' } }
    expect(acme.reload.custom_domain).to be_nil
  end

  it 'blocks and unblocks' do
    put "/instance/tenants/#{acme.id}/block", headers: auth
    expect(acme.reload).to be_blocked
    put "/instance/tenants/#{acme.id}/unblock", headers: auth
    expect(acme.reload).to be_active
  end

  it 'deletes a feedback space only when its subdomain is typed' do
    tenant = CreateTenantWorkflow.new(subdomain: 'initech', owner_email: 'owner@initech.example').run

    delete "/instance/tenants/#{tenant.id}", headers: auth, params: { confirm_subdomain: 'acme' }
    expect(Tenant.exists?(tenant.id)).to be(true)

    delete "/instance/tenants/#{tenant.id}", headers: auth, params: { confirm_subdomain: 'initech' }
    expect(response).to redirect_to('/instance/tenants')
    expect(Tenant.exists?(tenant.id)).to be(false)
    expect(User.unscoped.where(tenant_id: tenant.id)).to be_empty
  end

  it 'needs the CSRF token for changes' do
    ActionController::Base.allow_forgery_protection = true
    expect { put "/instance/tenants/#{acme.id}/block", headers: auth }.to raise_error(ActionController::InvalidAuthenticityToken)
    expect(acme.reload).to be_active
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end
