require 'swagger_helper'

RSpec.describe 'api/app/v1 votes, follows, comments', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:user) { FactoryBot.create(:user).tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let!(:post_record) { FactoryBot.create(:post) }
  let(:post_id) { post_record.slug }

  path '/api/app/v1/posts/{post_id}/vote' do
    parameter name: :post_id, in: :path, type: :string, description: 'Post id or slug'

    post('Vote for a post') do
      tags 'Interactions'
      produces 'application/json'

      response(200, 'voted (idempotent)') do
        schema '$ref' => '#/components/schemas/VoteState'
        before do
          sign_in user
          FactoryBot.create(:like, post: post_record, user: user) # voting twice keeps one vote
        end

        run_test! do |response|
          expect(JSON.parse(response.body)).to eq('liked' => true, 'likesCount' => 1)
        end
      end

      response(401, 'not signed in') do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response(404, 'post pending approval') do
        schema '$ref' => '#/components/schemas/Error'
        let(:post_id) { FactoryBot.create(:post, approval_status: 'pending').id }
        before { sign_in user }

        run_test!
      end
    end

    delete('Remove vote') do
      tags 'Interactions'
      produces 'application/json'

      response(200, 'vote removed') do
        schema '$ref' => '#/components/schemas/VoteState'
        before do
          sign_in user
          FactoryBot.create(:like, post: post_record, user: user)
        end

        run_test! { |response| expect(JSON.parse(response.body)).to eq('liked' => false, 'likesCount' => 0) }
      end
    end
  end

  path '/api/app/v1/posts/{post_id}/follow' do
    parameter name: :post_id, in: :path, type: :string, description: 'Post id or slug'

    post('Follow a post') do
      tags 'Interactions'
      produces 'application/json'

      response(200, 'following') do
        schema '$ref' => '#/components/schemas/FollowState'
        before { sign_in user }

        run_test! do
          Current.tenant = Tenant.first # reset after the request
          expect(Follow.where(post: post_record, user: user).count).to eq(1)
        end
      end
    end

    delete('Unfollow a post') do
      tags 'Interactions'
      produces 'application/json'

      response(200, 'not following') do
        schema '$ref' => '#/components/schemas/FollowState'
        before do
          sign_in user
          FactoryBot.create(:follow, post: post_record, user: user)
        end

        run_test! do
          Current.tenant = Tenant.first
          expect(Follow.where(post: post_record, user: user)).to be_empty
        end
      end
    end
  end

  path '/api/app/v1/posts/{post_id}/comments' do
    parameter name: :post_id, in: :path, type: :string, description: 'Post id or slug'

    post('Comment on a post') do
      tags 'Interactions'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :new_comment, in: :body, schema: { '$ref' => '#/components/schemas/NewComment' }

      response(201, 'reply; isPostUpdate is ignored for regular users') do
        schema '$ref' => '#/components/schemas/Comment'
        let(:parent) { FactoryBot.create(:comment, post: post_record) }
        let(:new_comment) { { body: 'Me too', parentId: parent.id, isPostUpdate: true } }
        before { sign_in user }

        run_test! do |response|
          expect(JSON.parse(response.body)).to include('parentId' => parent.id, 'isPostUpdate' => false)
        end
      end

      response(201, 'post update by a moderator') do
        schema '$ref' => '#/components/schemas/Comment'
        let(:new_comment) { { body: 'Shipped!', isPostUpdate: true } }
        before { sign_in moderator }

        run_test! { |response| expect(JSON.parse(response.body)['isPostUpdate']).to be(true) }
      end

      response(404, 'parent comment belongs to another post') do
        schema '$ref' => '#/components/schemas/Error'
        let(:new_comment) { { body: 'Hi', parentId: FactoryBot.create(:comment).id } }
        before { sign_in user }

        run_test!
      end

      response(422, 'empty body') do
        schema '$ref' => '#/components/schemas/Error'
        let(:new_comment) { { body: '' } }
        before { sign_in user }

        run_test!
      end

      response(401, 'not signed in') do
        schema '$ref' => '#/components/schemas/Error'
        let(:new_comment) { { body: 'Hi' } }

        run_test!
      end
    end
  end
end
