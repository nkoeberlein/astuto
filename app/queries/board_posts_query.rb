# Approved posts of a board with vote and comment counts, for list views.
# Fetches one extra row to know whether another page exists, avoiding a
# COUNT over the grouped query.
class BoardPostsQuery
  SORT_OPTIONS = %w[trending newest most_voted oldest].freeze

  Result = Struct.new(:posts, :page, :has_more, keyword_init: true)

  def initialize(board:, user: nil, search: nil, sort_by: nil, post_status_ids: nil, page: 1, per_page: Rails.application.posts_per_page)
    @board = board
    @user = user
    @search = search
    @sort_by = sort_by.presence || Current.tenant&.tenant_setting&.default_post_sorting || 'trending'
    @sort_by = SORT_OPTIONS.include?(@sort_by) ? @sort_by : 'trending'
    @post_status_ids = post_status_ids
    @page = [page.to_i, 1].max
    @per_page = per_page
  end

  def call
    rows = scope.offset((@page - 1) * @per_page).limit(@per_page + 1).to_a

    Result.new(posts: rows.first(@per_page), page: @page, has_more: rows.size > @per_page)
  end

  private

    def scope
      posts = Post
        .select(
          'posts.id', 'posts.title', 'posts.slug', 'posts.description', 'posts.post_status_id', 'posts.created_at',
          'COUNT(DISTINCT likes.id) AS likes_count',
          'COUNT(DISTINCT comments.id) AS comments_count',
          '((LOG(COUNT(DISTINCT likes.id) + 1) + LOG(COUNT(DISTINCT comments.id) + 1)) + (EXTRACT(EPOCH FROM posts.created_at) / 45000)) AS hotness',
          "(SELECT COUNT(*) FROM likes WHERE likes.user_id = #{@user ? @user.id.to_i : -1} AND likes.post_id = posts.id) AS liked"
        )
        .left_outer_joins(:likes, :comments)
        .group('posts.id')
        .where(board_id: @board.id, approval_status: 'approved')
        .search_by_name_or_description(@search)
        .order_by(@sort_by)

      return posts if @post_status_ids.blank?

      # "0" stands for posts without a status
      posts.where(post_status_id: Array(@post_status_ids).map { |id| id.to_s == '0' ? nil : id })
    end
end
