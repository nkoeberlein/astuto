# Roadmap columns: the statuses shown in the roadmap with their approved
# posts, including vote and comment counts. Each column holds at most
# `limit` posts; `posts_count` is the full number.
class RoadmapQuery
  SORT_OPTIONS = %w[most_voted recently_updated].freeze
  POSTS_PER_COLUMN = 100

  Column = Struct.new(:status, :posts, :posts_count, keyword_init: true)

  def initialize(user: nil, sort_by: nil, limit: POSTS_PER_COLUMN)
    @user = user
    @sort_by = SORT_OPTIONS.include?(sort_by) ? sort_by : 'most_voted'
    @limit = limit
  end

  def call
    statuses = PostStatus.find_roadmap.to_a
    return [] if statuses.empty?

    posts_by_status = scope(statuses.map(&:id)).to_a.group_by(&:post_status_id)
    statuses.map do |status|
      posts = posts_by_status.fetch(status.id, [])
      Column.new(status: status, posts: posts.first(@limit), posts_count: posts.size)
    end
  end

  private

    def scope(status_ids)
      Post
        .select(
          'posts.id', 'posts.title', 'posts.slug', 'posts.board_id', 'posts.post_status_id', 'posts.updated_at',
          'COUNT(DISTINCT likes.id) AS likes_count',
          'COUNT(DISTINCT comments.id) AS comments_count',
          "(SELECT COUNT(*) FROM likes WHERE likes.user_id = #{@user ? @user.id.to_i : -1} AND likes.post_id = posts.id) AS liked"
        )
        .left_outer_joins(:likes, :comments)
        .group('posts.id')
        .where(approval_status: 'approved', post_status_id: status_ids)
        .on_boards_visible_to(@user)
        .order(Arel.sql(order_sql))
    end

    def order_sql
      case @sort_by
      when 'recently_updated' then 'posts.updated_at DESC, posts.id DESC'
      else 'likes_count DESC, posts.updated_at DESC, posts.id DESC'
      end
    end
end
