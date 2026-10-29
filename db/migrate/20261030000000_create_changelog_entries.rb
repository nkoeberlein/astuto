# Changelog: release notes that link the posts they deliver. published_at nil is a draft.
class CreateChangelogEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :changelog_entries do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :title, null: false
      t.text :body, null: false, default: ''
      t.datetime :published_at
      # Followers of the linked posts are emailed once, on the first publication
      t.datetime :followers_notified_at
      t.timestamps
    end
    add_index :changelog_entries, [:tenant_id, :published_at]

    create_table :changelog_entry_posts do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :changelog_entry, null: false, foreign_key: { on_delete: :cascade }
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :changelog_entry_posts, [:changelog_entry_id, :post_id], unique: true
  end
end
