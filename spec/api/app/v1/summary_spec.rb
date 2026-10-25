require 'swagger_helper'

RSpec.describe 'api/app/v1 AI summary', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let!(:post_record) { FactoryBot.create(:post, title: 'Dark mode', description: 'Please add a dark theme') }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:user) { FactoryBot.create(:user).tap(&:confirm) }
  let(:ai_client) { instance_double(Ai::Client, enabled?: true, provider: 'ollama', model: 'test-model') }

  before do
    FactoryBot.create(:comment, post: post_record, body: 'Yes, my eyes hurt at night')
    allow(Ai::Client).to receive(:from_env).and_return(ai_client)
  end

  path '/api/app/v1/posts/{post_id}/summary' do
    parameter name: :post_id, in: :path, type: :string, description: 'Post id or slug'

    post('AI summary of a post and its comments (moderators, needs AI_PROVIDER and AI_MODEL)') do
      tags 'Posts'
      produces 'application/json'

      response(200, 'summary') do
        schema '$ref' => '#/components/schemas/Summary'
        let(:post_id) { post_record.slug }
        before do
          sign_in moderator
          allow(ai_client).to receive(:summarize_discussion).and_return('- Users want a dark theme')
        end

        run_test! do |response|
          expect(JSON.parse(response.body)).to eq('summary' => '- Users want a dark theme')
          expect(ai_client).to have_received(:summarize_discussion).with(post: post_record, locale: I18n.locale)
        end
      end

      response(403, 'not a moderator') do
        schema '$ref' => '#/components/schemas/Error'
        let(:post_id) { post_record.slug }
        before { sign_in user }

        run_test!
      end

      response(404, 'AI is not configured') do
        schema '$ref' => '#/components/schemas/Error'
        let(:post_id) { post_record.slug }
        before do
          sign_in moderator
          allow(ai_client).to receive(:enabled?).and_return(false)
        end

        run_test!
      end

      response(502, 'AI provider failed') do
        schema '$ref' => '#/components/schemas/Error'
        let(:post_id) { post_record.slug }
        before do
          sign_in moderator
          allow(ai_client).to receive(:summarize_discussion).and_raise(Ai::Client::ProviderError, 'HTTP 500')
        end

        run_test!
      end
    end
  end
end
