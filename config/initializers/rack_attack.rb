require 'digest'

class Rack::Attack
  APP_API_POSTS_PATH = %r{\A/api/app/v1/boards/[^/]+/posts\z}

  class << self
    def client_ip(req)
      req.get_header('action_dispatch.remote_ip')&.to_s.presence || req.ip
    end

    # ActionDispatch::Request parses JSON request bodies as well as form params
    def parsed_params(req)
      req.env['rack.attack.parsed_params'] ||= ActionDispatch::Request.new(req.env).params
    rescue ActionDispatch::Http::Parameters::ParseError
      {}
    end

    # Hash the bearer/API token before using it in cache keys so raw credentials
    # are never stored in the cache backend.
    def extract_api_token_digest(req)
      token = ApiToken.extract(ActionDispatch::Request.new(req.env))
      Digest::SHA256.hexdigest(token) if token
    end

    def login_request?(req)
      req.post? && (req.path == '/users/sign_in' || req.path == '/api/app/v1/session')
    end

    # Devise forms send user[email], the app API sends email. Malformed bodies
    # (e.g. "user" as a string) must not raise inside the middleware.
    def login_email(req)
      params = parsed_params(req)
      user_params = params['user']
      raw_email = (user_params['email'] if user_params.is_a?(Hash)) || params['email']
      return nil unless raw_email.is_a?(String)

      raw_email.downcase.gsub(/\s+/, '').presence
    end

    def registration_request?(req)
      req.post? && (req.path == '/users' || req.path == '/api/app/v1/registration')
    end

    def password_request?(req)
      (req.post? || req.put? || req.patch?) &&
        (req.path == '/users/password' || req.path == '/api/app/v1/password')
    end

    def post_creation_request?(req)
      req.post? && (req.path == '/posts' || req.path.match?(APP_API_POSTS_PATH))
    end

    def spam_post_submission?(req)
      params = parsed_params(req)

      # App API (POST /api/app/v1/boards/:board_id/posts): only a filled honeypot
      # flags the IP. The controller rejects too-fast forms with 422 on its own,
      # so a person who submits quickly is not locked out for an hour.
      return PostSpamCheck.honeypot_filled?(params['honeypot']) unless req.path == '/posts'

      post_params = params['post']
      post_params = {} unless post_params.is_a?(Hash)

      # Check for honeypot field submission (missing fields count as filled)
      honeypot_filled = post_params['dnf1'] != '' || post_params['dnf2'] != ''

      # Check for time of form render (a missing timestamp counts as too fast)
      rendered_at = post_params['form_rendered_at'].to_i
      too_fast_submit = rendered_at.zero? || Time.now.to_i - rendered_at < PostSpamCheck::MIN_SECONDS_TO_FILL_FORM

      honeypot_filled || too_fast_submit
    end
  end

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!
  #
  # Note: If you're serving assets through rack, those requests may be
  # counted by rack-attack and this throttle may be activated too
  # quickly. If so, enable the condition to exclude them from tracking.

  # Throttle all requests by IP (60rpm) except API and MCP endpoints
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    client_ip(req) unless req.path.start_with?('/api/v1/') || req.path == '/mcp'
  end

  # Throttle requests to REST API v1 endpoints by IP address
  throttle('api/ip', limit: 100, period: 5.minutes) do |req|
    client_ip(req) if req.path.start_with?('/api/v1/')
  end

  # Throttle requests to REST API v1 endpoints by hashed API key
  throttle('api/key', limit: 100, period: 5.minutes) do |req|
    extract_api_token_digest(req) if req.path.start_with?('/api/v1/')
  end

  # Throttle requests to MCP endpoint by IP address (protects against API key brute-force)
  throttle('mcp/ip', limit: 60, period: 1.minute) do |req|
    client_ip(req) if req.path == '/mcp'
  end

  # Throttle requests to MCP endpoint by hashed API key
  throttle('mcp/key', limit: 120, period: 1.minute) do |req|
    extract_api_token_digest(req) if req.path == '/mcp'
  end

  ### Prevent Brute-Force Login & Auth Attacks ###

  # The most common brute-force login attack is a brute-force password
  # attack where an attacker simply tries a large number of emails and
  # passwords to see if any credentials match.
  #
  # Another common method of attack is to use a swarm of computers with
  # different IPs to try brute-forcing a password for a specific account.

  # Throttle POST requests to /users/sign_in and /api/app/v1/session by IP address
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    client_ip(req) if login_request?(req)
  end

  # Throttle POST requests to /users/sign_in and /api/app/v1/session by email param
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/email:#{normalized_email}"
  throttle('logins/email', limit: 5, period: 20.seconds) do |req|
    login_email(req) if login_request?(req)
  end

  # Throttle registration attempts (including invitation tokens) by IP address
  throttle('registrations/ip', limit: 5, period: 1.minute) do |req|
    client_ip(req) if registration_request?(req)
  end

  # Throttle password reset requests and token submissions by IP address
  throttle('passwords/ip', limit: 5, period: 1.minute) do |req|
    client_ip(req) if password_request?(req)
  end

  # Throttle POST requests to /tenants by IP address
  throttle('tenant_signups/ip', limit: 5, period: 20.seconds) do |req|
    client_ip(req) if req.path == '/tenants' && req.post?
  end

  # Throttle POST requests to /posts and /api/app/v1/boards/:board_id/posts by IP address using anti-spam measures
  throttle('posts/ip', limit: 1, period: 1.hour) do |req|
    if post_creation_request?(req)
      ip = client_ip(req)

      if spam_post_submission?(req)
        Rack::Attack.cache.store.write("post-submit-antispam-#{ip}", true, expires_in: 1.hour)
      end

      # Block if this IP was previously flagged
      ip if Rack::Attack.cache.store.read("post-submit-antispam-#{ip}")
    end
  end

  ### Custom Throttle Response ###

  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is just fine.
  #
  # If you want to return 503 so that the attacker might be fooled into
  # believing that they've successfully broken your app (or you just want to
  # customize the response), then uncomment these lines.
  # self.throttled_response = lambda do |env|
  #  [ 503,  # status
  #    {},   # headers
  #    ['']] # body
  # end
end