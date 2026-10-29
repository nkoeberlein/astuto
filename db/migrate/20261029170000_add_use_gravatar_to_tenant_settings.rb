# Gravatar avatars can be switched off per feedback space (GDPR: the request reveals the hash of
# the email address to gravatar.com). Existing spaces keep them.
class AddUseGravatarToTenantSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :tenant_settings, :use_gravatar, :boolean, null: false, default: true
  end
end
