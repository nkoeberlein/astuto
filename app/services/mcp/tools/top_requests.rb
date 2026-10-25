# frozen_string_literal: true

module Mcp
  module Tools
    class TopRequests < Base
      SORTS = %w[most_voted trending newest oldest].freeze

      tool_name 'top_requests'
      description 'List top customer feedback requests ranked by votes (most_voted) or hotness (trending).'
      input_schema(
        properties: {
          sort_by: { type: 'string', enum: SORTS, description: 'Ranking order (default: most_voted).' },
          board_id: { type: 'integer', description: 'Optional board ID to filter by.' },
          post_status_id: { type: 'integer', description: 'Optional post status ID to filter by.' },
          limit: { type: 'integer', description: 'Maximum number of posts to return (default: 20, max: 100).' }
        },
        additionalProperties: false
      )
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.run(user:, sort_by: nil, board_id: nil, post_status_id: nil, limit: nil)
        sort_by = SORTS.include?(sort_by) ? sort_by : 'most_voted'
        scope = PostData.with_counts.where(approval_status: 'approved')
        scope = PostData.filter_board_and_status(scope, board_id: board_id, post_status_id: post_status_id)
        scope = scope.order_by(sort_by).limit(PostData.clamp_limit(limit, default: 20, max: 100))

        { sort_by: sort_by, posts: scope.map { |post| PostData.summary(post) } }
      end
    end
  end
end
