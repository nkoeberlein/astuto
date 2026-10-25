# frozen_string_literal: true

module Mcp
  # Builds the MCP server (official `mcp` gem) for one request. Tools live in
  # app/services/mcp/tools and get the authenticated moderator via server_context.
  module Server
    NAME = 'astuto-evolution-mcp'
    VERSION = '2.0.0'
    INSTRUCTIONS = 'Astuto Evolution MCP server. Use these tools to search and triage customer feedback, ' \
                   'inspect top requests and roadmaps, update post statuses, and post moderator replies.'

    TOOLS = [
      Tools::ListBoards,
      Tools::SearchPosts,
      Tools::TopRequests,
      Tools::GetPost,
      Tools::GetRoadmap,
      Tools::CreatePost,
      Tools::UpdatePostStatus,
      Tools::AddComment
    ].freeze

    def self.build(user:)
      MCP::Server.new(
        name: NAME,
        title: AstutoProject::NAME,
        version: VERSION,
        instructions: INSTRUCTIONS,
        tools: TOOLS,
        server_context: { user: user }
      )
    end
  end
end
