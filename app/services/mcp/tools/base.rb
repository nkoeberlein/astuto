# frozen_string_literal: true

module Mcp
  module Tools
    # Base class of all MCP tools. Subclasses implement `self.run(user:, **args)` and
    # return a Hash; it goes back to the client as JSON text and as structuredContent.
    # Lookup and validation errors become tool errors (isError: true) the model can read.
    class Base < MCP::Tool
      HANDLED_ERRORS = [ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, ArgumentError].freeze

      class << self
        def call(server_context:, **args)
          result = run(user: server_context[:user], **args)
          MCP::Tool::Response.new([{ type: 'text', text: JSON.pretty_generate(result) }], structured_content: result)
        rescue *HANDLED_ERRORS => e
          MCP::Tool::Response.new([{ type: 'text', text: e.message }], error: true)
        end

        def run(user:, **args)
          raise NotImplementedError
        end

        # Audit log entry for a moderator action through MCP
        def audit(action, user, subject, changes)
          AuditEvent.record!(action: action, actor: user, subject: subject, changes: changes, source: 'mcp')
        rescue StandardError => e
          Rails.logger.error { "[audit] #{action} not recorded: #{e.class}: #{e.message}" }
        end
      end
    end
  end
end
