# Hosts that belong to this instance: the BASE_URL host and, with multi-tenancy, the subdomains
# and custom domains of feedback spaces that are not blocked. Used for Caddy's on-demand TLS
# check and to let custom domains pass Rails' host authorization when RAILS_HOSTS is set.
module TenantHosts
  def self.known?(host)
    domain = host.to_s.strip.split(':').first.to_s.downcase
    return false if domain.blank?

    base_host = Rails.application.base_url_host.downcase
    return true if domain == base_host
    return false unless Rails.application.multi_tenancy?

    tenants = Tenant.where.not(status: :blocked)
    if domain.end_with?(".#{base_host}")
      subdomain = domain.delete_suffix(".#{base_host}")
      !RESERVED_SUBDOMAINS.include?(subdomain) && tenants.exists?(subdomain: subdomain)
    else
      tenants.exists?(custom_domain: domain)
    end
  end
end
