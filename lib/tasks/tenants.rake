# Feedback spaces of a multi-tenant instance (MULTI_TENANCY=true), until the instance admin UI
# exists (#76). See docs/multi-tenancy.md.
namespace :tenants do
  desc 'List feedback spaces'
  task list: :environment do
    Tenant.order(:id).each do |tenant|
      puts [tenant.id, tenant.subdomain, tenant.status, tenant.custom_domain, tenant.site_name].map(&:to_s).join("\t")
    end
  end

  desc 'Create a feedback space: SUBDOMAIN=acme NAME="Acme" OWNER_EMAIL=owner@acme.example [OWNER_NAME=...] [LOCALE=de]'
  task create: :environment do
    workflow = CreateTenantWorkflow.new(
      subdomain: ENV['SUBDOMAIN'], site_name: ENV['NAME'], owner_email: ENV['OWNER_EMAIL'],
      owner_name: ENV['OWNER_NAME'], locale: ENV['LOCALE']
    )
    abort 'SUBDOMAIN and OWNER_EMAIL are required' if ENV['SUBDOMAIN'].blank? || ENV['OWNER_EMAIL'].blank?
    tenant = workflow.run
    abort workflow.errors.join(', ') unless workflow.success?

    url = URI.parse(Rails.application.base_url.to_s)
    url.host = "#{tenant.subdomain}.#{url.host}" if Rails.application.multi_tenancy?
    puts "Created feedback space #{tenant.subdomain} (#{url})"
    puts "Owner: #{workflow.owner.email} / #{workflow.password}"
    puts 'Ask the owner to change the password after the first login.'
  end

  desc 'Block a feedback space (its pages show "blocked", data stays): SUBDOMAIN=acme'
  task block: :environment do
    tenant = Tenant.find_by!(subdomain: ENV.fetch('SUBDOMAIN'))
    tenant.update!(status: 'blocked')
    puts "Blocked #{tenant.subdomain}"
  end

  desc 'Unblock a feedback space: SUBDOMAIN=acme'
  task unblock: :environment do
    tenant = Tenant.find_by!(subdomain: ENV.fetch('SUBDOMAIN'))
    tenant.update!(status: 'active')
    puts "Unblocked #{tenant.subdomain}"
  end
end
