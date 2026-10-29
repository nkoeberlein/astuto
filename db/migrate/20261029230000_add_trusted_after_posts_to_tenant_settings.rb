# Approval policy "new_users_require_approval": an account's first posts wait for approval,
# after this many approved posts new ones are approved automatically
class AddTrustedAfterPostsToTenantSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :tenant_settings, :trusted_after_posts, :integer, null: false, default: 3
  end
end
