# Posts of one person for "My feedback": what they posted (also pending, rejected or merged, so
# they see what became of it), voted on or follow. Most recently updated first, so status
# changes come to the top. Fetches one extra row to know whether another page exists.
class MyPostsQuery
  FILTERS = %w[created voted followed].freeze

  Result = Struct.new(:posts, :page, :has_more, keyword_init: true)

  def initialize(user:, filter:, page: 1, per_page: Rails.application.posts_per_page)
    @user = user
    @filter = FILTERS.include?(filter.to_s) ? filter.to_s : 'created'
    @page = [page.to_i, 1].max
    @per_page = per_page
  end

  attr_reader :filter

  def call
    rows = scope.offset((@page - 1) * @per_page).limit(@per_page + 1).to_a
    Result.new(posts: rows.first(@per_page), page: @page, has_more: rows.size > @per_page)
  end

  # Number of posts behind each filter, for the tabs
  def counts
    FILTERS.index_with { |filter| filtered(Post.all, filter).count }
  end

  private

    def scope
      posts = Post
        .select(
          'posts.id', 'posts.title', 'posts.slug', 'posts.description', 'posts.post_status_id',
          'posts.board_id', 'posts.approval_status', 'posts.created_at', 'posts.updated_at',
          'COUNT(DISTINCT likes.id) AS likes_count',
          'COUNT(DISTINCT comments.id) AS comments_count',
          "(SELECT COUNT(*) FROM likes WHERE likes.user_id = #{@user.id.to_i} AND likes.post_id = posts.id) AS liked"
        )
        .left_outer_joins(:likes, :comments)
        .group('posts.id')
        .order(updated_at: :desc, id: :desc)
      filtered(posts, @filter)
    end

    # Votes and follows count only on posts everybody sees (or the person's own)
    def filtered(posts, filter)
      visible = posts.where(approval_status: 'approved').or(posts.where(user_id: @user.id).where.not(approval_status: 'merged'))
      case filter
      when 'created' then posts.where(user_id: @user.id)
      when 'voted' then visible.where(id: Like.where(user_id: @user.id).select(:post_id))
      when 'followed' then visible.where(id: Follow.where(user_id: @user.id).select(:post_id))
      end
    end
end
