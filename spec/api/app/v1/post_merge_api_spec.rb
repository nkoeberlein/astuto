require 'swagger_helper'

# OpenAPI documentation of merging; behaviour in spec/requests/post_merge_spec.rb
RSpec.describe 'api/app/v1/posts merge', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:target) { FactoryBot.create(:post, title: 'Dark mode') }
  let(:duplicate) { FactoryBot.create(:post, title: 'Night theme please') }

  path '/api/app/v1/posts/{id}/merge' do
    parameter name: :id, in: :path, type: :string, description: 'Slug or id of the duplicate'

    post('Merge a duplicate into another post (moderators); not reversible') do
      tags 'Posts'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :merge_input, in: :body, schema: { '$ref' => '#/components/schemas/MergePostInput' }

      response(200, 'merged; the target with its new votes and comments') do
        schema '$ref' => '#/components/schemas/Post'
        let(:id) { duplicate.slug }
        let(:merge_input) { { targetId: target.id } }
        before { sign_in moderator }

        run_test!
      end

      response(422, 'same or already merged post') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { target.slug }
        let(:merge_input) { { targetId: target.id } }
        before { sign_in moderator }

        run_test!
      end
    end
  end
end
