require 'rails_helper'

RSpec.describe 'robots.txt and sitemap.xml', type: :request do
  let!(:board) { FactoryBot.create(:board, name: 'Feature Requests') }
  let!(:approved) { FactoryBot.create(:post, board: board, title: 'Dark mode', updated_at: Time.utc(2026, 10, 1)) }
  let!(:pending) { FactoryBot.create(:post, board: board, title: 'Pending post', approval_status: 'pending') }

  def locations
    Nokogiri::XML(response.body).remove_namespaces!.xpath('//url/loc').map(&:text)
  end

  it 'lists home, roadmap, boards and approved posts' do
    get '/sitemap.xml'

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('application/xml')
    expect(locations).to eq([
      'http://www.example.com/', 'http://www.example.com/roadmap',
      "http://www.example.com/boards/#{board.slug}", "http://www.example.com/posts/#{approved.slug}"
    ])
    lastmods = Nokogiri::XML(response.body).remove_namespaces!.xpath('//url/lastmod').map(&:text)
    expect(lastmods).to all(eq('2026-10-01T00:00:00Z'))
  end

  it 'leaves out a switched-off roadmap' do
    Current.tenant.tenant_setting.update!(roadmap_enabled: false)
    get '/sitemap.xml'

    expect(locations).not_to include('http://www.example.com/roadmap')
  end

  it 'names the sitemap in robots.txt and keeps crawlers out of account pages' do
    get '/robots.txt'

    expect(response.media_type).to eq('text/plain')
    expect(response.body).to include("Sitemap: http://www.example.com/sitemap.xml\n", "Disallow: /site_settings/\n", "Disallow: /api/\n")
  end

  it 'keeps crawlers out of private feedback spaces' do
    Current.tenant.tenant_setting.update!(is_private: true)

    get '/robots.txt'
    expect(response.body).to eq("User-agent: *\nDisallow: /\n")

    get '/sitemap.xml'
    expect(response).to have_http_status(:not_found)
  end
end
