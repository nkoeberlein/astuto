# Astuto Evolution has no paid plans: the Stripe billing of the former astuto.io hosting is gone
class DropTenantBillings < ActiveRecord::Migration[8.1]
  def change
    drop_table :tenant_billings do |t|
      t.references :tenant, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.datetime :trial_ends_at, precision: nil
      t.timestamps
      t.string :customer_id
      t.datetime :subscription_ends_at, precision: nil
      t.string :slug, index: { unique: true }
      t.string :auth_token
    end
  end
end
