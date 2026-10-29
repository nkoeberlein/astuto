require 'swagger_helper'

RSpec.describe 'api/app/v1 boards and statuses (site settings)', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:admin) { FactoryBot.create(:admin).tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let!(:ideas) { FactoryBot.create(:board, name: 'Ideas') }
  let!(:bugs) { FactoryBot.create(:board, name: 'Bugs') }
  let!(:planned) { FactoryBot.create(:post_status, name: 'Planned') }
  let!(:done) { FactoryBot.create(:post_status, name: 'Done') }

  path '/api/app/v1/boards' do
    post('Create a board (admins)') do
      tags 'Boards'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :board, in: :body, schema: { '$ref' => '#/components/schemas/BoardInput' }

      response(201, 'created at the end, slug from the name') do
        schema '$ref' => '#/components/schemas/Board'
        let(:board) { { name: 'Mobile App', description: 'iOS and Android' } }
        before { sign_in admin }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('name' => 'Mobile App', 'slug' => 'mobile-app')
          expect(Board.find(body['id']).order).to be > [ideas.order, bugs.order].max
        end
      end

      response(422, 'duplicate name') do
        schema '$ref' => '#/components/schemas/Error'
        let(:board) { { name: 'Ideas' } }
        before { sign_in admin }

        run_test!
      end

      response(403, 'moderators cannot create boards') do
        schema '$ref' => '#/components/schemas/Error'
        let(:board) { { name: 'Sneaky' } }
        before { sign_in moderator }

        run_test! { expect(Board.where(name: 'Sneaky')).to be_empty }
      end
    end
  end

  path '/api/app/v1/boards/{id}' do
    parameter name: :id, in: :path, type: :integer

    patch('Update a board (admins)') do
      tags 'Boards'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :board, in: :body, schema: { '$ref' => '#/components/schemas/BoardInput' }

      response(200, 'renamed with a custom slug') do
        schema '$ref' => '#/components/schemas/Board'
        let(:id) { ideas.id }
        let(:board) { { name: 'Feature Ideas', slug: 'Feature Ideas!' } }
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body)).to include('name' => 'Feature Ideas', 'slug' => 'feature-ideas')
        end
      end
    end

    delete('Delete a board and its posts (admins)') do
      tags 'Boards'

      response(204, 'deleted, the other boards move up') do
        let(:id) { ideas.id }
        before do
          FactoryBot.create(:post, board: ideas)
          sign_in admin
        end

        run_test! do
          expect(Board.exists?(ideas.id)).to be(false)
          expect(Post.where(board_id: ideas.id)).to be_empty
          expect(bugs.reload.order).to eq(0)
        end
      end

      response(403, 'moderators cannot delete boards') do
        let(:id) { ideas.id }
        before { sign_in moderator }

        run_test! { expect(Board.exists?(ideas.id)).to be(true) }
      end
    end
  end

  path '/api/app/v1/boards/reorder' do
    put('Reorder boards (admins)') do
      tags 'Boards'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :reorder, in: :body, schema: { '$ref' => '#/components/schemas/Reorder' }

      response(200, 'boards in the new order') do
        schema type: :array, items: { '$ref' => '#/components/schemas/Board' }
        let(:reorder) { { ids: [bugs.id, ideas.id] } }
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body).map { |b| b['id'] }).to eq([bugs.id, ideas.id])
        end
      end

      response(422, 'ids missing a board') do
        schema '$ref' => '#/components/schemas/Error'
        let(:reorder) { { ids: [bugs.id] } }
        before { sign_in admin }

        run_test! { expect(ideas.reload.order).to eq(ideas.order) }
      end
    end
  end

  path '/api/app/v1/post_statuses' do
    post('Create a status (admins)') do
      tags 'Post Statuses'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :post_status, in: :body, schema: { '$ref' => '#/components/schemas/PostStatusInput' }

      response(201, 'created') do
        schema '$ref' => '#/components/schemas/PostStatus'
        let(:post_status) { { name: 'Rejected', color: '#cc0000', showInRoadmap: false } }
        before { sign_in admin }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('name' => 'Rejected', 'color' => '#cc0000', 'showInRoadmap' => false)
          expect(body['order']).to be > [planned.order, done.order].max
        end
      end

      response(422, 'invalid color') do
        schema '$ref' => '#/components/schemas/Error'
        let(:post_status) { { name: 'Odd', color: 'red' } }
        before { sign_in admin }

        run_test!
      end
    end
  end

  path '/api/app/v1/post_statuses/{id}' do
    parameter name: :id, in: :path, type: :integer

    patch('Update a status (admins)') do
      tags 'Post Statuses'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :post_status, in: :body, schema: { '$ref' => '#/components/schemas/PostStatusInput' }

      response(200, 'updated') do
        schema '$ref' => '#/components/schemas/PostStatus'
        let(:id) { planned.id }
        let(:post_status) { { color: '#00aa00', showInRoadmap: false } }
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body)).to include('name' => 'Planned', 'color' => '#00aa00', 'showInRoadmap' => false)
        end
      end
    end

    delete('Delete a status (admins); its posts keep existing without one') do
      tags 'Post Statuses'

      response(204, 'deleted') do
        let(:id) { planned.id }
        let!(:post_record) { FactoryBot.create(:post, post_status: planned) }
        before { sign_in admin }

        run_test! do
          expect(post_record.reload.post_status_id).to be_nil
          expect(done.reload.order).to eq(0)
        end
      end
    end
  end

  path '/api/app/v1/post_statuses/reorder' do
    put('Reorder statuses (admins)') do
      tags 'Post Statuses'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :reorder, in: :body, schema: { '$ref' => '#/components/schemas/Reorder' }

      response(200, 'statuses in the new order') do
        schema type: :array, items: { '$ref' => '#/components/schemas/PostStatus' }
        let(:reorder) { { ids: [done.id, planned.id] } }
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body).map { |s| [s['id'], s['order']] }).to eq([[done.id, 0], [planned.id, 1]])
        end
      end

      response(422, 'duplicate ids') do
        schema '$ref' => '#/components/schemas/Error'
        let(:reorder) { { ids: [done.id, done.id] } }
        before { sign_in admin }

        run_test!
      end
    end
  end
end
