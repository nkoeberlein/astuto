# frozen_string_literal: true

module Mcp
  module Tools
    class GetPost < Base
      tool_name 'get_post'
      description 'Get full details of a single feedback post (by numeric ID or slug), including votes and all comments.'
      input_schema(
        properties: { id: { type: %w[integer string], description: 'Post numeric ID or URL slug.' } },
        required: ['id'],
        additionalProperties: false
      )
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.run(user:, id:)
        post = find_post(id)
        comments = post.comments.includes(:user).order(created_at: :asc).map do |comment|
          {
            id: comment.id,
            body: comment.body,
            parent_id: comment.parent_id,
            is_post_update: comment.is_post_update,
            author: PostData.person(comment.user),
            created_at: comment.created_at.iso8601
          }
        end

        {
          post: {
            id: post.id,
            slug: post.slug,
            title: post.title,
            description: post.description,
            approval_status: post.approval_status,
            board: { id: post.board.id, name: post.board.name, slug: post.board.slug },
            post_status: post.post_status && { id: post.post_status.id, name: post.post_status.name, color: post.post_status.color },
            author: PostData.person(post.user),
            likes_count: post.likes.count,
            comments_count: comments.size,
            created_at: post.created_at.iso8601,
            updated_at: post.updated_at.iso8601,
            comments: comments
          }
        }
      end

      # Numeric strings are IDs first, but a post may also have a numeric slug
      def self.find_post(identifier)
        raise ArgumentError, 'Parameter "id" is required' if identifier.blank?

        scope = Post.includes(:board, :post_status, :user)
        by_id = scope.find_by(id: identifier.to_i) if identifier.to_s.match?(/\A\d+\z/)
        by_id || scope.friendly.find(identifier.to_s)
      end
    end
  end
end
