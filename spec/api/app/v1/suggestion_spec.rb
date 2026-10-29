require 'swagger_helper'

RSpec.describe 'api/app/v1 AI suggestion', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let!(:features) { FactoryBot.create(:board, name: 'Feature Requests') }
  let!(:bugs) { FactoryBot.create(:board, name: 'Bug Reports') }
  let!(:mobile) { Tag.create!(name: 'Mobile') }
  let!(:post_record) { FactoryBot.create(:post, board: features, title: 'App crashes on start') }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:ai_client) { instance_double(Ai::Client, enabled?: true, provider: 'ollama', model: 'test-model') }

  before { allow(Ai::Client).to receive(:from_env).and_return(ai_client) }

  path '/api/app/v1/posts/{post_id}/suggestion' do
    parameter name: :post_id, in: :path, type: :string, description: 'Post id or slug'

    post('AI suggestion of board and tags from the existing ones (moderators, needs AI_PROVIDER and AI_MODEL)') do
      tags 'Posts'
      produces 'application/json'

      response(200, 'suggestion; unknown names are dropped') do
        schema '$ref' => '#/components/schemas/Suggestion'
        let(:post_id) { post_record.slug }
        before do
          sign_in moderator
          allow(ai_client).to receive(:suggest_board_and_tags).and_return('board' => 'bug reports', 'tags' => ['mobile', 'Made up'])
        end

        run_test! do |response|
          expect(JSON.parse(response.body)).to eq('boardId' => bugs.id, 'tagIds' => [mobile.id])
          expect(ai_client).to have_received(:suggest_board_and_tags).with(
            title: 'App crashes on start', description: post_record.description, boards: [features, bugs].sort_by(&:order), tags: [mobile]
          )
        end
      end

      response(403, 'not a moderator') do
        schema '$ref' => '#/components/schemas/Error'
        let(:post_id) { post_record.slug }
        before { sign_in FactoryBot.create(:user).tap(&:confirm) }

        run_test!
      end
    end
  end
end
