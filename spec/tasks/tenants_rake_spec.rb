require 'rails_helper'
require 'rake'

RSpec.describe 'tenants rake tasks' do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('tenants:create')
  end

  def run_task(name, env)
    stub_const('ENV', ENV.to_h.merge(env))
    Rake::Task[name].reenable
    expect { Rake::Task[name].invoke }.to output.to_stdout
  ensure
    Current.tenant = Tenant.find_by(subdomain: 'default') || Current.tenant
  end

  it 'creates a feedback space with a confirmed owner and the welcome boards' do
    run_task('tenants:create', 'SUBDOMAIN' => 'initech', 'NAME' => 'Initech', 'OWNER_EMAIL' => 'owner@initech.example')

    tenant = Tenant.find_by!(subdomain: 'initech')
    expect(tenant).to be_active
    expect(TenantSetting.unscoped.where(tenant_id: tenant.id).count).to eq(1)
    owner = User.unscoped.find_by!(tenant_id: tenant.id)
    expect(owner).to be_owner
    expect(owner.email).to eq('owner@initech.example')
    expect(owner.confirmed_at).to be_present
    expect(Board.unscoped.where(tenant_id: tenant.id)).to exist
  end

  it 'blocks and unblocks a feedback space' do
    tenant = Tenant.create!(site_name: 'Acme', subdomain: 'acme', status: 'active')

    run_task('tenants:block', 'SUBDOMAIN' => 'acme')
    expect(tenant.reload).to be_blocked
    run_task('tenants:unblock', 'SUBDOMAIN' => 'acme')
    expect(tenant.reload).to be_active
  end
end
