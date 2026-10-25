class AddMailLogoSizeToTenantSettings < ActiveRecord::Migration[8.1]
  def change
    # Logo size in email templates (#474)
    add_column :tenant_settings, :mail_logo_size, :integer, default: 64, null: false
  end
end