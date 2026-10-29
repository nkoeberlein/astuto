require 'rails_helper'

RSpec.describe 'Embeddable widget', type: :request do
  let!(:config) { WidgetConfig.create!(enabled: true) }
  let(:board) { FactoryBot.create(:board) }
  let!(:post_record) { FactoryBot.create(:post, board: board) }

  def visitor_token(claims = {})
    WidgetToken.encode({ 'email' => 'visitor@example.com', 'name' => 'Vera Visitor', 'exp' => 1.hour.from_now.to_i }.merge(claims), config.secret)
  end

  def access_token(claims = {})
    post '/api/app/v1/widget/session', params: { token: visitor_token(claims) }, as: :json
    expect(response).to have_http_status(:ok)
    response.parsed_body['accessToken']
  end

  def bearer(token)
    { 'Authorization' => "Bearer #{token}" }
  end

  around do |example|
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  it 'signs visitors in with a bearer token that works without cookies or CSRF token' do
    token = access_token
    reset!

    get '/api/app/v1/session', headers: bearer(token)
    expect(response.parsed_body.dig('user', 'email')).to eq('visitor@example.com')

    post "/api/app/v1/posts/#{post_record.slug}/vote", headers: bearer(token)
    expect(response).to have_http_status(:ok)
    expect(post_record.likes.sole.user.email).to eq('visitor@example.com')
  end

  it 'refuses writes with an invalid bearer token and never falls back to the cookie session' do
    user = FactoryBot.create(:user).tap(&:confirm)
    sign_in user

    get '/api/app/v1/session', headers: bearer('forged')
    expect(response.parsed_body['user']).to be_nil

    post "/api/app/v1/posts/#{post_record.slug}/vote", headers: bearer('forged')
    expect(response).to have_http_status(:unprocessable_content).or have_http_status(:forbidden)
    expect(post_record.likes).to be_empty
  end

  it 'stops accepting the access token when the account becomes staff' do
    token = access_token
    User.find_by(email: 'visitor@example.com').update!(role: 'moderator')

    get '/api/app/v1/session', headers: bearer(token)
    expect(response.parsed_body['user']).to be_nil
  end

  it 'answers wrong visitor tokens with 401 and refuses staff with 403' do
    post '/api/app/v1/widget/session', params: { token: 'nope' }, as: :json
    expect(response).to have_http_status(:unauthorized)

    FactoryBot.create(:admin, email: 'boss@example.com')
    post '/api/app/v1/widget/session', params: { token: visitor_token('email' => 'boss@example.com') }, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'is off until turned on' do
    config.update!(enabled: false)

    post '/api/app/v1/widget/session', params: { token: visitor_token }, as: :json
    expect(response).to have_http_status(:not_found)

    get '/embed'
    expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
  end

  it 'lets other sites frame /embed, only the allowed origins when set' do
    get '/embed'
    expect(response.headers['X-Frame-Options']).to be_nil

    config.update!(allowed_origins: "https://app.example.com\nhttps://www.example.org/")
    get '/embed'
    expect(response.headers['X-Frame-Options']).to be_nil
    expect(response.headers['Content-Security-Policy']).to include('frame-ancestors https://app.example.com https://www.example.org')
  end
end
