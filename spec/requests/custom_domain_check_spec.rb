require 'rails_helper'

# Caddy on-demand TLS: certificates only for hosts that belong to the instance
RSpec.describe 'GET /custom_domain_check', type: :request do
  let!(:acme) { Tenant.create!(site_name: 'Acme', subdomain: 'acme', status: 'active', custom_domain: 'ideas.acme.example') }
  let!(:blocked) { Tenant.create!(site_name: 'Blocked', subdomain: 'blocked', status: 'blocked', custom_domain: 'ideas.blocked.example') }

  def check(domain)
    get '/custom_domain_check', params: { domain: domain }
    response.status
  end

  context 'with multi-tenancy' do
    before do
      allow(Rails.application).to receive(:multi_tenancy?).and_return(true)
      allow(Rails.application).to receive(:base_url).and_return('https://feedback.example.com')
    end

    it 'allows the base host, subdomains and custom domains of feedback spaces' do
      expect(check('feedback.example.com')).to eq(200)
      expect(check('acme.feedback.example.com')).to eq(200)
      expect(check('IDEAS.acme.example')).to eq(200)
    end

    it 'refuses unknown hosts, reserved subdomains and blocked feedback spaces' do
      expect(check('evil.example')).to eq(404)
      expect(check('nobody.feedback.example.com')).to eq(404)
      expect(check('login.feedback.example.com')).to eq(404)
      expect(check('blocked.feedback.example.com')).to eq(404)
      expect(check('ideas.blocked.example')).to eq(404)
      expect(check('')).to eq(404)
    end
  end

  it 'only allows the base host without multi-tenancy' do
    allow(Rails.application).to receive(:base_url).and_return('https://feedback.example.com')
    expect(check('feedback.example.com')).to eq(200)
    expect(check('ideas.acme.example')).to eq(404)
  end
end
