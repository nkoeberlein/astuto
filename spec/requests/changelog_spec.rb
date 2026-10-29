require 'rails_helper'

RSpec.describe 'Changelog', type: :request do
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let!(:done_post) { FactoryBot.create(:post, title: 'Dark mode') }
  let!(:entry) do
    ChangelogEntry.create!(title: 'October release', body: 'Now with **dark mode**', published_at: 1.day.ago).tap do |e|
      e.changelog_entry_posts.create!(post: done_post)
    end
  end

  it 'shows drafts to moderators first, then the published entries' do
    ChangelogEntry.create!(title: 'Next release')
    sign_in moderator

    get '/api/app/v1/changelog_entries'

    expect(response.parsed_body['entries'].map { |e| e['title'] }).to eq(['Next release', 'October release'])
  end

  it 'hides entries planned for later' do
    ChangelogEntry.create!(title: 'Future release', published_at: 1.day.from_now)

    get '/api/app/v1/changelog_entries'

    expect(response.parsed_body['entries'].map { |e| e['title'] }).to eq(['October release'])
  end

  it 'links the post page to its changelog entries' do
    get "/api/app/v1/posts/#{done_post.slug}"

    expect(response.parsed_body['changelogEntries']).to eq([{ 'id' => entry.id, 'title' => 'October release' }])
  end

  it 'tells the frontend whether there is a changelog' do
    get '/api/app/v1/session'
    expect(response.parsed_body.dig('tenant', 'hasChangelog')).to be(true)

    entry.update!(published_at: nil)
    get '/api/app/v1/session'
    expect(response.parsed_body.dig('tenant', 'hasChangelog')).to be(false)
  end

  it 'has an RSS feed with one item per published entry' do
    ChangelogEntry.create!(title: 'Draft')

    get '/changelog/feed'

    items = Nokogiri::XML(response.body).xpath('//item')
    expect(items.map { |item| item.at_xpath('title').text }).to eq(['October release'])
    expect(items.first.at_xpath('link').text).to eq("http://www.example.com/changelog#entry-#{entry.id}")
    expect(items.first.at_xpath('description').text).to eq('Now with **dark mode**')
  end

  it 'is listed in the sitemap and announced on the page' do
    get '/sitemap.xml'
    expect(response.body).to include('<loc>http://www.example.com/changelog</loc>')

    get '/changelog'
    expect(response.body).to include('<link rel="alternate" type="application/rss+xml" title="Changelog" href="/changelog/feed" />')
  end

  it 'keeps the link when the post is merged into another one' do
    target = FactoryBot.create(:post, title: 'Dark theme')
    MergePostsWorkflow.new(source: done_post, target: target, actor: moderator).run!

    expect(entry.reload.posts).to eq([target])
  end
end
