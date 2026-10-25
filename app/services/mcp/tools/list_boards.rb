# frozen_string_literal: true

module Mcp
  module Tools
    class ListBoards < Base
      tool_name 'list_boards'
      description 'List all feedback boards in the current tenant with their approved post counts.'
      input_schema(properties: {}, additionalProperties: false)
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.run(user:)
        boards = Board.order(order: :asc).map do |board|
          {
            id: board.id,
            name: board.name,
            slug: board.slug,
            description: board.description,
            order: board.order,
            approved_posts_count: board.posts.where(approval_status: 'approved').count
          }
        end
        { boards: boards }
      end
    end
  end
end
