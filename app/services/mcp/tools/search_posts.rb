# frozen_string_literal: true

module Mcp
  module Tools
    class SearchPosts < Base
      tool_name 'search_posts'
      description 'Search feedback posts by keyword or full-text query, optionally filtered by board, status, or approval status.'
      input_schema(
        properties: {
          query: { type: 'string', description: 'Search query matched against post title and description.' },
          board_id: { type: 'integer', description: 'Optional board ID to filter by.' },
          post_status_id: { type: 'integer', description: 'Optional post status ID to filter by.' },
          approval_status: { type: 'string', enum: %w[approved pending rejected all], description: 'Approval status filter (default: approved).' },
          limit: { type: 'integer', description: 'Maximum number of posts to return (default: 20, max: 100).' }
        },
        additionalProperties: false
      )
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.run(user:, query: nil, board_id: nil, post_status_id: nil, approval_status: nil, limit: nil)
        scope = PostData.filter_approval(PostData.with_counts, approval_status)
        scope = PostData.filter_board_and_status(scope, board_id: board_id, post_status_id: post_status_id)
        scope = scope.search_by_name_or_description(query) if query.present?
        scope = scope.order_by('most_voted').limit(PostData.clamp_limit(limit, default: 20, max: 100))

        { posts: scope.map { |post| PostData.summary(post) } }
      end
    end
  end
end
