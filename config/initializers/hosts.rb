# This initializer allows configuring allowed hosts dynamically
# via the environment variable RAILS_HOSTS.
#
# Example:
#   RAILS_HOSTS=feedback.mydom.org,other.domain.com
#
# will allow both "feedback.mydom.org" and "other.domain.com"

if ENV["RAILS_HOSTS"].present?
  ENV["RAILS_HOSTS"].split(",").each do |host|
    Rails.application.config.hosts << host.strip
  end

  # Multi-tenancy: custom domains of feedback spaces are allowed too, without listing each one
  if ENV["MULTI_TENANCY"] == "true"
    Rails.application.config.hosts << ->(host) { TenantHosts.known?(host) }
  end
end
