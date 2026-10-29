# Embeddable widget of a feedback space (Site settings › Widget, docs/widget.md).
# The secret signs visitor tokens (HS256 JWT) in the customer's app; allowed_origins limits
# which sites may show the widget (CSP frame-ancestors of /embed), one origin per line.
class WidgetConfig < ApplicationRecord
  include TenantOwnable

  belongs_to :tenant

  validate :origins_valid

  before_validation :ensure_secret

  def self.current
    first_or_initialize
  end

  def self.encryptor
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key('astuto widget secret', 32)
    ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-gcm', serializer: :json)
  end

  def secret
    secret_ciphertext.presence && self.class.encryptor.decrypt_and_verify(secret_ciphertext)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  def regenerate_secret
    self.secret_ciphertext = self.class.encryptor.encrypt_and_sign("wsk_#{SecureRandom.hex(32)}")
  end

  def origins
    allowed_origins.to_s.split(/[\s,]+/).map { |origin| origin.chomp('/') }.reject(&:blank?).uniq
  end

  private

    def ensure_secret
      regenerate_secret if secret_ciphertext.blank?
    end

    def origins_valid
      invalid = origins.reject { |origin| origin.match?(%r{\Ahttps?://[a-z0-9.-]+(:\d+)?\z}i) }
      errors.add(:allowed_origins, :invalid) if invalid.any?
    end
end
