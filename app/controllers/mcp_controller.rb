# frozen_string_literal: true

# Streamable HTTP endpoint (/mcp) for the Model Context Protocol (MCP).
# Authenticates using the tenant's API keys (Authorization: Bearer <token> or X-Api-Key).
class McpController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :check_tenant_is_private
  skip_before_action :load_tenant_data

  prepend_before_action :set_current_tenant
  before_action :authenticate_mcp_api_key

  # POST /mcp — JSON-RPC 2.0 request/notification/batch over Streamable HTTP
  def handle
    raw_body = request.raw_post
    payload = JSON.parse(raw_body)
    response_payload = Mcp::Server.new(user: @current_user).handle(payload)

    if response_payload.nil?
      head :accepted
    else
      render json: response_payload, status: :ok
    end
  rescue JSON::ParserError
    render json: {
      jsonrpc: '2.0',
      id: nil,
      error: { code: Mcp::Server::PARSE_ERROR, message: 'Parse error: invalid JSON' }
    }, status: :bad_request
  end

  # GET /mcp — Streamable HTTP spec allows returning 405 when server-initiated SSE stream is not offered
  def show
    response.set_header('Allow', 'POST, DELETE')
    head :method_not_allowed
  end

  # DELETE /mcp — Streamable HTTP session termination (stateless server acknowledges with 204)
  def destroy
    head :no_content
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
      auth_header = request.headers['Authorization'].to_s
      if auth_header.start_with?('Bearer ')
        auth_header.delete_prefix('Bearer ').strip
      else
        request.headers['X-Api-Key'].to_s.strip.presence
      end
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
