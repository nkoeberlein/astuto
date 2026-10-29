require 'rails_helper'

# "Use browser language" applies to the v2 frontend too (session locale, page language)
RSpec.describe 'browser language', type: :request do
  let(:setting) { Current.tenant.tenant_setting }

  before { Current.tenant.update!(locale: 'en') }

  it 'is ignored unless switched on' do
    get '/api/app/v1/session', headers: { 'Accept-Language' => 'de-DE,de;q=0.9' }

    expect(JSON.parse(response.body)['tenant']['locale']).to eq('en')
  end

  it 'picks the first preferred language the app has' do
    setting.update!(use_browser_locale: true)

    get '/api/app/v1/session', headers: { 'Accept-Language' => 'xx-YY, de-AT;q=0.9, fr;q=0.8' }
    expect(JSON.parse(response.body)['tenant']['locale']).to eq('de')

    get '/api/app/v1/session', headers: { 'Accept-Language' => 'zh-TW' }
    expect(JSON.parse(response.body)['tenant']['locale']).to eq('zh-CN')

    get '/api/app/v1/session', headers: { 'Accept-Language' => 'xx' }
    expect(JSON.parse(response.body)['tenant']['locale']).to eq('en')
  end

  it 'sets the language of the server-rendered page' do
    skip 'v2 frontend not built' unless SpaController::INDEX.exist?
    setting.update!(use_browser_locale: true)

    get '/roadmap', headers: { 'Accept-Language' => 'nl' }

    expect(response.body).to include('<html lang="nl" dir="ltr">')
  end
end
