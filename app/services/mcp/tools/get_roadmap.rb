# frozen_string_literal: true

module Mcp
  module Tools
    class GetRoadmap < Base
      tool_name 'get_roadmap'
      description 'Retrieve the public roadmap columns (statuses marked show_in_roadmap) and their assigned posts.'
      input_schema(
        properties: {
          limit_per_status: { type: 'integer', description: 'Maximum posts returned per roadmap status column (default: 50, max: 200).' }
        },
        additionalProperties: false
      )
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.run(user:, limit_per_status: nil)
        limit = PostData.clamp_limit(limit_per_status, default: 50, max: 200)
        columns = PostStatus.where(show_in_roadmap: true).order(order: :asc).map do |status|
          posts = PostData.with_counts
            .where(approval_status: 'approved', post_status_id: status.id)
            .order_by('most_voted')
            .limit(limit)
          {
            id: status.id,
            name: status.name,
            color: status.color,
            order: status.order,
            posts: posts.map { |post| PostData.summary(post) }
          }
        end

        { roadmap: columns }
      end
    end
  end
end
