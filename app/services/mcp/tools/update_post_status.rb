# frozen_string_literal: true

module Mcp
  module Tools
    class UpdatePostStatus < Base
      # Tells "post_status_id: null" (clear the status) apart from "not given"
      NOT_GIVEN = Object.new.freeze

      tool_name 'update_post_status'
      description 'Update the roadmap/workflow status (or approval status / board) of a feedback post and notify followers.'
      input_schema(
        properties: {
          post_id: { type: 'integer', description: 'ID of the post to update.' },
          post_status_id: { type: %w[integer null], description: 'New post status ID (or null to clear the status).' },
          board_id: { type: 'integer', description: 'Optional new board ID to move the post to.' },
          approval_status: { type: 'string', enum: %w[approved pending rejected], description: 'Optional approval status moderation change.' }
        },
        required: ['post_id'],
        additionalProperties: false
      )
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.run(user:, post_id:, post_status_id: NOT_GIVEN, board_id: nil, approval_status: nil)
        post = Post.find(post_id)
        unless post_status_id.equal?(NOT_GIVEN)
          post.post_status_id = post_status_id.nil? ? nil : PostStatus.find(post_status_id).id
        end
        post.board_id = Board.find(board_id).id if board_id.present?
        post.approval_status = approval_status if approval_status.present?

        status_changed = post.post_status_id_changed?
        workflow = ExecutePostStatusChangeLogicWorkflow.new(user_id: user.id, post: post, post_status_id: post.post_status_id)

        # Post update and timeline entry together or not at all (#169); mails after commit
        ActiveRecord::Base.transaction do
          post.save!
          workflow.create_status_change! if status_changed
        end
        workflow.notify_followers if status_changed

        {
          post: {
            id: post.id,
            slug: post.slug,
            title: post.title,
            board_id: post.board_id,
            post_status_id: post.post_status_id,
            approval_status: post.approval_status,
            updated_at: post.updated_at.iso8601
          }
        }
      end
    end
  end
end
