require 'rails_helper'

RSpec.describe 'Merging duplicate posts', type: :request do
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:board) { FactoryBot.create(:board) }
  let!(:target) { FactoryBot.create(:post, board: board, title: 'Dark mode') }
  let!(:duplicate) { FactoryBot.create(:post, board: board, title: 'Night theme please') }

  it 'lets moderators merge; the duplicate leaves the board and its link shows the target' do
    sign_in moderator
    post "/api/app/v1/posts/#{duplicate.slug}/merge", params: { targetId: target.id }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('slug' => target.slug, 'mergedPosts' => [{ 'title' => 'Night theme please' }])
    expect(AuditEvent.sole).to have_attributes(action: 'post.merge', subject_label: 'Night theme please → Dark mode')

    sign_out moderator
    get "/api/app/v1/boards/#{board.slug}/posts"
    expect(response.parsed_body['posts'].map { |p| p['slug'] }).to eq([target.slug])

    get "/api/app/v1/posts/#{duplicate.slug}"
    expect(response.parsed_body['slug']).to eq(target.slug)
  end

  it 'is for moderators only and refuses invalid targets' do
    sign_in FactoryBot.create(:user).tap(&:confirm)
    post "/api/app/v1/posts/#{duplicate.slug}/merge", params: { targetId: target.id }, as: :json
    expect(response).to have_http_status(:forbidden)

    sign_in moderator
    post "/api/app/v1/posts/#{duplicate.slug}/merge", params: { targetId: duplicate.id }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'works through MCP' do
    result = Mcp::Tools::MergePosts.run(user: moderator, duplicate_post_id: duplicate.id, target_post_id: target.id)
    expect(result[:merged]).to eq(duplicate_post_id: duplicate.id, target_post_id: target.id)
    expect(duplicate.reload).to be_merged
  end
end
