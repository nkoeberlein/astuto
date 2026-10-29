require 'swagger_helper'

RSpec.describe 'api/app/v1 AI translation', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let!(:post_record) { FactoryBot.create(:post, title: 'Dunkler Modus', description: 'Bitte ein dunkles Design') }
  let!(:comment) { FactoryBot.create(:comment, post: post_record, body: 'Ja, nachts tun die Augen weh') }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:user) { FactoryBot.create(:user).tap(&:confirm) }
  let(:ai_client) { instance_double(Ai::Client, enabled?: true, provider: 'ollama', model: 'test-model') }

  before do
    allow(Ai::Client).to receive(:from_env).and_return(ai_client)
    allow(ai_client).to receive(:translate_feedback) { |text:, target_locale:| "[#{target_locale}] #{text}" }
  end

  path '/api/app/v1/posts/{post_id}/translation' do
    parameter name: :post_id, in: :path, type: :string, description: 'Post id or slug'

    post('AI translation of a post into the interface language (moderators, needs AI_PROVIDER and AI_MODEL)') do
      tags 'Posts'
      produces 'application/json'

      response(200, 'translated title and description') do
        schema '$ref' => '#/components/schemas/PostTranslation'
        let(:post_id) { post_record.slug }
        before { sign_in moderator }

        run_test! do |response|
          expect(JSON.parse(response.body)).to eq(
            'title' => '[en] Dunkler Modus', 'description' => '[en] Bitte ein dunkles Design', 'locale' => 'en'
          )
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

        run_test! { expect(ai_client).not_to have_received(:translate_feedback) }
      end

      response(502, 'AI provider failed') do
        schema '$ref' => '#/components/schemas/Error'
        let(:post_id) { post_record.slug }
        before do
          sign_in moderator
          allow(ai_client).to receive(:translate_feedback).and_raise(Ai::Client::ProviderError, 'HTTP 500')
        end

        run_test!
      end
    end
  end

  path '/api/app/v1/posts/{post_id}/comments/{comment_id}/translation' do
    parameter name: :post_id, in: :path, type: :string, description: 'Post id or slug'
    parameter name: :comment_id, in: :path, type: :integer

    post('AI translation of a comment into the interface language (moderators, needs AI_PROVIDER and AI_MODEL)') do
      tags 'Comments'
      produces 'application/json'

      response(200, 'translated comment') do
        schema '$ref' => '#/components/schemas/CommentTranslation'
        let(:post_id) { post_record.slug }
        let(:comment_id) { comment.id }
        before { sign_in moderator }

        run_test! do |response|
          expect(JSON.parse(response.body)).to eq('body' => '[en] Ja, nachts tun die Augen weh', 'locale' => 'en')
        end
      end

      response(404, 'comment of another post') do
        schema '$ref' => '#/components/schemas/Error'
        let(:post_id) { post_record.slug }
        let(:comment_id) { FactoryBot.create(:comment).id }
        before { sign_in moderator }

        run_test!
      end

      response(401, 'not signed in') do
        schema '$ref' => '#/components/schemas/Error'
        let(:post_id) { post_record.slug }
        let(:comment_id) { comment.id }

        run_test!
      end
    end
  end
end
