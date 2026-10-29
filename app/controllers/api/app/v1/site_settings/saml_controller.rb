module Api::App::V1::SiteSettings
  # Site settings › Authentication › SAML single sign-on (admins)
  #   GET   /api/app/v1/site_settings/saml
  #   PATCH /api/app/v1/site_settings/saml { enabled, label, idpEntityId, idpSsoUrl, idpCert, ... }
  #   POST  /api/app/v1/site_settings/saml/parse_metadata { xml }: IdP fields from its metadata
  #         (pasted, never fetched from a URL), not saved
  class SamlController < Api::App::BaseController
    FIELDS = %w[enabled label idp_entity_id idp_sso_url idp_cert email_attribute name_attribute auto_create_users].freeze

    before_action :require_admin

    def show
      render json: serialize(SamlConfig.current)
    end

    def update
      config = SamlConfig.current
      config.assign_attributes(FIELDS.each_with_object({}) do |field, attributes|
        key = field.camelize(:lower)
        attributes[field] = params[key] if params.key?(key)
      end)
      return render_error(:unprocessable_content, config.errors.full_messages.join(', ')) unless config.save

      audit('saml.update', nil, changes: config.saved_changes, prefix: 'saml_config', subject_label: config.label) if config.saved_changes?
      render json: serialize(config)
    end

    def parse_metadata
      parsed = OneLogin::RubySaml::IdpMetadataParser.new.parse_to_hash(params[:xml].to_s)
      return render_error(:unprocessable_content, I18n.t('saml.metadata_invalid')) if parsed[:idp_sso_service_url].blank?

      render json: {
        idpEntityId: parsed[:idp_entity_id],
        idpSsoUrl: parsed[:idp_sso_service_url],
        idpCert: parsed[:idp_cert] || Array(parsed.dig(:idp_cert_multi, :signing)).first
      }
    rescue StandardError
      render_error(:unprocessable_content, I18n.t('saml.metadata_invalid'))
    end

    private

      def serialize(config)
        {
          enabled: config.enabled,
          label: config.label,
          idpEntityId: config.idp_entity_id,
          idpSsoUrl: config.idp_sso_url,
          idpCert: config.idp_cert,
          emailAttribute: config.email_attribute,
          nameAttribute: config.name_attribute,
          autoCreateUsers: config.auto_create_users,
          # What the identity provider needs to know about Astuto
          spEntityId: get_url_for(method(:saml_metadata_url), disallow_custom_domain: true),
          acsUrl: get_url_for(method(:saml_acs_url), disallow_custom_domain: true)
        }
      end
  end
end
