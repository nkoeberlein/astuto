require 'swagger_helper'

RSpec.describe 'api/app/v1 my posts', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:user) { FactoryBot.create(:user).tap(&:confirm) }
  let!(:own_pending) { FactoryBot.create(:post, user: user, title: 'Dark mode', approval_status: 'pending') }
  let!(:voted) { FactoryBot.create(:post, title: 'Export to CSV') }

  before { FactoryBot.create(:like, user: user, post: voted) }

  path '/api/app/v1/my_posts' do
    get('Posts the signed-in person created, voted on or follows ("My feedback")') do
      tags 'Posts'
      produces 'application/json'
      parameter name: :filter, in: :query, required: false,
                schema: { type: :string, enum: MyPostsQuery::FILTERS, default: 'created' },
                description: 'created (also pending, rejected and merged own posts), voted or followed'
      parameter name: :page, in: :query, type: :integer, required: false

      response(200, 'posts, newest update first, with counts per filter') do
        schema '$ref' => '#/components/schemas/MyPostPage'
        let(:filter) { 'voted' }
        before { sign_in user }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['posts'].map { |p| p['title'] }).to eq(['Export to CSV'])
          expect(body['posts'].first).to include('liked' => true, 'likesCount' => 1, 'approvalStatus' => 'approved')
          expect(body['counts']).to eq('created' => 1, 'voted' => 1, 'followed' => 0)
        end
      end

      response(401, 'not signed in') do
        schema '$ref' => '#/components/schemas/Error'

        run_test!
      end
    end
  end
end
