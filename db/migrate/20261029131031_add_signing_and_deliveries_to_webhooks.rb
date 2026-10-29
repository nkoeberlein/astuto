# Webhooks get a signing secret (HMAC-SHA256 signature header) and a delivery log (#458).
# The secret is stored encrypted like the URL (Webhook.encryptor).
class AddSigningAndDeliveriesToWebhooks < ActiveRecord::Migration[8.1]
  def up
    add_column :webhooks, :signing_secret, :string

    create_table :webhook_deliveries do |t|
      t.references :webhook, null: false, foreign_key: { on_delete: :cascade }
      t.references :tenant, null: false, foreign_key: true
      t.string :trigger, null: false
      t.boolean :is_test, null: false, default: false
      t.boolean :success, null: false, default: false
      t.integer :http_status
      t.integer :duration_ms
      t.text :error
      t.text :response_body
      t.datetime :created_at, null: false
    end
    add_index :webhook_deliveries, [:webhook_id, :created_at]

    # Existing webhooks get a secret too; receivers can start checking signatures when they like
    encryptor = ActiveSupport::MessageEncryptor.new(
      Digest::SHA256.digest(Rails.application.secret_key_base), cipher: 'aes-256-gcm', serializer: :json
    )
    select_values('SELECT id FROM webhooks').each do |id|
      secret = encryptor.encrypt_and_sign(SecureRandom.hex(32))
      execute(sanitize_sql(['UPDATE webhooks SET signing_secret = ? WHERE id = ?', secret, id]))
    end
  end

  def down
    drop_table :webhook_deliveries
    remove_column :webhooks, :signing_secret
  end

  private

    def sanitize_sql(array)
      ActiveRecord::Base.sanitize_sql_array(array)
    end
end
