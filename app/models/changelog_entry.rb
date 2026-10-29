# Release note of the changelog (/changelog). Links the posts it delivers; publishing it tells
# their followers (PublishChangelogEntryWorkflow). Drafts (published_at nil) are for moderators.
class ChangelogEntry < ApplicationRecord
  include TenantOwnable

  belongs_to :user, optional: true
  has_many :changelog_entry_posts, dependent: :delete_all
  has_many :posts, through: :changelog_entry_posts

  validates :title, presence: true, length: { maximum: 200 }
  validates :body, length: { maximum: 20_000 }

  scope :published, -> { where.not(published_at: nil).where(published_at: ..Time.current) }
  scope :newest_first, -> { order(Arel.sql('published_at DESC NULLS FIRST'), id: :desc) }

  def published?
    published_at.present? && published_at <= Time.current
  end
end
