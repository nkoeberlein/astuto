# frozen_string_literal: true

module Mcp
  module Tools
    class AddComment < Base
      tool_name 'add_comment'
      description 'Add a comment, reply, or official moderator status update to a feedback post.'
      input_schema(
        properties: {
          post_id: { type: 'integer', description: 'ID of the post to comment on.' },
          body: { type: 'string', description: 'Comment text body.' },
          parent_id: { type: 'integer', description: 'Optional parent comment ID when replying to an existing comment.' },
          is_post_update: { type: 'boolean', description: 'Whether to mark the comment as an official post update (notifies all post followers).' }
        },
        required: %w[post_id body],
        additionalProperties: false
      )
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.run(user:, post_id:, body:, parent_id: nil, is_post_update: false)
        post = Post.find(post_id)
        comment = Comment.create!(
          post: post,
          user: user,
          parent: parent_id.present? ? post.comments.find(parent_id) : nil,
          body: body,
          is_post_update: is_post_update == true
        )
        SendNotificationForCommentWorkflow.new(comment: comment).run

        {
          comment: {
            id: comment.id,
            post_id: comment.post_id,
            parent_id: comment.parent_id,
            body: comment.body,
            is_post_update: comment.is_post_update,
            created_at: comment.created_at.iso8601
          }
        }
      end
    end
  end
end
