# Extra HTTP headers for the profile request of an OAuth provider (#485),
# e.g. a User-Agent or a Client-Id. Stored as [{ "key": ..., "value": ... }].
class AddProfileHeadersToOAuths < ActiveRecord::Migration[8.1]
  def change
    add_column :o_auths, :profile_headers, :jsonb, default: [], null: false
  end
end
