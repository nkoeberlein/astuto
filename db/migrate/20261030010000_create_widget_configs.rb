# Embeddable widget (docs/widget.md): the customer's app signs visitor tokens with the secret,
# Astuto links them to accounts by widget_external_id or email
class CreateWidgetConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :widget_configs do |t|
      t.references :tenant, null: false, foreign_key: true, index: { unique: true }
      t.boolean :enabled, null: false, default: false
      t.text :secret_ciphertext
      t.text :allowed_origins, null: false, default: ''
      t.boolean :auto_create_users, null: false, default: true
      t.timestamps
    end

    add_column :users, :widget_external_id, :string
    add_index :users, [:tenant_id, :widget_external_id], unique: true, where: 'widget_external_id IS NOT NULL'
  end
end
