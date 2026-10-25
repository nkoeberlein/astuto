# Webhook URLs and headers used to be encrypted with Marshal serialization.
# Re-encrypt them with JSON so the stored values are portable (v3 TypeScript backend).
# Reading Marshal values keeps working, so this migration can be re-run safely.
class ReencryptWebhooksAsJson < ActiveRecord::Migration[8.1]
  class MigrationWebhook < ActiveRecord::Base
    self.table_name = 'webhooks'
  end

  def up
    key = Digest::SHA256.digest(Rails.application.secret_key_base)
    encryptor = ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-gcm', serializer: :json_allow_marshal)

    MigrationWebhook.find_each do |webhook|
      changes = %w[url http_headers].filter_map do |column|
        value = webhook[column]
        next if value.blank?

        [column, encryptor.encrypt_and_sign(encryptor.decrypt_and_verify(value))]
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        say "Webhook #{webhook.id}: #{column} could not be decrypted (SECRET_KEY_BASE changed?), left as is"
        nil
      end

      webhook.update_columns(changes.to_h) if changes.any?
    end
  end

  def down
    # Nothing to do: Marshal and JSON values can both be read.
  end
end
