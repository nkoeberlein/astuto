# Who changed what in moderation and site settings (Site settings › Audit log)
class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.references :tenant, null: false, foreign_key: true
      # The acting user; kept as a name snapshot in actor_label too
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :actor_label
      t.string :action, null: false
      t.string :subject_type
      t.bigint :subject_id
      t.string :subject_label
      # { "post.title" => [old, new] }, secrets filtered
      t.jsonb :field_changes, null: false, default: {}
      t.string :source, null: false, default: 'app'
      t.string :ip
      t.datetime :created_at, null: false
    end
    add_index :audit_events, [:tenant_id, :created_at]
    add_index :audit_events, [:tenant_id, :action]
  end
end
