# Reads an API key from a request: "Authorization: Bearer <token>" (or Rails'
# "Token token=<token>") first, then the "X-Api-Key" header. Shared by the MCP
# endpoint and the Rack::Attack throttles, so both read the same token.
module ApiToken
  def self.extract(request)
    token, _options = ActionController::HttpAuthentication::Token.token_and_options(request)
    token.to_s.strip.presence || request.headers['X-Api-Key'].to_s.strip.presence
  end
end
