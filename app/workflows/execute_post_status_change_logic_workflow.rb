class ExecutePostStatusChangeLogicWorkflow
  attr_accessor :user_id, :post, :post_status_id

  def initialize(user_id:, post:, post_status_id:)
    @user_id = user_id
    @post = post
    @post_status_id = post_status_id
  end

  # Writes the status change record. Call inside a transaction together with the
  # post update to keep them atomic (#169).
  def create_status_change!
    PostStatusChange.create!(
      user_id: @user_id,
      post_id: @post.id,
      post_status_id: @post_status_id
    )
  end

  # Enqueues follower notifications. Call after the surrounding transaction
  # has committed, so mail jobs never run before their data is visible.
  def notify_followers
    return if @post_status_id.nil?

    @post.followers.each do |follower|
      # Private boards: no mail about posts the follower can no longer see
      next unless @post.board.visible_to?(follower)

      UserMailer.notify_follower_of_post_status_change(post: @post, follower: follower).deliver_later
    end
  end

  def run
    create_status_change!
    notify_followers
  end
end