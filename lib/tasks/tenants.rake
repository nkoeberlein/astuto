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
    subdomain = ENV['SUBDOMAIN'].to_s.strip.downcase
    owner_email = ENV['OWNER_EMAIL'].to_s.strip
    abort 'SUBDOMAIN and OWNER_EMAIL are required' if subdomain.blank? || owner_email.blank?
    abort "#{subdomain} is reserved" if RESERVED_SUBDOMAINS.include?(subdomain)

    password = SecureRandom.base58(20)
    tenant = nil
    ActiveRecord::Base.transaction do
      tenant = Tenant.create!(
        site_name: ENV['NAME'].presence || subdomain,
        subdomain: subdomain,
        locale: ENV['LOCALE'].presence || I18n.default_locale.to_s,
        status: 'active'
      )
      Current.tenant = tenant
      User.create!(
        full_name: ENV['OWNER_NAME'].presence || I18n.t('defaults.user_full_name'),
        email: owner_email,
        password: password,
        role: 'owner',
        confirmed_at: Time.current
      )
      CreateWelcomeEntitiesWorkflow.new.run
    end

    url = URI.parse(Rails.application.base_url.to_s)
    url.host = "#{tenant.subdomain}.#{url.host}" if Rails.application.multi_tenancy?
    puts "Created feedback space #{tenant.subdomain} (#{url})"
    puts "Owner: #{owner_email} / #{password}"
    puts 'Ask the owner to change the password after the first login.'
  ensure
    Current.reset
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
