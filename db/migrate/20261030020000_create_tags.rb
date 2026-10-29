# Tags for posts (#171): admins define them, moderators put them on posts, everyone filters
class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false, default: '#64748b'
      t.integer :order, null: false
      t.timestamps
    end
    add_index :tags, [:tenant_id, :name], unique: true

    create_table :post_tags do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.references :tag, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :post_tags, [:post_id, :tag_id], unique: true
  end
end
