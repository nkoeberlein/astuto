# A post delivered by a changelog entry
class ChangelogEntryPost < ApplicationRecord
  include TenantOwnable

  belongs_to :changelog_entry
  belongs_to :post

  validates :post_id, uniqueness: { scope: :changelog_entry_id }
end
