require 'swagger_helper'

RSpec.describe 'api/app/v1/boards', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let!(:board) { FactoryBot.create(:board) }

  path '/api/app/v1/boards' do
    get('List boards') do
      tags 'Boards'
      produces 'application/json'

      response(200, 'successful') do
        schema type: :array, items: { '$ref' => '#/components/schemas/Board' }

        run_test! do |response|
          expect(JSON.parse(response.body).map { |b| b['slug'] }).to eq([board.slug])
        end
      end

      response(401, 'private feedback space, not signed in') do
        schema '$ref' => '#/components/schemas/Error'
        before { Current.tenant.tenant_setting.update!(is_private: true) }

        run_test!
      end
    end
  end

  path '/api/app/v1/boards/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Board id or slug'

    get('Show board') do
      tags 'Boards'
      produces 'application/json'

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/Board'
        let(:id) { board.slug }

        run_test!
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 'missing' }

        run_test!
      end
    end
  end

  path '/api/app/v1/post_statuses' do
    parameter name: :board_id, in: :query, type: :string, required: false,
              description: 'Optional board id or slug to filter out unused statuses when hideUnusedStatusesInFilterByStatus is enabled'

    get('List post statuses') do
      tags 'Boards'
      produces 'application/json'

      response(200, 'successful') do
        schema type: :array, items: { '$ref' => '#/components/schemas/PostStatus' }
        before { FactoryBot.create(:post_status) }

        run_test!
      end

      response(200, 'hides unused statuses for a board when setting is enabled') do
        schema type: :array, items: { '$ref' => '#/components/schemas/PostStatus' }
        let(:used_status) { FactoryBot.create(:post_status, name: 'Planned', order: 1) }
        let!(:unused_status) { FactoryBot.create(:post_status, name: 'Archived', order: 2) }
        let(:board_id) { board.slug }

        before do
          Current.tenant.tenant_setting.update!(hide_unused_statuses_in_filter_by_status: true)
          FactoryBot.create(:post, board: board, post_status: used_status, approval_status: 'approved')
        end

        run_test! do |response|
          ids = JSON.parse(response.body).map { |s| s['id'] }
          expect(ids).to eq([used_status.id])
        end
      end
    end
  end
end
