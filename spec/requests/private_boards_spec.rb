require 'rails_helper'

# Private boards (#414): a board for signed-in people only, and one for moderators and admins
RSpec.describe 'Private boards', type: :request do
  let!(:public_board) { FactoryBot.create(:board, name: 'Public ideas') }
  let!(:members_board) { FactoryBot.create(:board, name: 'Members only', visibility: 'signed_in') }
  let!(:staff_board) { FactoryBot.create(:board, name: 'Internal', visibility: 'staff') }
  let!(:status) { FactoryBot.create(:post_status, show_in_roadmap: true) }
  let!(:public_post) { FactoryBot.create(:post, board: public_board, title: 'Public post', post_status: status) }
  let!(:members_post) { FactoryBot.create(:post, board: members_board, title: 'Members post', post_status: status) }
  let!(:staff_post) { FactoryBot.create(:post, board: staff_board, title: 'Internal post', post_status: status) }
  let(:user) { FactoryBot.create(:user).tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }

  def board_names
    get '/api/app/v1/boards'
    response.parsed_body.map { |board| board['name'] }
  end

  def roadmap_titles
    get '/api/app/v1/roadmap'
    response.parsed_body['columns'].flat_map { |column| column['posts'].map { |post| post['title'] } }
  end

  it 'shows visitors only public boards and posts' do
    expect(board_names).to eq(['Public ideas'])
    expect(roadmap_titles).to eq(['Public post'])

    get "/api/app/v1/boards/#{members_board.slug}"
    expect(response).to have_http_status(:not_found)
    get "/api/app/v1/boards/#{staff_board.slug}/posts"
    expect(response).to have_http_status(:not_found)
    get "/api/app/v1/posts/#{members_post.slug}"
    expect(response).to have_http_status(:not_found)
    get "/api/app/v1/posts/#{staff_post.slug}/comments"
    expect(response).to have_http_status(:not_found)
  end

  it 'shows signed-in people the members board, not the internal one' do
    sign_in user

    expect(board_names).to contain_exactly('Public ideas', 'Members only')
    expect(roadmap_titles).to contain_exactly('Public post', 'Members post')
    get "/api/app/v1/posts/#{staff_post.slug}"
    expect(response).to have_http_status(:not_found)
    post "/api/app/v1/posts/#{staff_post.slug}/vote"
    expect(response).to have_http_status(:not_found)
    post "/api/app/v1/boards/#{staff_board.slug}/posts", params: { title: 'Sneaky post', formFillMs: 5000 }, as: :json
    expect(response).to have_http_status(:not_found)

    get "/api/app/v1/posts/#{members_post.slug}"
    expect(response).to have_http_status(:ok)
  end

  it 'shows moderators everything' do
    sign_in moderator

    expect(board_names).to contain_exactly('Public ideas', 'Members only', 'Internal')
    get "/api/app/v1/posts/#{staff_post.slug}"
    expect(response).to have_http_status(:ok)
  end

  it 'keeps private posts out of feeds, sitemap, page titles and "My feedback"' do
    get "/boards/#{members_board.slug}/feed"
    expect(response).to have_http_status(:not_found)

    get '/sitemap.xml'
    expect(response.body).to include("/posts/#{public_post.slug}")
    expect(response.body).not_to include(members_post.slug, staff_post.slug, members_board.slug)

    get "/posts/#{staff_post.slug}"
    expect(response.body).not_to include('Internal post')

    staff_post.likes.create!(user: user)
    sign_in user
    get '/api/app/v1/my_posts', params: { filter: 'voted' }
    expect(response.parsed_body['posts']).to be_empty
  end

  it 'leaves private posts out of changelog entries for people who cannot see them' do
    entry = ChangelogEntry.create!(title: 'Release', published_at: 1.hour.ago)
    [public_post, staff_post].each { |p| entry.changelog_entry_posts.create!(post: p) }

    get '/api/app/v1/changelog_entries'
    expect(response.parsed_body['entries'].first['posts'].map { |p| p['title'] }).to eq(['Public post'])
  end

  it 'leaves private posts out of the recap and stops follower mails' do
    Follow.create!(user: user, post: staff_post)
    digest = RecapDigest.new(user: user, from: 1.day.ago, to: 1.minute.from_now)
    expect(digest.new_posts.map(&:title)).to contain_exactly('Public post', 'Members post')

    expect do
      ExecutePostStatusChangeLogicWorkflow.new(user_id: moderator.id, post: staff_post, post_status_id: status.id).notify_followers
    end.not_to have_enqueued_mail(UserMailer, :notify_follower_of_post_status_change)
  end

  it 'lets admins set the visibility and refuses unknown values' do
    sign_in FactoryBot.create(:admin).tap(&:confirm)

    patch "/api/app/v1/boards/#{public_board.id}", params: { visibility: 'staff' }, as: :json
    expect(response.parsed_body['visibility']).to eq('staff')

    patch "/api/app/v1/boards/#{public_board.id}", params: { visibility: 'secret' }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
  end
end
