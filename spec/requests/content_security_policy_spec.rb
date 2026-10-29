require 'rails_helper'

RSpec.describe 'Content Security Policy', type: :request do
  def csp
    response.headers['Content-Security-Policy'].to_s
  end

  def directive(name)
    csp.split(';').map(&:strip).find { |d| d.start_with?("#{name} ") }.to_s
  end

  it 'only allows scripts from this site or with the nonce' do
    get root_path

    expect(response).to have_http_status(:ok)
    script_src = directive('script-src')
    expect(script_src).to include("'self'", "'nonce-")
    expect(csp).not_to include('stripe')
    expect(script_src).not_to include("'unsafe-inline'", "'unsafe-eval'")
    expect(directive('object-src')).to eq("object-src 'none'")
  end

  it 'gives the inline locale script of the Rails pages the nonce from the header' do
    get new_user_confirmation_path

    nonce = directive('script-src')[/'nonce-([^']+)'/, 1]
    expect(nonce).to be_present
    expect(response.body).to match(/<script[^>]* nonce="#{Regexp.escape(nonce)}"/)
    expect(response.body).to include('data-turbolinks-eval="false"')
  end

  it 'uses a new nonce for every response' do
    get root_path
    first = directive('script-src')[/'nonce-([^']+)'/, 1]
    get root_path
    second = directive('script-src')[/'nonce-([^']+)'/, 1]

    expect(first).not_to eq(second)
  end

  it 'keeps inline styles allowed for custom CSS' do
    get root_path

    expect(directive('style-src')).to include("'unsafe-inline'")
    expect(directive('style-src')).not_to include("'nonce-")
  end

  it 'sends the policy for the v2 frontend, whose pages Rails renders itself' do
    skip 'v2 frontend not built' unless SpaController::INDEX.exist?

    %w[/ /roadmap].each do |path|
      get path
      expect(directive('script-src')).to include("'self'")
      expect(response.body).to include('og:site_name')
    end
  end

  it 'has no inline event handlers in the layout and the profile page' do
    user = FactoryBot.create(:moderator).tap(&:confirm)
    sign_in user

    [root_path, edit_user_registration_path].each do |path|
      get path
      expect(response.body).not_to match(/\son(click|load|submit|change)=/), path
    end
  end
end
