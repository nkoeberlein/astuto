# What happened in a feedback space between from and to, as one person sees it. Used for the
# recap email (SendRecapEmails, UserMailer#recap):
# - everyone: new feedback by others, the most voted posts of the period, status changes of
#   posts they follow
# - moderators also: feedback that waits for approval
class RecapDigest
  LIST_SIZE = 5

  attr_reader :user, :from, :to

  def initialize(user:, from:, to:)
    @user = user
    @from = from
    @to = to
  end

  def any?
    new_posts_count.positive? || top_posts.any? || status_changes.any? || pending_posts_count.to_i.positive?
  end

  def new_posts_count
    @new_posts_count ||= new_posts_scope.count
  end

  def new_posts
    @new_posts ||= new_posts_scope.order(created_at: :desc).limit(LIST_SIZE).to_a
  end

  # Posts with the most votes cast in the period; period_votes holds that number
  def top_posts
    @top_posts ||= Post
      .where(approval_status: 'approved')
      .joins(:likes)
      .where(likes: { created_at: range })
      .group('posts.id')
      .select('posts.*', 'COUNT(likes.id) AS period_votes')
      .order('period_votes DESC', 'posts.id DESC')
      .limit(LIST_SIZE)
      .to_a
  end

  # Latest status change per followed post, made by someone else
  def status_changes
    @status_changes ||= PostStatusChange
      .where(created_at: range, post_id: user.follows.select(:post_id))
      .where.not(user_id: user.id)
      .joins(:post).where(posts: { approval_status: 'approved' })
      .includes(:post, :post_status)
      .order(created_at: :desc)
      .to_a
      .uniq(&:post_id)
      .first(LIST_SIZE * 2)
  end

  def pending_posts_count
    return unless user.moderator?

    @pending_posts_count ||= Post.where(approval_status: 'pending', created_at: range).count
  end

  private

    def range
      from..to
    end

    def new_posts_scope
      # IS DISTINCT FROM keeps anonymous posts (user_id NULL), unlike !=
      Post.where(approval_status: 'approved', created_at: range).where('posts.user_id IS DISTINCT FROM ?', user.id)
    end
end
