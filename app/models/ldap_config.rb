# LDAP / Active Directory login of a feedback space (Site settings › Authentication, docs/sso.md).
# The login form sends login name and password; Astuto finds the person's entry with the service
# account (or anonymously) and checks the password by binding as that entry.
class LdapConfig < ApplicationRecord
  include TenantOwnable

  belongs_to :tenant

  ENCRYPTIONS = %w[plain start_tls simple_tls].freeze
  TIMEOUT = 5

  Result = Struct.new(:email, :name, :dn, keyword_init: true)

  validates :label, presence: true, length: { maximum: 60 }
  validates :encryption, inclusion: { in: ENCRYPTIONS }
  validates :port, numericality: { only_integer: true, in: 1..65_535 }
  validates :host, :base_dn, presence: true, if: :enabled?
  validates :email_attribute, :name_attribute, presence: true
  validate :filter_parses

  def self.current
    first_or_initialize
  end

  def self.encryptor
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key('astuto ldap bind password', 32)
    ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-gcm', serializer: :json)
  end

  def usable?
    enabled? && host.present? && base_dn.present?
  end

  def bind_password
    bind_password_ciphertext.presence && self.class.encryptor.decrypt_and_verify(bind_password_ciphertext)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  def bind_password=(value)
    self.bind_password_ciphertext = value.blank? ? nil : self.class.encryptor.encrypt_and_sign(value.to_s)
  end

  # The person's email and name when login and password are right, otherwise nil. An empty
  # password is refused before asking the directory (LDAP treats it as an anonymous bind).
  def authenticate(login, password)
    return nil if login.to_s.strip.empty? || password.to_s.empty?

    entry = find_entry(login)
    return nil unless entry
    return nil unless connection(entry.dn, password).bind

    result_for(entry)
  rescue StandardError => e
    Rails.logger.warn { "[ldap] #{Current.tenant&.subdomain}: #{e.class}: #{e.message}" }
    nil
  end

  # For the settings page: can the service account find this login? Returns [result, error]
  def test_lookup(login)
    service = connection(bind_dn.presence, bind_password)
    return [nil, service.get_operation_result.message] unless service.bind

    entry = find_entry(login, service)
    entry ? [result_for(entry), nil] : [nil, I18n.t('ldap.not_found')]
  rescue StandardError => e
    [nil, "#{e.class}: #{e.message}"]
  end

  private

    def find_entry(login, service = connection(bind_dn.presence, bind_password))
      # Block form: a replacement string would read the escapes (\2a) as backreferences
      escaped = Net::LDAP::Filter.escape(login.to_s.strip)
      filter = Net::LDAP::Filter.construct(user_filter.gsub('%{login}') { escaped })
      entries = service.search(base: base_dn, filter: filter, attributes: [email_attribute, name_attribute, 'cn'].uniq, size: 2, return_result: true)
      # None, or more than one: never guess which person is meant
      entries.size == 1 ? entries.first : nil if entries
    end

    def result_for(entry)
      Result.new(
        email: Array(entry[email_attribute]).first.to_s.strip.downcase.presence,
        name: (Array(entry[name_attribute]).first.presence || Array(entry['cn']).first).to_s.strip.presence,
        dn: entry.dn
      )
    end

    def connection(username, password)
      options = { host: host, port: port, connect_timeout: TIMEOUT }
      unless encryption == 'plain'
        tls = verify_certificate ? OpenSSL::SSL::SSLContext::DEFAULT_PARAMS : { verify_mode: OpenSSL::SSL::VERIFY_NONE }
        options[:encryption] = { method: encryption.to_sym, tls_options: tls }
      end
      options[:auth] = { method: :simple, username: username, password: password.to_s } if username.present?
      Net::LDAP.new(options)
    end

    def filter_parses
      return errors.add(:user_filter, :invalid) unless user_filter.to_s.include?('%{login}')

      Net::LDAP::Filter.construct(user_filter.to_s.gsub('%{login}', 'x'))
    rescue Net::LDAP::FilterSyntaxInvalidError, Net::LDAP::Error
      errors.add(:user_filter, :invalid)
    end
end
