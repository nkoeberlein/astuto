require 'swagger_helper'

RSpec.describe 'api/app/v1/roadmap', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let!(:planned) { FactoryBot.create(:post_status, name: 'Planned', order: 1) }
  let!(:done) { FactoryBot.create(:post_status, name: 'Done', order: 2) }
  let!(:hidden) { FactoryBot.create(:post_status, name: 'Hidden', show_in_roadmap: false) }
  let!(:popular) { FactoryBot.create(:post, post_status: planned, updated_at: 3.days.ago) }
  let!(:fresh) { FactoryBot.create(:post, post_status: planned, updated_at: 1.hour.ago) }

  before do
    FactoryBot.create_list(:like, 2, post: popular)
    FactoryBot.create(:comment, post: fresh)
    FactoryBot.create(:post, post_status: planned, approval_status: 'pending')
    FactoryBot.create(:post, post_status: hidden)
  end

  path '/api/app/v1/roadmap' do
    parameter name: :sort_by, in: :query, type: :string, required: false, enum: %w[most_voted recently_updated]

    get('Roadmap columns with their approved posts') do
      tags 'Roadmap'
      produces 'application/json'

      response(200, 'successful, most voted first') do
        schema '$ref' => '#/components/schemas/Roadmap'

        run_test! do |response|
          columns = JSON.parse(response.body)['columns']
          expect(columns.map { |c| c['status']['name'] }).to eq(%w[Planned Done])
          expect(columns[0]['posts'].map { |p| p['id'] }).to eq([popular.id, fresh.id])
          expect(columns[0]['postsCount']).to eq(2)
          expect(columns[0]['posts'][0]).to include('likesCount' => 2, 'commentsCount' => 0, 'liked' => false)
          expect(columns[1]['posts']).to eq([])
        end
      end

      response(200, 'recently updated first') do
        schema '$ref' => '#/components/schemas/Roadmap'
        let(:sort_by) { 'recently_updated' }

        run_test! do |response|
          posts = JSON.parse(response.body)['columns'][0]['posts']
          expect(posts.map { |p| p['id'] }).to eq([fresh.id, popular.id])
          expect(posts[0]['commentsCount']).to eq(1)
        end
      end

      response(404, 'roadmap disabled') do
        schema '$ref' => '#/components/schemas/Error'
        before { Current.tenant.tenant_setting.update!(roadmap_enabled: false) }

        run_test!
      end

      response(401, 'private feedback space, not signed in') do
        schema '$ref' => '#/components/schemas/Error'
        before { Current.tenant.tenant_setting.update!(is_private: true) }

        run_test!
      end
    end
  end
end
