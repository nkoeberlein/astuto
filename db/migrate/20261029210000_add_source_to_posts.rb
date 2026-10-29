# Where feedback came from when a moderator or an assistant (MCP) captured it: a link to the
# Slack thread, email or support ticket, and a short label. Visible to moderators only.
class AddSourceToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :source_url, :string, limit: 500
    add_column :posts, :source_label, :string, limit: 40
  end
end
