require 'rails_helper'

RSpec.describe CreateTenantWorkflow do
  def create(**args)
    described_class.new(subdomain: 'initech', site_name: 'Initech', owner_email: 'owner@initech.example', **args)
  end

  it 'creates an active feedback space with a confirmed owner, settings and welcome boards' do
    previous = Current.tenant
    workflow = create(locale: 'de')
    tenant = workflow.run

    expect(workflow).to be_success
    expect(tenant).to be_active
    expect(tenant.locale).to eq('de')
    expect(workflow.password.length).to eq(20)
    expect(Current.tenant).to eq(previous)

    Current.set(tenant: tenant) do
      expect(TenantSetting.count).to eq(1)
      expect(User.sole).to be_owner
      expect(User.sole.confirmed_at).to be_present
      expect(User.sole.valid_password?(workflow.password)).to be(true)
      expect(Board.count).to be > 0
    end
  end

  it 'refuses reserved and taken subdomains without leaving anything behind' do
    expect(described_class.new(subdomain: 'login', owner_email: 'a@b.example').run).to be_nil
    create.run

    workflow = create
    expect(workflow.run).to be_nil
    expect(workflow.errors.join).to include('Subdomain')
    expect(Tenant.where(subdomain: 'initech').count).to eq(1)

    invalid = described_class.new(subdomain: 'globex', owner_email: 'not-an-email')
    expect(invalid.run).to be_nil
    expect(Tenant.exists?(subdomain: 'globex')).to be(false)
  end

  it 'leaves a feedback space that can be deleted with all its data' do
    tenant = create.run
    Current.set(tenant: tenant) { tenant.destroy! }
    expect(Tenant.exists?(tenant.id)).to be(false)
    expect(User.unscoped.where(tenant_id: tenant.id)).to be_empty
    expect(Board.unscoped.where(tenant_id: tenant.id)).to be_empty
  end
end
