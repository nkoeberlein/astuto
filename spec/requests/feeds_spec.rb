require 'rails_helper'

RSpec.describe 'RSS feeds', type: :request do
  let!(:board) { FactoryBot.create(:board, name: 'Feature Requests', description: 'Ideas & wishes') }
  let(:status) { FactoryBot.create(:post_status, name: 'Planned') }

  def items
    Nokogiri::XML(response.body).xpath('//item')
  end

  it 'lists the newest approved posts of the board' do
    FactoryBot.create(:post, board: board, title: 'Older post', created_at: 2.days.ago)
    newest = FactoryBot.create(:post, board: board, title: 'Dark <mode>', description: 'Please **add** it', post_status: status)
    FactoryBot.create(:post, board: board, title: 'Pending post', approval_status: 'pending')
    FactoryBot.create(:post, title: 'Other board')

    get "/boards/#{board.slug}/feed"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('application/rss+xml')
    doc = Nokogiri::XML(response.body)
    expect(doc.at_xpath('//channel/title').text).to end_with('Feature Requests · ' + Current.tenant.site_name)
    expect(doc.at_xpath('//channel/description').text).to eq('Ideas & wishes')
    expect(items.map { |item| item.at_xpath('title').text }).to eq(['Dark <mode>', 'Older post'])
    expect(items.first.at_xpath('link').text).to eq("http://www.example.com/posts/#{newest.slug}")
    expect(items.first.at_xpath('category').text).to eq('Planned')
    expect(items.first.at_xpath('description').text).to eq('Please **add** it')
    expect(response.headers['Cache-Control']).to include('public')
  end

  it 'has no feeds in a private feedback space' do
    Current.tenant.tenant_setting.update!(is_private: true)

    get "/boards/#{board.slug}/feed"

    expect(response).to have_http_status(:not_found)
  end

  it 'answers unknown boards with 404' do
    get '/boards/no-such-board/feed'

    expect(response).to have_http_status(:not_found)
  end

  it 'is announced on the board page' do
    get "/boards/#{board.slug}"

    expect(response.body).to include(%(<link rel="alternate" type="application/rss+xml" title="Feature Requests" href="/boards/#{board.slug}/feed" />))
  end
end
