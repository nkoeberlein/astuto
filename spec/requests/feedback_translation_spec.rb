require 'rails_helper'

RSpec.describe 'AI translation of feedback', type: :request do
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:ai_client) { instance_double(Ai::Client, enabled?: true, provider: 'ollama', model: 'test-model') }
  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Ai::Client).to receive(:from_env).and_return(ai_client)
    allow(ai_client).to receive(:translate_feedback) { |text:, target_locale:| "[#{target_locale}] #{text}" }
    allow(Rails).to receive(:cache).and_return(memory_cache)
    sign_in moderator
  end

  it 'caches by content, so repeated clicks cost nothing and edits are translated again' do
    post_record = FactoryBot.create(:post, title: 'Dunkler Modus', description: nil)

    2.times { post "/api/app/v1/posts/#{post_record.id}/translation" }
    expect(ai_client).to have_received(:translate_feedback).once
    expect(response.parsed_body['description']).to be_nil

    post_record.update!(title: 'Dunkles Design')
    post "/api/app/v1/posts/#{post_record.id}/translation"
    expect(ai_client).to have_received(:translate_feedback).twice
    expect(response.parsed_body['title']).to eq('[en] Dunkles Design')
  end

  it 'translates into the language of the feedback space' do
    Current.tenant.update!(locale: 'de')
    post_record = FactoryBot.create(:post, title: 'Dark mode')

    post "/api/app/v1/posts/#{post_record.id}/translation"

    expect(response.parsed_body).to include('title' => '[de] Dark mode', 'locale' => 'de')
  end

  it 'hides pending posts from people who may not see them' do
    post_record = FactoryBot.create(:post, approval_status: 'pending')
    sign_out moderator
    sign_in FactoryBot.create(:user).tap(&:confirm)

    post "/api/app/v1/posts/#{post_record.id}/translation"

    expect(response).to have_http_status(:not_found)
    expect(ai_client).not_to have_received(:translate_feedback)
  end

  it 'reports an empty answer from the provider as an error and does not cache it' do
    post_record = FactoryBot.create(:post, title: 'Dunkler Modus')
    allow(ai_client).to receive(:translate_feedback).and_return('')

    post "/api/app/v1/posts/#{post_record.id}/translation"
    expect(response).to have_http_status(:bad_gateway)

    allow(ai_client).to receive(:translate_feedback).and_return('Dark mode')
    post "/api/app/v1/posts/#{post_record.id}/translation"
    expect(response.parsed_body['title']).to eq('Dark mode')
  end
end
