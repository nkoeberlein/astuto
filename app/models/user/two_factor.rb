# Two-factor authentication for a user: TOTP (RFC 6238, 30-second codes from an authenticator
# app) plus ten one-time backup codes. The secret is stored encrypted; backup codes only as
# digests. Admins can require it for staff (TenantSetting#require_two_factor_for_staff).
module User::TwoFactor
  extend ActiveSupport::Concern

  BACKUP_CODES = 10
  # One code before or after the current one is accepted (clock drift)
  DRIFT_SECONDS = 30

  class_methods do
    def two_factor_encryptor
      key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key('astuto two-factor secret', 32)
      ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-gcm', serializer: :json)
    end
  end

  def two_factor_enabled?
    otp_enabled_at.present?
  end

  # Staff of a space that requires 2FA, who have not set it up yet
  def two_factor_setup_required?
    moderator? && !two_factor_enabled? && Current.tenant&.tenant_setting&.require_two_factor_for_staff == true
  end

  # A new secret, not active until confirmed with a code (#enable_two_factor!)
  def start_two_factor_setup!
    secret = ROTP::Base32.random
    update!(otp_secret_ciphertext: self.class.two_factor_encryptor.encrypt_and_sign(secret), otp_enabled_at: nil,
            otp_last_used_at: nil, otp_backup_code_digests: [])
    secret
  end

  def otp_secret
    return if otp_secret_ciphertext.blank?

    self.class.two_factor_encryptor.decrypt_and_verify(otp_secret_ciphertext)
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  # otpauth:// URI for the QR code of the authenticator app
  def two_factor_provisioning_uri
    totp&.provisioning_uri(email)
  end

  # Activates 2FA when the code matches the pending secret; returns the backup codes (shown once)
  def enable_two_factor!(code)
    return nil if two_factor_enabled? || !accept_totp?(code)

    codes = new_backup_codes
    update!(otp_enabled_at: Time.current, otp_backup_code_digests: codes.map { |c| digest(c) })
    codes
  end

  def disable_two_factor!
    update!(otp_secret_ciphertext: nil, otp_enabled_at: nil, otp_last_used_at: nil, otp_backup_code_digests: [])
  end

  # A fresh set of backup codes; the old ones stop working
  def regenerate_backup_codes!
    codes = new_backup_codes
    update!(otp_backup_code_digests: codes.map { |c| digest(c) })
    codes
  end

  def backup_codes_left
    otp_backup_code_digests.size
  end

  # A code from the app (each one only once) or an unused backup code (then used up)
  def verify_two_factor(code)
    return false unless two_factor_enabled?

    accept_totp?(code) || use_backup_code?(code)
  end

  private

    def totp
      secret = otp_secret
      secret && ROTP::TOTP.new(secret, issuer: Current.tenant&.site_name.presence || AstutoProject::NAME)
    end

    def normalize_code(code)
      code.to_s.gsub(/[\s-]/, '').downcase
    end

    def accept_totp?(code)
      code = normalize_code(code)
      return false unless code.match?(/\A\d{6}\z/) && totp

      timestamp = totp.verify(code, drift_behind: DRIFT_SECONDS, drift_ahead: DRIFT_SECONDS, after: otp_last_used_at)
      return false unless timestamp

      update_column(:otp_last_used_at, timestamp)
      true
    end

    def use_backup_code?(code)
      given = digest(normalize_code(code))
      match = otp_backup_code_digests.find { |stored| ActiveSupport::SecurityUtils.secure_compare(stored, given) }
      return false unless match

      update_column(:otp_backup_code_digests, otp_backup_code_digests - [match])
      true
    end

    def new_backup_codes
      Array.new(BACKUP_CODES) { SecureRandom.hex(5).scan(/.{5}/).join('-') }
    end

    def digest(code)
      Digest::SHA256.hexdigest(normalize_code(code))
    end
end
