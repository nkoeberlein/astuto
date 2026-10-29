# frozen_string_literal: true

module Mcp
  # Queries and JSON shapes for posts shared by the MCP tools
  module PostData
    module_function

    # Posts with vote and comment counts and the hotness used by order_by('trending')
    def with_counts
      Post
        .select(
          'posts.id', 'posts.title', 'posts.slug', 'posts.description', 'posts.board_id',
          'posts.post_status_id', 'posts.approval_status', 'posts.source_url', 'posts.source_label', 'posts.created_at', 'posts.updated_at',
          'COUNT(DISTINCT likes.id) AS likes_count',
          'COUNT(DISTINCT comments.id) AS comments_count',
          '((LOG(COUNT(DISTINCT likes.id) + 1) + LOG(COUNT(DISTINCT comments.id) + 1)) + (EXTRACT(EPOCH FROM posts.created_at) / 45000)) AS hotness'
        )
        .left_outer_joins(:likes, :comments)
        .group('posts.id')
    end

    # Default is approved posts only; 'all' includes pending and rejected ones
    def filter_approval(scope, approval_status)
      case approval_status
      when 'pending', 'rejected' then scope.where(approval_status: approval_status)
      when 'all' then scope
      else scope.where(approval_status: 'approved')
      end
    end

    def filter_board_and_status(scope, board_id:, post_status_id:)
      scope = scope.where(board_id: board_id.to_i) if board_id.present?
      scope = scope.where(post_status_id: post_status_id.to_i) if post_status_id.present?
      scope
    end

    def summary(post)
      {
        id: post.id,
        slug: post.slug,
        title: post.title,
        description: post.description,
        board_id: post.board_id,
        post_status_id: post.post_status_id,
        approval_status: post.approval_status,
        source_url: post.source_url,
        source_label: post.source_label,
        likes_count: post.likes_count.to_i,
        comments_count: post.comments_count.to_i,
        created_at: post.created_at.iso8601
      }
    end

    def person(user)
      user && { id: user.id, full_name: user.full_name, role: user.role }
    end

    def clamp_limit(value, default:, max:)
      num = value.to_i
      return default if num <= 0

      [num, max].min
    end
  end
end
