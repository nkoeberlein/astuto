require 'rails_helper'

# Forgery protection is off in the test environment; this spec turns it on to
# check the real flow of the v2 frontend: token from GET /session, sent back as X-CSRF-Token.
RSpec.describe 'App API CSRF protection', type: :request do
  around do |example|
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  let(:user) { FactoryBot.create(:user).tap(&:confirm) }
  let!(:post_record) { FactoryBot.create(:post) }

  before { sign_in user }

  it 'accepts a write request with the token from the session endpoint' do
    get '/api/app/v1/session'
    token = JSON.parse(response.body)['csrfToken']

    post "/api/app/v1/posts/#{post_record.slug}/vote", headers: { 'X-CSRF-Token' => token }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['liked']).to be(true)
  end

  it 'rejects a write request without token' do
    post "/api/app/v1/posts/#{post_record.slug}/vote"

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)['error']).to match(/CSRF/)
    Current.tenant = Tenant.first # reset after the request
    expect(post_record.likes.count).to eq(0)
  end

  it 'rejects a forged token' do
    post "/api/app/v1/posts/#{post_record.slug}/vote", headers: { 'X-CSRF-Token' => 'forged' }

    expect(response).to have_http_status(:unprocessable_content)
  end
end
