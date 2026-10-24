# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MCP Streamable HTTP (/mcp)', type: :request do
  let(:tenant) { Tenant.first || FactoryBot.create(:tenant) }
  let(:moderator) do
    Current.tenant = tenant
    FactoryBot.create(:moderator, tenant: tenant)
  end
  let(:api_key) do
    Current.tenant = tenant
    ApiKey.create!(user: moderator, tenant: tenant)
  end
  let(:auth_headers) do
    {
      'Authorization' => "Bearer #{api_key.token}",
      'Content-Type' => 'application/json'
    }
  end

  before do
    Current.tenant = tenant
  end

  describe 'authentication' do
    it 'rejects unauthenticated requests with 401 and WWW-Authenticate header' do
      post '/mcp',
           params: { jsonrpc: '2.0', id: 1, method: 'ping' }.to_json,
           headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['WWW-Authenticate']).to include('Bearer')
      body = JSON.parse(response.body)
      expect(body['jsonrpc']).to eq('2.0')
      expect(body.dig('error', 'code')).to eq(-32_001)
    end

    it 'accepts authentication via X-Api-Key header as well as Authorization Bearer' do
      post '/mcp',
           params: { jsonrpc: '2.0', id: 1, method: 'ping' }.to_json,
           headers: { 'X-Api-Key' => api_key.token, 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['result']).to eq({})
    end
  end

  describe 'protocol lifecycle' do
    it 'handles initialize and negotiates protocol version' do
      post '/mcp',
           params: {
             jsonrpc: '2.0',
             id: 1,
             method: 'initialize',
             params: {
               protocolVersion: '2025-03-26',
               capabilities: {},
               clientInfo: { name: 'claude-code', version: '1.0' }
             }
           }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['id']).to eq(1)
      expect(body.dig('result', 'protocolVersion')).to eq('2025-03-26')
      expect(body.dig('result', 'serverInfo', 'name')).to eq('astuto-evolution-mcp')
      expect(body.dig('result', 'capabilities', 'tools')).to be_a(Hash)
    end

    it 'returns 202 Accepted with empty body for notifications/initialized' do
      post '/mcp',
           params: { jsonrpc: '2.0', method: 'notifications/initialized' }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:accepted)
      expect(response.body).to be_empty
    end

    it 'returns 405 on GET /mcp and 204 on DELETE /mcp' do
      get '/mcp', headers: auth_headers
      expect(response).to have_http_status(:method_not_allowed)

      delete '/mcp', headers: auth_headers
      expect(response).to have_http_status(:no_content)
    end

    it 'lists all 8 feedback tools via tools/list' do
      post '/mcp',
           params: { jsonrpc: '2.0', id: 2, method: 'tools/list' }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:ok)
      tools = JSON.parse(response.body).dig('result', 'tools')
      tool_names = tools.map { |t| t['name'] }
      expect(tool_names).to contain_exactly(
        'list_boards',
        'search_posts',
        'top_requests',
        'get_post',
        'get_roadmap',
        'create_post',
        'update_post_status',
        'add_comment'
      )
    end
  end

  describe 'tools/call' do
    let!(:board) { FactoryBot.create(:board, tenant: tenant, name: 'Feature Requests') }
    let!(:roadmap_status) do
      FactoryBot.create(:post_status, tenant: tenant, name: 'Planned', show_in_roadmap: true, order: 1)
    end
    let!(:existing_post) do
      FactoryBot.create(
        :post,
        tenant: tenant,
        board: board,
        post_status: roadmap_status,
        title: 'Dark mode support for dashboard',
        description: 'Please add a dark theme option to reduce eye strain.',
        approval_status: 'approved'
      )
    end

    def call_tool(name, arguments = {})
      post '/mcp',
           params: {
             jsonrpc: '2.0',
             id: 10,
             method: 'tools/call',
             params: { name: name, arguments: arguments }
           }.to_json,
           headers: auth_headers
      expect(response).to have_http_status(:ok)
      JSON.parse(response.body)['result']
    end

    it 'lists boards with approved post counts (list_boards)' do
      result = call_tool('list_boards')
      expect(result['isError']).to eq(false)
      boards = result.dig('structuredContent', 'boards')
      target = boards.find { |b| b['id'] == board.id }
      expect(target['name']).to eq('Feature Requests')
      expect(target['approved_posts_count']).to eq(1)
    end

    it 'searches posts by query (search_posts)' do
      result = call_tool('search_posts', { query: 'dark theme', board_id: board.id })
      expect(result['isError']).to eq(false)
      posts = result.dig('structuredContent', 'posts')
      expect(posts.map { |p| p['id'] }).to include(existing_post.id)
    end

    it 'fetches top requests (top_requests)' do
      FactoryBot.create(:like, tenant: tenant, post: existing_post)
      result = call_tool('top_requests', { sort_by: 'most_voted', board_id: board.id, limit: 5 })
      expect(result['isError']).to eq(false)
      posts = result.dig('structuredContent', 'posts')
      expect(posts.first['id']).to eq(existing_post.id)
      expect(posts.first['likes_count']).to eq(1)
    end

    it 'fetches roadmap columns and posts (get_roadmap)' do
      result = call_tool('get_roadmap')
      expect(result['isError']).to eq(false)
      columns = result.dig('structuredContent', 'roadmap')
      planned_col = columns.find { |c| c['id'] == roadmap_status.id }
      expect(planned_col['name']).to eq('Planned')
      expect(planned_col['posts'].map { |p| p['id'] }).to include(existing_post.id)
    end

    it 'creates a post, updates its status, adds a comment, and retrieves full post details' do
      created = call_tool('create_post', {
        board_id: board.id,
        title: 'SSO SAML login integration',
        description: 'Enterprise customers need SAML 2.0.'
      })
      expect(created['isError']).to eq(false)
      new_post_id = created.dig('structuredContent', 'post', 'id')
      expect(new_post_id).to be_present

      updated = call_tool('update_post_status', {
        post_id: new_post_id,
        post_status_id: roadmap_status.id
      })
      expect(updated['isError']).to eq(false)
      expect(updated.dig('structuredContent', 'post', 'post_status_id')).to eq(roadmap_status.id)

      commented = call_tool('add_comment', {
        post_id: new_post_id,
        body: 'We are scheduling this for Q2.',
        is_post_update: true
      })
      expect(commented['isError']).to eq(false)
      comment_id = commented.dig('structuredContent', 'comment', 'id')

      detail = call_tool('get_post', { id: new_post_id })
      expect(detail['isError']).to eq(false)
      post_data = detail.dig('structuredContent', 'post')
      expect(post_data['title']).to eq('SSO SAML login integration')
      expect(post_data.dig('post_status', 'id')).to eq(roadmap_status.id)
      expect(post_data['comments'].map { |c| c['id'] }).to include(comment_id)
    end
  end
end
