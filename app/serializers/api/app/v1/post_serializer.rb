module Api::App::V1
  module PostSerializer
    # Row from BoardPostsQuery (includes aggregated counts)
    def self.list_item(post)
      {
        id: post.id,
        slug: post.slug,
        title: post.title,
        description: post.description,
        postStatusId: post.post_status_id,
        likesCount: post.likes_count.to_i,
        commentsCount: post.comments_count.to_i,
        liked: post.liked.to_i.positive?,
        createdAt: post.created_at.iso8601
      }
    end

    # Row from RoadmapQuery (includes aggregated counts)
    def self.roadmap_item(post)
      {
        id: post.id,
        slug: post.slug,
        title: post.title,
        boardId: post.board_id,
        likesCount: post.likes_count.to_i,
        commentsCount: post.comments_count.to_i,
        liked: post.liked.to_i.positive?,
        updatedAt: post.updated_at.iso8601
      }
    end

    def self.detail(post, current_user:)
      {
        id: post.id,
        slug: post.slug,
        title: post.title,
        description: post.description,
        boardId: post.board_id,
        postStatusId: post.post_status_id,
        approvalStatus: post.approval_status,
        author: AuthorSerializer.call(post.user),
        likesCount: post.likes.count,
        commentsCount: post.comments.count,
        liked: current_user.present? && post.likes.exists?(user_id: current_user.id),
        followed: current_user.present? && post.follows.exists?(user_id: current_user.id),
        createdAt: post.created_at.iso8601,
        updatedAt: post.updated_at.iso8601
      }
    end
  end
end
