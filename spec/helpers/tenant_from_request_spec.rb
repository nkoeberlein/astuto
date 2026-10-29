require 'rails_helper'

# Multi-tenancy: the tenant comes from the part of the host in front of the BASE_URL host,
# whatever the number of labels (tld_length used to decide, so feedback.example.com broke)
RSpec.describe ApplicationHelper, '#get_tenant_from_request' do
  let(:acme) { Tenant.create!(site_name: 'Acme', subdomain: 'acme', status: 'active') }
  let(:custom) { Tenant.create!(site_name: 'Custom', subdomain: 'custom', status: 'active', custom_domain: 'ideas.custom.example') }

  def request_for(host, forwarded: nil)
    headers = forwarded ? { 'HTTP_X_FORWARDED_HOST' => forwarded } : {}
    ActionDispatch::Request.new(Rack::MockRequest.env_for("http://#{host}/", headers))
  end

  def tenant_for(host, base_url:, **options)
    allow(Rails.application).to receive(:multi_tenancy?).and_return(true)
    allow(Rails.application).to receive(:base_url).and_return(base_url)
    helper.get_tenant_from_request(request_for(host, **options))
  end

  it 'finds the tenant below a base host with three or more labels' do
    acme
    expect(tenant_for('acme.feedback.example.com', base_url: 'https://feedback.example.com')).to eq(acme)
    expect(tenant_for('acme.feedback.example.co.uk', base_url: 'https://feedback.example.co.uk')).to eq(acme)
    expect(tenant_for('acme.localhost', base_url: 'http://localhost:3000')).to eq(acme)
  end

  it 'reads X-Forwarded-Host, also with a port' do
    acme
    expect(tenant_for('internal', base_url: 'https://feedback.example.com', forwarded: 'acme.feedback.example.com:443')).to eq(acme)
  end

  it 'has no tenant on the base host itself or on reserved subdomains' do
    acme
    expect(tenant_for('feedback.example.com', base_url: 'https://feedback.example.com')).to be_nil
    expect(tenant_for('login.feedback.example.com', base_url: 'https://feedback.example.com')).to be_nil
  end

  it 'finds tenants by their custom domain, also with a long top-level domain' do
    custom
    custom.update!(custom_domain: 'ideas.custom.solutions')
    expect(tenant_for('ideas.custom.solutions', base_url: 'https://feedback.example.com')).to eq(custom)
    custom.update!(custom_domain: 'ideas.custom.example')
    expect(tenant_for('ideas.custom.example', base_url: 'https://feedback.example.com')).to eq(custom)
  end
end
