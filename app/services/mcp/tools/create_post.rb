# frozen_string_literal: true

module Mcp
  module Tools
    class CreatePost < Base
      tool_name 'create_post'
      description 'Create a new feedback post in a board. By default the authenticated moderator/admin is the author; ' \
                  'admins can name an existing user of this feedback space as author (author_email), e.g. for feedback ' \
                  'collected from Slack, email or a support ticket. source_url and source_label record where it came from ' \
                  '(visible to moderators only).'
      input_schema(
        properties: {
          board_id: { type: 'integer', description: 'Target board ID.' },
          title: { type: 'string', description: 'Post title (4 to 128 characters).' },
          description: { type: 'string', description: 'Optional post description / details.' },
          post_status_id: { type: 'integer', description: 'Optional initial post status ID.' },
          author_email: { type: 'string', description: 'Admins only: email of an existing user of this feedback space to post for.' },
          source_url: { type: 'string', description: 'Optional link to the original feedback (Slack thread, email, ticket); http(s) or mailto.' },
          source_label: { type: 'string', description: 'Optional short name of the source, e.g. "Slack", "Support ticket" (max. 40 characters).' }
        },
        required: %w[board_id title],
        additionalProperties: false
      )
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.run(user:, board_id:, title:, description: nil, post_status_id: nil, author_email: nil, source_url: nil, source_label: nil)
        author = author_email.present? ? author_for(user, author_email) : user
        post = Post.new(
          board: Board.find(board_id),
          post_status: post_status_id.present? ? PostStatus.find(post_status_id) : nil,
          title: title,
          description: description,
          user: author,
          approval_status: 'approved',
          source_url: source_url.presence,
          source_label: source_label.presence
        )
        # The author follows their post (status changes by mail); the moderator sets the status
        CreatePostWorkflow.new(post: post, follower: author, status_actor: user).run!
        audit('post.create_for_author', user, post, post.saved_changes.slice('user_id', 'source_url', 'source_label')) if author != user

        {
          post: {
            id: post.id,
            slug: post.slug,
            title: post.title,
            description: post.description,
            board_id: post.board_id,
            post_status_id: post.post_status_id,
            approval_status: post.approval_status,
            author_id: post.user_id,
            source_url: post.source_url,
            source_label: post.source_label,
            created_at: post.created_at.iso8601
          }
        }
      end

      # Only admins post for others, and only for existing accounts of this feedback space
      def self.author_for(user, email)
        raise ArgumentError, 'Only admins can post on behalf of other users.' unless user.admin?

        author = User.find_for_authentication(email: email.to_s.strip)
        raise ArgumentError, "No user with the email #{email} in this feedback space." unless author&.active?

        author
      end
    end
  end
end
