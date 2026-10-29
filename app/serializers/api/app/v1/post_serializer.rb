module Api::App::V1
  module PostSerializer
    # Row from BoardPostsQuery (includes aggregated counts)
    # Tag ids of many posts in one query, for list items
    def self.tag_ids_by_post(posts)
      PostTag.where(post_id: posts.map(&:id)).joins(:tag).order('tags.order').pluck(:post_id, :tag_id)
        .group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
    end

    def self.list_item(post, tag_ids: [])
      {
        id: post.id,
        slug: post.slug,
        title: post.title,
        description: post.description,
        postStatusId: post.post_status_id,
        likesCount: post.likes_count.to_i,
        commentsCount: post.comments_count.to_i,
        liked: post.liked.to_i.positive?,
        tagIds: tag_ids,
        createdAt: post.created_at.iso8601
      }
    end

    # Row from MyPostsQuery: list item plus board and approval status (own posts can be pending)
    def self.my_item(post, board:, tag_ids: [])
      list_item(post, tag_ids: tag_ids).merge(
        board: board && { name: board.name, slug: board.slug },
        approvalStatus: post.approval_status,
        updatedAt: post.updated_at.iso8601
      )
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

    # Feedback queue for moderators (posts waiting for approval or rejected)
    def self.moderation_item(post)
      {
        id: post.id,
        slug: post.slug,
        title: post.title,
        description: post.description,
        boardId: post.board_id,
        approvalStatus: post.approval_status,
        author: AuthorSerializer.call(post.user),
        createdAt: post.created_at.iso8601
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
        tagIds: post.tags.map(&:id),
        author: AuthorSerializer.call(post.user),
        likesCount: post.likes.count,
        commentsCount: post.comments.count,
        liked: current_user.present? && post.likes.exists?(user_id: current_user.id),
        followed: current_user.present? && post.follows.exists?(user_id: current_user.id),
        # Where the feedback came from; often an internal link, so moderators only
        source: current_user&.moderator? && (post.source_url.present? || post.source_label.present?) ? { url: post.source_url, label: post.source_label } : nil,
        # Duplicates merged into this post (their links lead here)
        mergedPosts: post.merged_posts.order(:created_at).map { |merged| { title: merged.title } },
        changelogEntries: post.changelog_entries.published.newest_first.map { |entry| { id: entry.id, title: entry.title } },
        createdAt: post.created_at.iso8601,
        updatedAt: post.updated_at.iso8601
      }
    end
  end
end
