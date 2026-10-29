# Instance admin pages (/instance on the BASE_URL host, multi-tenancy only): the operator of the
# instance manages feedback spaces here. Users belong to one feedback space each, so there is no
# instance admin account; the page is protected with HTTP Basic auth and INSTANCE_ADMIN_PASSWORD.
module InstanceAdmin
  class BaseController < ActionController::Base
    USERNAME = 'admin'.freeze

    layout 'instance_admin'

    before_action :ensure_available
    before_action :authenticate
    before_action :set_locale

    helper_method :tenant_url

    private

      # Invisible (404) unless switched on, and only on the base host, never on a feedback space
      def ensure_available
        available = Rails.application.multi_tenancy? &&
          instance_admin_password.present? &&
          request.host.to_s.downcase == Rails.application.base_url_host.downcase
        head :not_found unless available
      end

      def authenticate
        authenticate_or_request_with_http_basic('Astuto instance admin') do |username, password|
          # Both comparisons always run, so the timing does not tell which part was wrong
          [
            ActiveSupport::SecurityUtils.secure_compare(username.to_s, USERNAME),
            ActiveSupport::SecurityUtils.secure_compare(password.to_s, instance_admin_password),
          ].all?
        end
      end

      def set_locale
        preferred = request.env['HTTP_ACCEPT_LANGUAGE'].to_s[/\A\s*([a-z]{2})/i, 1].to_s.downcase
        I18n.locale = preferred == 'de' ? :de : :en
      end

      def tenant_url(tenant)
        uri = URI.parse(Rails.application.base_url.to_s)
        uri.host = tenant.custom_domain.presence || "#{tenant.subdomain}.#{uri.host}"
        uri.port = nil if tenant.custom_domain.present?
        uri.to_s
      end

      def instance_admin_password
        ENV['INSTANCE_ADMIN_PASSWORD'].to_s
      end
  end
end
