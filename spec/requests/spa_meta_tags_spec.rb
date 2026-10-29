require 'rails_helper'

RSpec.describe 'SpaController server-side meta tags', type: :request do
  let!(:board) { FactoryBot.create(:board, name: 'Feature Requests', description: 'Submit **great** ideas here') }
  let!(:post_record) do
    FactoryBot.create(
      :post,
      board: board,
      title: 'Add MCP Server Support',
      description: 'Allow AI agents to query feedback via **Model Context Protocol**.',
      approval_status: 'approved'
    )
  end

  before do
    Current.tenant.update!(site_name: 'Acme Feedback', site_favicon: 'https://acme.example/favicon.png')
  end

  it 'injects board title, Open Graph tags, and custom favicon for /next/boards/:slug' do
    get "/next/boards/#{board.slug}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<title>Feature Requests · Acme Feedback</title>')
    expect(response.body).to include('<meta property="og:title" content="Feature Requests · Acme Feedback" />')
    expect(response.body).to include('<meta name="description" content="Submit great ideas here" />')
    expect(response.body).to include('<link rel="icon" href="https://acme.example/favicon.png" />')
  end

  it 'injects post title and plain-text description excerpt for /next/posts/:slug' do
    get "/next/posts/#{post_record.slug}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<title>Add MCP Server Support · Acme Feedback</title>')
    expect(response.body).to include('<meta property="og:description" content="Allow AI agents to query feedback via Model Context Protocol." />')
  end

  it 'sets the language and writing direction of the page' do
    Current.tenant.update!(locale: 'de')

    get '/next/roadmap'

    expect(response.body).to include('<html lang="de" dir="ltr">')
  end

  it 'keeps backslash sequences in titles literal' do
    post_record.update!(title: 'Escape \0 and \1 in paths')

    get "/next/posts/#{post_record.slug}"

    expect(response.body).to include('<title>Escape \0 and \1 in paths · Acme Feedback</title>')
    expect(response.body.scan('<title>').size).to eq(1)
  end

  it 'does not leak post titles in meta tags when the feedback space is private' do
    Current.tenant.tenant_setting.update!(is_private: true)

    get "/next/posts/#{post_record.slug}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<title>Acme Feedback</title>')
    expect(response.body).not_to include('Add MCP Server Support')
  end
end
