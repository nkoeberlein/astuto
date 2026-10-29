# Merges a duplicate into another post (moderators, app API and MCP): votes, followers and
# comments move to the target (people who voted or followed both keep one), the duplicate gets
# approval status "merged" and redirects to the target. Not reversible.
class MergePostsWorkflow
  class Error < StandardError; end

  attr_reader :source, :target

  def initialize(source:, target:, actor:)
    @source = source
    @target = target
    @actor = actor
  end

  def run!
    raise Error, I18n.t('post.merge.same_post') if source.id == target.id
    raise Error, I18n.t('post.merge.already_merged') if source.merged? || target.merged?

    ActiveRecord::Base.transaction do
      move(source.likes, target.likes)
      move(source.follows, target.follows)
      source.comments.update_all(post_id: target.id, updated_at: Time.current)
      move_changelog_links
      # The kept post gets the tags of the duplicate too
      target.tag_ids = (target.tag_ids + source.tag_ids).uniq
      # Posts merged into the duplicate earlier now point to the target directly
      Post.where(merged_into_post_id: source.id).update_all(merged_into_post_id: target.id)
      source.update!(approval_status: 'merged', merged_into: target)
      target.touch
    end
    target
  end

  private

    # Changelog entries that named the duplicate now name the target (once)
    def move_changelog_links
      linked = target.changelog_entry_posts.pluck(:changelog_entry_id)
      source.changelog_entry_posts.where(changelog_entry_id: linked).delete_all
      source.changelog_entry_posts.update_all(post_id: target.id, updated_at: Time.current)
    end

    # Rows of the duplicate move to the target unless the same person already has one there
    def move(from, to)
      taken = to.pluck(:user_id)
      from.where(user_id: taken).delete_all
      from.update_all(post_id: target.id, updated_at: Time.current)
    end
end
