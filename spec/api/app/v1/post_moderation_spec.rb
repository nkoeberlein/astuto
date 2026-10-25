require 'swagger_helper'

RSpec.describe 'api/app/v1 post & comment editing and moderation', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let!(:board) { FactoryBot.create(:board) }
  let!(:other_board) { FactoryBot.create(:board, name: 'Bug Reports') }
  let!(:status) { FactoryBot.create(:post_status, name: 'In Progress') }
  let(:author) { FactoryBot.create(:user).tap(&:confirm) }
  let(:other_user) { FactoryBot.create(:user).tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let!(:post_record) { FactoryBot.create(:post, board: board, user: author, post_status: nil, title: 'Original title', description: 'Original description') }

  path '/api/app/v1/posts/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Post id or slug'

    patch('Update post (author or moderator)') do
      tags 'Posts'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :update_post, in: :body, schema: { '$ref' => '#/components/schemas/UpdatePost' }

      response(200, 'author updates title and description; moderation fields are ignored') do
        schema '$ref' => '#/components/schemas/Post'
        let(:id) { post_record.slug }
        let(:update_post) { { title: 'Updated title', description: 'Updated description', postStatusId: status.id } }
        before { sign_in author }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('title' => 'Updated title', 'description' => 'Updated description', 'postStatusId' => nil)
        end
      end

      response(200, 'moderator changes status, board, and approval status') do
        schema '$ref' => '#/components/schemas/Post'
        let(:id) { post_record.slug }
        let(:update_post) { { boardId: other_board.id, postStatusId: status.id, approvalStatus: 'approved' } }
        before { sign_in moderator }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('boardId' => other_board.id, 'postStatusId' => status.id)
          Current.tenant = Tenant.first
          expect(PostStatusChange.where(post_id: post_record.id, post_status_id: status.id).count).to eq(1)
        end
      end

      response(422, 'unknown approval status') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { post_record.slug }
        let(:update_post) { { approvalStatus: 'published' } }
        before { sign_in moderator }

        run_test!
      end

      response(403, 'forbidden for another non-moderator user') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { post_record.slug }
        let(:update_post) { { title: 'Hijacked title' } }
        before { sign_in other_user }

        run_test!
      end

      response(401, 'not signed in') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { post_record.slug }
        let(:update_post) { { title: 'Hijacked title' } }

        run_test!
      end
    end

    delete('Delete post (author or moderator)') do
      tags 'Posts'

      response(204, 'deleted by author') do
        let(:id) { post_record.slug }
        before { sign_in author }

        run_test! do
          Current.tenant = Tenant.first
          expect(Post.exists?(post_record.id)).to be(false)
        end
      end

      response(403, 'forbidden for another user') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { post_record.slug }
        before { sign_in other_user }

        run_test!
      end
    end
  end

  path '/api/app/v1/posts/{post_id}/comments/{id}' do
    parameter name: :post_id, in: :path, type: :string, description: 'Post id or slug'
    parameter name: :id, in: :path, type: :integer, description: 'Comment id'

    let!(:comment_record) { FactoryBot.create(:comment, post: post_record, user: author, body: 'Initial comment') }
    let(:post_id) { post_record.slug }
    let(:id) { comment_record.id }

    patch('Update comment (author or moderator)') do
      tags 'Interactions'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :update_comment, in: :body, schema: { '$ref' => '#/components/schemas/UpdateComment' }

      response(200, 'author updates comment body') do
        schema '$ref' => '#/components/schemas/Comment'
        let(:update_comment) { { body: 'Edited comment', isPostUpdate: true } }
        before { sign_in author }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('body' => 'Edited comment', 'isPostUpdate' => false)
        end
      end

      response(200, 'moderator marks comment as post update') do
        schema '$ref' => '#/components/schemas/Comment'
        let(:update_comment) { { body: 'Official update', isPostUpdate: true } }
        before { sign_in moderator }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('body' => 'Official update', 'isPostUpdate' => true)
        end
      end

      response(403, 'forbidden for another user') do
        schema '$ref' => '#/components/schemas/Error'
        let(:update_comment) { { body: 'Nope' } }
        before { sign_in other_user }

        run_test!
      end
    end

    delete('Delete comment (author or moderator)') do
      tags 'Interactions'

      response(204, 'deleted by author') do
        before { sign_in author }

        run_test! do
          Current.tenant = Tenant.first
          expect(Comment.exists?(comment_record.id)).to be(false)
        end
      end

      response(403, 'forbidden for another user') do
        schema '$ref' => '#/components/schemas/Error'
        before { sign_in other_user }

        run_test!
      end
    end
  end
end
