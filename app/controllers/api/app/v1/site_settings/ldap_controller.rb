module Api::App::V1::SiteSettings
  # Site settings › Authentication › LDAP / Active Directory (admins)
  #   GET   /api/app/v1/site_settings/ldap
  #   PATCH /api/app/v1/site_settings/ldap { enabled, host, port, ..., bindPassword (blank keeps it) }
  #   POST  /api/app/v1/site_settings/ldap/test { login }: does the service account find this login?
  class LdapController < Api::App::BaseController
    FIELDS = %w[enabled label host port encryption verify_certificate base_dn bind_dn user_filter email_attribute name_attribute auto_create_users].freeze

    before_action :require_admin

    def show
      render json: serialize(LdapConfig.current)
    end

    def update
      config = LdapConfig.current
      attributes = FIELDS.each_with_object({}) do |field, memo|
        key = field.camelize(:lower)
        memo[field] = params[key] if params.key?(key)
      end
      config.assign_attributes(attributes)
      config.bind_password = params[:bindPassword] if params[:bindPassword].present?
      config.bind_password = nil if params.key?(:bindDn) && params[:bindDn].blank?
      return render_error(:unprocessable_content, config.errors.full_messages.join(', ')) unless config.save

      audit('ldap.update', nil, changes: config.saved_changes, prefix: 'ldap_config', subject_label: config.label) if config.saved_changes?
      render json: serialize(config)
    end

    def test
      result, error = LdapConfig.current.test_lookup(params[:login].to_s)
      return render_error(:unprocessable_content, error) unless result

      render json: { dn: result.dn, email: result.email, name: result.name }
    end

    private

      def serialize(config)
        {
          enabled: config.enabled, label: config.label, host: config.host, port: config.port,
          encryption: config.encryption, verifyCertificate: config.verify_certificate,
          baseDn: config.base_dn, bindDn: config.bind_dn, bindPasswordSet: config.bind_password_ciphertext.present?,
          userFilter: config.user_filter, emailAttribute: config.email_attribute, nameAttribute: config.name_attribute,
          autoCreateUsers: config.auto_create_users
        }
      end
  end
end
