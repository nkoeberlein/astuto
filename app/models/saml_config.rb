# SAML 2.0 single sign-on of a feedback space (Site settings › Authentication, docs/sso.md).
# Astuto is the service provider; the identity provider (Entra ID, Okta, Keycloak, ADFS, ...)
# signs the responses with the certificate stored here.
class SamlConfig < ApplicationRecord
  include TenantOwnable

  belongs_to :tenant

  # Common attribute names for the email address and the name, tried when none is configured
  EMAIL_ATTRIBUTES = %w[
    email mail emailaddress
    http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
    urn:oid:0.9.2342.19200300.100.1.3
  ].freeze
  NAME_ATTRIBUTES = %w[
    displayName name cn
    http://schemas.microsoft.com/identity/claims/displayname
    http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name
    urn:oid:2.16.840.1.113730.3.1.241
  ].freeze

  validates :label, presence: true, length: { maximum: 60 }
  validates :idp_entity_id, :idp_sso_url, :idp_cert, presence: true, if: :enabled?
  validate :sso_url_is_https, if: -> { idp_sso_url.present? }
  validate :certificate_parses, if: -> { idp_cert.present? }

  def self.current
    first_or_initialize
  end

  def usable?
    enabled? && idp_entity_id.present? && idp_sso_url.present? && idp_cert.present?
  end

  # Settings for ruby-saml; the SP side comes from the controller (URLs of this host)
  def saml_settings(sp_entity_id:, acs_url:)
    settings = OneLogin::RubySaml::Settings.new
    settings.sp_entity_id = sp_entity_id
    settings.assertion_consumer_service_url = acs_url
    settings.idp_entity_id = idp_entity_id
    settings.idp_sso_service_url = idp_sso_url
    settings.idp_cert = idp_cert
    settings.name_identifier_format = 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
    settings.security[:strict_audience_validation] = true
    settings.security[:want_assertions_signed] = false
    settings.soft = true
    settings
  end

  def email_from(response)
    value = attribute_value(response, email_attribute.presence ? [email_attribute] : EMAIL_ATTRIBUTES)
    value ||= response.nameid if email_attribute.blank?
    value.to_s.strip.downcase.presence
  end

  def name_from(response)
    attribute_value(response, name_attribute.presence ? [name_attribute] : NAME_ATTRIBUTES).to_s.strip.presence
  end

  private

    def attribute_value(response, names)
      names.each do |name|
        value = response.attributes[name]
        return value if value.present?
      end
      nil
    end

    def sso_url_is_https
      uri = URI.parse(idp_sso_url)
      errors.add(:idp_sso_url, :invalid) unless uri.is_a?(URI::HTTPS) || (Rails.env.local? && uri.is_a?(URI::HTTP))
    rescue URI::InvalidURIError
      errors.add(:idp_sso_url, :invalid)
    end

    def certificate_parses
      OpenSSL::X509::Certificate.new(idp_cert.to_s.include?('BEGIN CERTIFICATE') ? idp_cert : "-----BEGIN CERTIFICATE-----\n#{idp_cert.strip}\n-----END CERTIFICATE-----")
    rescue OpenSSL::X509::CertificateError
      errors.add(:idp_cert, :invalid)
    end
end
