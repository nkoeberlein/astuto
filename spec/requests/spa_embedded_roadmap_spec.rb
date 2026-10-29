require 'rails_helper'

RSpec.describe 'SpaController embedded roadmap', type: :request do
  let(:setting) { Current.tenant.tenant_setting }

  it 'lets other sites frame the embedded roadmap' do
    get '/next/embedded_roadmap?show_boards=1&show_board_filter=false'

    expect(response).to have_http_status(:ok)
    expect(response.headers).not_to have_key('X-Frame-Options')
    expect(response.body).to include('<title>Roadmap · ')
  end

  it 'keeps the frame protection on all other pages' do
    get '/next/roadmap'

    expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
  end

  it 'keeps the frame protection when the roadmap is disabled' do
    setting.update!(roadmap_enabled: false)

    get '/next/embedded_roadmap'

    expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
  end
end
