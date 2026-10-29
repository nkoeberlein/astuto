# Admin approval of new accounts (#362): sign-ups wait with status pending_approval
class AddUserApproval < ActiveRecord::Migration[8.1]
  def change
    add_column :tenant_settings, :require_user_approval, :boolean, null: false, default: false
  end
end
