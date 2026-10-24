require 'rails_helper'

RSpec.describe 'roadmap pages', type: :request do
  let(:setting) { Current.tenant.tenant_setting }

  it 'renders the roadmap when enabled' do
    get '/roadmap'

    expect(response).to have_http_status(:ok)
  end

  it 'redirects to the root page when the roadmap is disabled (#361)' do
    setting.update!(roadmap_enabled: false)

    get '/roadmap'

    expect(response).to redirect_to(root_path)
  end

  it 'redirects the embedded roadmap to the root page when the roadmap is disabled' do
    setting.update!(roadmap_enabled: false)

    get '/embedded_roadmap'

    expect(response).to redirect_to(root_url)
  end
end