# frozen_string_literal: true

module Mcp
  module Tools
    class CreatePost < Base
      tool_name 'create_post'
      description 'Create a new feedback post in a board on behalf of the authenticated moderator/admin.'
      input_schema(
        properties: {
          board_id: { type: 'integer', description: 'Target board ID.' },
          title: { type: 'string', description: 'Post title (4 to 128 characters).' },
          description: { type: 'string', description: 'Optional post description / details.' },
          post_status_id: { type: 'integer', description: 'Optional initial post status ID.' }
        },
        required: %w[board_id title],
        additionalProperties: false
      )
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.run(user:, board_id:, title:, description: nil, post_status_id: nil)
        post = Post.new(
          board: Board.find(board_id),
          post_status: post_status_id.present? ? PostStatus.find(post_status_id) : nil,
          title: title,
          description: description,
          user: user,
          approval_status: 'approved'
        )
        CreatePostWorkflow.new(post: post, follower: user, status_actor: user).run!

        {
          post: {
            id: post.id,
            slug: post.slug,
            title: post.title,
            description: post.description,
            board_id: post.board_id,
            post_status_id: post.post_status_id,
            approval_status: post.approval_status,
            created_at: post.created_at.iso8601
          }
        }
      end
    end
  end
end
