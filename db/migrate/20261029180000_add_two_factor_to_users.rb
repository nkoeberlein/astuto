# Two-factor authentication with an authenticator app (TOTP) and one-time backup codes
class AddTwoFactorToUsers < ActiveRecord::Migration[8.1]
  def change
    # Encrypted with a key derived from SECRET_KEY_BASE (User::TwoFactor)
    add_column :users, :otp_secret_ciphertext, :string
    add_column :users, :otp_enabled_at, :datetime
    # Time step of the last accepted code, so a code works only once
    add_column :users, :otp_last_used_at, :bigint
    # SHA-256 digests of unused backup codes
    add_column :users, :otp_backup_code_digests, :jsonb, null: false, default: []

    add_column :tenant_settings, :require_two_factor_for_staff, :boolean, null: false, default: false
  end
end
