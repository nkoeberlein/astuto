# Creates a post together with its side records in one transaction (#169):
# - the author's follow (skipped for anonymous posts)
# - a status change entry when a moderator picks an initial status (#119)
# Either all records are written or none.
#
# Used by the legacy UI, the app API and the MCP server so they share one set of rules.
class CreatePostWorkflow
  attr_reader :post

  # post:        unsaved Post with all attributes set
  # follower:    user who follows the new post, usually the author (nil = nobody)
  # status_actor: user recorded in the timeline when the post starts with a status
  def initialize(post:, follower: nil, status_actor: nil)
    @post = post
    @follower = follower
    @status_actor = status_actor
  end

  # Returns true on success. On failure the errors are on post.errors.
  def run
    run!
    true
  rescue ActiveRecord::RecordInvalid => e
    copy_errors(e.record)
    false
  end

  # Raises ActiveRecord::RecordInvalid on failure
  def run!
    ActiveRecord::Base.transaction do
      @post.save!
      Follow.find_or_create_by!(post: @post, user: @follower) if @follower
      create_status_change! if @post.post_status_id.present? && @status_actor
    end
    @post
  end

  private

    def create_status_change!
      ExecutePostStatusChangeLogicWorkflow.new(
        user_id: @status_actor.id,
        post: @post,
        post_status_id: @post.post_status_id
      ).create_status_change!
    end

    # A failing follow or status change rolls back the post; surface its errors on the post
    def copy_errors(record)
      return if record.equal?(@post)

      record.errors.full_messages.each { |message| @post.errors.add(:base, message) }
    end
end
