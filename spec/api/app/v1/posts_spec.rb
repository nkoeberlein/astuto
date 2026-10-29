require 'swagger_helper'

RSpec.describe 'api/app/v1/posts', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let!(:board) { FactoryBot.create(:board) }
  let(:author) { FactoryBot.create(:user) }
  let!(:older) { FactoryBot.create(:post, board: board, user: author, created_at: 2.days.ago) }
  let!(:newer) { FactoryBot.create(:post, board: board, user: author, created_at: 1.day.ago) }

  path '/api/app/v1/boards/{board_id}/posts' do
    parameter name: :board_id, in: :path, type: :string, description: 'Board id or slug'
    parameter name: :sort_by, in: :query, type: :string, required: false, enum: %w[trending newest most_voted oldest]
    parameter name: :search, in: :query, type: :string, required: false
    parameter name: :page, in: :query, type: :integer, required: false
    parameter name: 'post_status_ids[]', in: :query, type: :array, items: { type: :integer }, required: false,
              description: 'Filter by status; 0 means posts without status'
    parameter name: 'tag_ids[]', in: :query, type: :array, items: { type: :integer }, required: false,
              description: 'Filter by tag: posts with any of these tags'

    get('List approved posts of a board') do
      tags 'Posts'
      produces 'application/json'
      let(:board_id) { board.slug }

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/PostPage'
        let(:sort_by) { 'newest' }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['posts'].map { |p| p['id'] }).to eq([newer.id, older.id])
          expect(body['hasMore']).to be(false)
        end
      end

      response(200, 'paginated, pending posts hidden, likes counted') do
        schema '$ref' => '#/components/schemas/PostPage'
        let(:sort_by) { 'oldest' }

        before do
          allow(Rails.application).to receive(:posts_per_page).and_return(1)
          FactoryBot.create(:post, board: board, approval_status: 'pending')
          FactoryBot.create(:like, post: older)
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['posts'].size).to eq(1)
          expect(body['posts'][0]).to include('id' => older.id, 'likesCount' => 1)
          expect(body['hasMore']).to be(true)
        end
      end

      response(200, 'search') do
        schema '$ref' => '#/components/schemas/PostPage'
        let(:search) { newer.title }

        run_test! do |response|
          expect(JSON.parse(response.body)['posts'].map { |p| p['id'] }).to eq([newer.id])
        end
      end
    end
  end

  path '/api/app/v1/posts/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Post id or slug'

    get('Show post') do
      tags 'Posts'
      produces 'application/json'

      response(200, 'successful, without author email') do
        schema '$ref' => '#/components/schemas/Post'
        let(:id) { newer.slug }

        run_test! do |response|
          expect(response.body).not_to include(author.email)
          expect(JSON.parse(response.body)['author']['fullName']).to eq(author.full_name)
        end
      end

      response(404, 'pending post for a regular visitor') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { FactoryBot.create(:post, board: board, approval_status: 'pending').id }

        run_test!
      end

      response(200, 'pending post for a moderator') do
        schema '$ref' => '#/components/schemas/Post'
        let(:id) { FactoryBot.create(:post, board: board, approval_status: 'pending').id }
        before { sign_in FactoryBot.create(:moderator).tap(&:confirm) }

        run_test!
      end
    end
  end

  path '/api/app/v1/posts/{post_id}/comments' do
    parameter name: :post_id, in: :path, type: :string, description: 'Post id or slug'

    get('List comments of a post') do
      tags 'Posts'
      produces 'application/json'

      response(200, 'successful') do
        schema type: :array, items: { '$ref' => '#/components/schemas/Comment' }
        let(:post_id) { newer.slug }
        let!(:comment) { FactoryBot.create(:comment, post: newer) }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.map { |c| c['id'] }).to eq([comment.id])
          expect(response.body).not_to include(comment.user.email)
        end
      end
    end
  end
end
