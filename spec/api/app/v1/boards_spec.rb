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
    get('List post statuses') do
      tags 'Boards'
      produces 'application/json'

      response(200, 'successful') do
        schema type: :array, items: { '$ref' => '#/components/schemas/PostStatus' }
        before { FactoryBot.create(:post_status) }

        run_test!
      end
    end
  end
end
