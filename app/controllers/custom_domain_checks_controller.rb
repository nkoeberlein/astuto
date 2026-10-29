# Answers "may this instance get a TLS certificate for this host?" for Caddy's on-demand TLS
# (`on_demand_tls { ask http://astuto:3000/custom_domain_check }`): 200 for the instance's own
# host and for feedback spaces' subdomains and custom domains, 404 for anything else, so nobody
# can make Caddy request certificates for arbitrary hosts pointed at the server.
class CustomDomainChecksController < ActionController::API
  def show
    head(TenantHosts.known?(params[:domain]) ? :ok : :not_found)
  end
end
