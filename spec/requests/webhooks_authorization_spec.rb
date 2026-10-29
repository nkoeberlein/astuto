require 'rails_helper'

# The legacy webhook preview and test endpoints used to skip authorization
RSpec.describe 'webhook preview and test authorization', type: :request do
  let(:webhook) { FactoryBot.create(:webhook, http_body: '{"title": "{{ post.title | escape_json }}"}') }
  let(:preview_params) { { webhook: { trigger: 'new_post', url: 'https://example.com', http_body: '{}' } } }

  before { allow(RunWebhook).to receive(:perform_now).and_return('ok') }

  it 'keeps anonymous visitors out' do
    put "/webhooks/#{webhook.id}/test", as: :json
    expect(response).to have_http_status(:unauthorized)

    put '/webhooks_preview', params: preview_params, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(RunWebhook).not_to have_received(:perform_now)
  end

  it 'keeps moderators out' do
    sign_in FactoryBot.create(:moderator).tap(&:confirm)

    put "/webhooks/#{webhook.id}/test", as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(RunWebhook).not_to have_received(:perform_now)
  end

  it 'lets admins test and preview' do
    sign_in FactoryBot.create(:admin).tap(&:confirm)

    put "/webhooks/#{webhook.id}/test", as: :json
    expect(response).to have_http_status(:ok)
    expect(RunWebhook).to have_received(:perform_now)

    put '/webhooks_preview', params: preview_params, as: :json
    expect(response).to have_http_status(:ok)
  end
end
