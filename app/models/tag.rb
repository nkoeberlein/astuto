# Label for posts (#171), e.g. "Mobile" or "Billing": set up in Site settings › Tags, put on
# posts by moderators, shown on posts and used as a board filter
class Tag < ApplicationRecord
  include TenantOwnable
  include Orderable

  has_many :post_tags, dependent: :delete_all
  has_many :posts, through: :post_tags

  validates :name, presence: true, length: { maximum: 40 }, uniqueness: { scope: :tenant_id, case_sensitive: false }
  validates :color, format: { with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/ }

  before_validation { self.name = name.to_s.squish }
end
