require 'rails_helper'

RSpec.describe 'posts controller', type: :request do
  let (:user) { FactoryBot.create(:user) }

  let(:board1) { FactoryBot.create(:board) }
  let(:board2) { FactoryBot.create(:board) }

  let(:post1) { FactoryBot.create(:post, board: board1) }
  let(:post2) { FactoryBot.create(:post, board: board1) }
  let(:post3) { FactoryBot.create(:post, board: board2) }

  def create_posts
    post1
    post2
    post3
  end

  describe 'index' do
    before(:each) { create_posts }

    it 'returns posts of first board (if no board id provided) as JSON' do
      get posts_path
      json1 = JSON.parse(response.body)

      get posts_path(board_id: Board.first.id)
      json2 = JSON.parse(response.body)

      expect(json1).to eq(json2)
    end

    it 'returns posts filtered by board id as JSON' do
      get posts_path(board_id: post1.board_id)

      json = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      expect(json.length).to eq(2)
    end

    it 'returns posts filtered by post status id as JSON' do
      get posts_path(board_id: post1.board_id, post_status_ids: [post1.post_status_id])

      json = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      expect(json.length).to eq(1)
    end
  end

  describe 'create' do
    before(:each) do
      user.confirm
      sign_in user
    end

    it 'creates a new post' do
      post_count = Post.count

      new_post = FactoryBot.build(:post, board: board1)

      post(
        posts_path,
        params: {
          post: {
            title: new_post.title,
            description: new_post.description,
            board_id: new_post.board_id,
            dnf1: '',
            dnf2: '',
            form_rendered_at: 1.minute.ago.to_i
          }
        }
      )

      expect(response).to have_http_status(:success)
      expect(Post.count).to eq(post_count + 1)
      expect(Post.last.followers).to eq([user])
    end

    it 'rejects a non-anonymous post if not logged in' do
      sign_out user

      post_count = Post.count

      new_post = FactoryBot.build(:post, board: board1)

      post(
        posts_path,
        params: {
          post: {
            title: new_post.title,
            description: new_post.description,
            board_id: new_post.board_id,
            dnf1: '',
            dnf2: '',
            form_rendered_at: 1.minute.ago.to_i
          }
        }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(Post.count).to eq(post_count)
    end

    it 'rejects a post whose honeypot field is filled' do
      new_post = FactoryBot.build(:post, board: board1)

      expect do
        post(
          posts_path,
          params: {
            post: {
              title: new_post.title,
              board_id: new_post.board_id,
              dnf1: 'bot',
              dnf2: '',
              form_rendered_at: 1.minute.ago.to_i
            }
          }
        )
      end.not_to change(Post, :count)
      expect(response).not_to have_http_status(:success)
    end
  end
end