class Webhook < ApplicationRecord
  include TenantOwnable

  before_save :encrypt_url
  after_find :decrypt_url
  before_save :encrypt_http_headers
  after_find :decrypt_http_headers
  before_validation :ensure_signing_secret
  before_save :encrypt_signing_secret
  after_find :decrypt_signing_secret
  # Back to plain text in memory, so the saved record serializes and runs like a loaded one
  after_save :decrypt_url, :decrypt_http_headers, :decrypt_signing_secret

  has_many :deliveries, class_name: 'WebhookDelivery', dependent: :delete_all

  validates :name, presence: true, uniqueness: { scope: :tenant_id }, length: { maximum: 255 }
  validates :url, presence: true, format: { with: URI::RFC2396_PARSER.make_regexp(%w(http https)), message: I18n.t('common.validations.url') }
  validates :trigger, presence: true
  validates :http_method, presence: true

  enum :trigger, [
    :new_post,
    :new_post_pending_approval,
    :delete_post,
    :post_status_change,
    :new_comment,
    :new_vote,
    :new_user
  ]

  enum :http_method, [
    :http_post,
    :http_put,
    :http_patch,
    :http_delete
  ]

  # URL and headers can contain secrets, so they are stored encrypted (AES-256-GCM,
  # key = SHA-256 of SECRET_KEY_BASE). Values are serialized as JSON so the v3 backend
  # can read them; values written by older versions with Marshal can still be read.
  def self.encryptor
    key = Digest::SHA256.digest(Rails.application.secret_key_base)
    ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-gcm', serializer: :json_allow_marshal)
  end

  SIGNATURE_HEADER = 'X-Astuto-Signature'.freeze
  TIMESTAMP_HEADER = 'X-Astuto-Timestamp'.freeze
  EVENT_HEADER = 'X-Astuto-Event'.freeze

  # Headers that let the receiver check sender and age of a delivery:
  # X-Astuto-Signature: sha256=HMAC-SHA256(signing_secret, "<timestamp>.<body>")
  def signature_headers(body, timestamp: Time.now.to_i)
    digest = OpenSSL::HMAC.hexdigest('SHA256', signing_secret.to_s, "#{timestamp}.#{body}")
    { SIGNATURE_HEADER => "sha256=#{digest}", TIMESTAMP_HEADER => timestamp.to_s, EVENT_HEADER => trigger.to_s }
  end

  def regenerate_signing_secret!
    self.signing_secret = self.class.generate_signing_secret
    save!
  end

  def self.generate_signing_secret
    "whsec_#{SecureRandom.hex(32)}"
  end

  private

    def ensure_signing_secret
      self.signing_secret = self.class.generate_signing_secret if signing_secret.blank?
    end

    def encrypt_signing_secret
      return if signing_secret.nil?

      self.signing_secret = self.class.encryptor.encrypt_and_sign(signing_secret)
    end

    def decrypt_signing_secret
      return if signing_secret.nil?

      self.signing_secret = self.class.encryptor.decrypt_and_verify(signing_secret)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      errors.add(:signing_secret, 'could not be decrypted')
    end

    def encrypt_url
      return if url.nil?

      self.url = self.class.encryptor.encrypt_and_sign(url)
    end

    def decrypt_url
      return if url.nil?

      self.url = self.class.encryptor.decrypt_and_verify(url)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      errors.add(:url, 'could not be decrypted')
    end

    def encrypt_http_headers
      return if http_headers.nil?

      self.http_headers = self.class.encryptor.encrypt_and_sign(http_headers.to_json)
    end

    def decrypt_http_headers
      return if http_headers.nil?

      self.http_headers = JSON.parse(self.class.encryptor.decrypt_and_verify(http_headers)) if http_headers.present?
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      errors.add(:http_headers, 'could not be decrypted')
    end
end
