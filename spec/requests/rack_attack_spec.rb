# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rack::Attack rate limiting and anti-spam', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:board) { FactoryBot.create(:board) }
  let(:user) { FactoryBot.create(:user).tap(&:confirm) }

  around do |example|
    previous_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    # Throttle windows start at multiples of their period (20 s, 1 min, 5 min). Frozen time
    # just after the start of a 5-minute window keeps every request of an example in one
    # window; otherwise a run across a boundary resets the counter and the limit never hits.
    window_start = (Time.now.to_i / 300 + 1) * 300
    travel_to(Time.zone.at(window_start + 1)) { example.run }
  ensure
    Rack::Attack.cache.store = previous_store
  end

  describe 'App API post creation anti-spam (POST /api/app/v1/boards/:board_id/posts)' do
    before { sign_in user }

    it 'flags an IP for 1 hour after a honeypot hit and blocks subsequent valid posts with 429' do
      # 1. Spam request (honeypot filled) -> rejected with 422 and flags the IP
      post "/api/app/v1/boards/#{board.slug}/posts",
           params: {
             title: 'Spam post',
             description: 'Buy cheap watches',
             honeypot: 'https://spam.example',
             formFillMs: 10_000
           }.to_json,
           headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => '198.51.100.10' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Rack::Attack.cache.store.read('post-submit-antispam-198.51.100.10')).to be(true)

      # 2. Subsequent valid request from the same IP on the App API -> blocked with 429
      post "/api/app/v1/boards/#{board.slug}/posts",
           params: {
             title: 'Looks legitimate now',
             description: 'Valid payload from flagged IP',
             honeypot: '',
             formFillMs: 10_000
           }.to_json,
           headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => '198.51.100.10' }

      expect(response).to have_http_status(:too_many_requests)

      # 3. Subsequent valid request from the same IP on legacy /posts -> also blocked with 429
      post '/posts',
           params: {
             post: {
               title: 'Legacy endpoint attempt',
               board_id: board.id,
               dnf1: '',
               dnf2: '',
               form_rendered_at: 10.seconds.ago.to_i
             }
           },
           headers: { 'REMOTE_ADDR' => '198.51.100.10' }

      expect(response).to have_http_status(:too_many_requests)

      # 4. Different IP is unaffected
      post "/api/app/v1/boards/#{board.slug}/posts",
           params: {
             title: 'Clean IP post',
             description: 'From another client',
             honeypot: '',
             formFillMs: 10_000
           }.to_json,
           headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => '198.51.100.11' }

      expect(response).to have_http_status(:created)
    end

    it 'rejects a too-fast form with 422 but does not flag the IP' do
      post "/api/app/v1/boards/#{board.slug}/posts",
           params: {
             title: 'Quick typist',
             description: 'Sent within a second',
             honeypot: '',
             formFillMs: 500
           }.to_json,
           headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => '198.51.100.20' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Rack::Attack.cache.store.read('post-submit-antispam-198.51.100.20')).to be_nil

      post "/api/app/v1/boards/#{board.slug}/posts",
           params: {
             title: 'Second try after waiting',
             description: 'Goes through',
             honeypot: '',
             formFillMs: 10_000
           }.to_json,
           headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => '198.51.100.20' }

      expect(response).to have_http_status(:created)
    end
  end

  describe 'login and auth brute-force protection' do
    it 'throttles Devise form logins by nested user[email] across different IPs' do
      5.times do |i|
        post '/users/sign_in',
             params: { user: { email: '  Victim@Example.com ', password: 'wrong' } },
             headers: { 'REMOTE_ADDR' => "203.0.113.#{10 + i}" }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      post '/users/sign_in',
           params: { user: { email: 'victim@example.com', password: 'wrong' } },
           headers: { 'REMOTE_ADDR' => '203.0.113.99' }

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'throttles App API JSON logins (/api/app/v1/session) by IP and by email' do
      5.times do
        post '/api/app/v1/session',
             params: { email: user.email, password: 'wrong' }.to_json,
             headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => '203.0.113.50' }
        expect(response).to have_http_status(:unauthorized)
      end

      post '/api/app/v1/session',
           params: { email: user.email, password: 'wrong' }.to_json,
           headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => '203.0.113.50' }

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'does not fail on malformed user params' do
      post '/users/sign_in', params: 'user=x', headers: { 'REMOTE_ADDR' => '203.0.113.40' }
      expect(response.status).to be < 500

      post '/api/app/v1/session',
           params: { user: 'x' }.to_json,
           headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => '203.0.113.41' }
      expect(response.status).to be < 500
    end

    it 'throttles App API registration and password reset endpoints by IP' do
      5.times do |i|
        post '/api/app/v1/password',
             params: { email: "user#{i}@example.com" }.to_json,
             headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => '203.0.113.60' }
        expect(response).to have_http_status(:ok)
      end

      post '/api/app/v1/password',
           params: { email: 'another@example.com' }.to_json,
           headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => '203.0.113.60' }

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'MCP and API v1 rate limiting and token hashing' do
    it 'hashes API tokens with SHA-256 instead of storing raw tokens in cache keys' do
      raw_token = 'tkn_mod_secret_token_value'
      env = Rack::MockRequest.env_for('/api/v1/posts', 'HTTP_AUTHORIZATION' => "Bearer #{raw_token}")
      req = Rack::Attack::Request.new(env)

      digest = Rack::Attack.extract_api_token_digest(req)
      expect(digest).to eq(Digest::SHA256.hexdigest(raw_token))
      expect(digest).not_to include(raw_token)
    end

    it 'reads Rails token headers and X-Api-Key like the MCP endpoint' do
      token_env = Rack::MockRequest.env_for('/mcp', 'HTTP_AUTHORIZATION' => 'Token token="abc"')
      key_env = Rack::MockRequest.env_for('/mcp', 'HTTP_X_API_KEY' => 'abc')

      expect(Rack::Attack.extract_api_token_digest(Rack::Attack::Request.new(token_env))).to eq(Digest::SHA256.hexdigest('abc'))
      expect(Rack::Attack.extract_api_token_digest(Rack::Attack::Request.new(key_env))).to eq(Digest::SHA256.hexdigest('abc'))
    end

    it 'throttles brute-force requests against /mcp by IP after 60 requests per minute' do
      60.times do |i|
        post '/mcp',
             params: { jsonrpc: '2.0', id: i, method: 'ping' }.to_json,
             headers: {
               'Authorization' => "Bearer invalid_guess_#{i}",
               'Content-Type' => 'application/json',
               'REMOTE_ADDR' => '192.0.2.77'
             }
        expect(response).to have_http_status(:unauthorized)
      end

      post '/mcp',
           params: { jsonrpc: '2.0', id: 61, method: 'ping' }.to_json,
           headers: {
             'Authorization' => 'Bearer invalid_guess_61',
             'Content-Type' => 'application/json',
             'REMOTE_ADDR' => '192.0.2.77'
           }

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
