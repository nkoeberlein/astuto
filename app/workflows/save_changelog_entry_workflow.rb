# Creates or updates a changelog entry with its linked posts. Publishing (published: true on a
# draft) sets published_at; the first publication emails the followers of the linked posts
# (each person once, not the publisher, only with notifications on).
class SaveChangelogEntryWorkflow
  attr_reader :entry

  def initialize(entry:, actor:, attributes:, post_ids: nil, published: nil)
    @entry = entry
    @actor = actor
    @attributes = attributes
    @post_ids = post_ids
    @published = published
  end

  # Returns false with entry.errors on invalid input
  def run
    saved = ActiveRecord::Base.transaction do
      entry.assign_attributes(@attributes)
      entry.user ||= @actor
      entry.published_at = publication_time unless @published.nil?
      entry.save || raise(ActiveRecord::Rollback)
      replace_posts unless @post_ids.nil?
      true
    end
    return false unless saved

    notify_followers if entry.published? && entry.followers_notified_at.nil?
    true
  end

  private

    def publication_time
      @published ? (entry.published_at || Time.current) : nil
    end

    # Only approved posts can be linked; unknown ids are ignored
    def replace_posts
      ids = Post.where(id: Array(@post_ids).map(&:to_i), approval_status: 'approved').pluck(:id)
      entry.changelog_entry_posts.where.not(post_id: ids).delete_all
      (ids - entry.changelog_entry_posts.pluck(:post_id)).each { |post_id| entry.changelog_entry_posts.create!(post_id: post_id) }
      entry.posts.reset
    end

    def notify_followers
      entry.update_column(:followers_notified_at, Time.current)
      recipients = User
        .where(id: Follow.where(post_id: entry.posts.select(:id)).select(:user_id))
        .where(status: 'active', notifications_enabled: true)
        .where.not(id: @actor&.id)
      recipients.find_each { |user| UserMailer.notify_follower_of_changelog_entry(user: user, entry: entry).deliver_later }
    end
end
