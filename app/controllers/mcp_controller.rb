# frozen_string_literal: true

# Streamable HTTP endpoint (/mcp) for the Model Context Protocol (MCP).
# Authenticates using the tenant's API keys (Authorization: Bearer <token> or X-Api-Key);
# only active moderators and admins get access. Tools: app/services/mcp/tools.
class McpController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :check_tenant_is_private
  skip_before_action :load_tenant_data

  prepend_before_action :set_current_tenant
  before_action :authenticate_mcp_api_key

  # POST, GET and DELETE /mcp. The official SDK transport handles the protocol
  # (version negotiation, JSON-RPC, notifications). Stateless: every POST stands
  # alone, so the app needs no session store and runs behind any load balancer.
  def handle
    transport = MCP::Server::Transports::StreamableHTTPTransport.new(
      Mcp::Server.build(user: @current_user),
      stateless: true,
      enable_json_response: true,
      serve_subscriptions_listen: false,
      # Rails host authorization (config.hosts) and tenant lookup already vetted the
      # host; the SDK still rejects cross-origin browser requests via Origin.
      allowed_hosts: [request.host.downcase]
    )
    status, headers, body = transport.handle_request(request)

    headers.each { |name, value| response.set_header(name, value) }
    content = body.respond_to?(:join) ? body.join : ''
    if content.empty?
      head status
    else
      render body: content, status: status, content_type: headers['Content-Type'] || 'application/json'
    end
  end

  private

    def set_current_tenant
      Current.tenant = get_tenant_from_request(request)
      render_unauthorized('Tenant not found.') if Current.tenant.nil?
      I18n.locale = I18n.default_locale
    end

    def authenticate_mcp_api_key
      token = extract_api_token
      api_key = token.present? ? ApiKey.find_by_token(token) : nil
      user = api_key&.user

      unless user&.active? && user.moderator?
        render_unauthorized('Valid moderator or admin API key required.')
        return
      end

      @current_api_key = api_key
      @current_user = user
    end

    def extract_api_token
      ApiToken.extract(request)
    end

    def render_unauthorized(message)
      headers['WWW-Authenticate'] = 'Bearer realm="Astuto MCP"'
      render json: {
        jsonrpc: '2.0',
        id: nil,
        error: { code: -32_001, message: message }
      }, status: :unauthorized
    end
end
