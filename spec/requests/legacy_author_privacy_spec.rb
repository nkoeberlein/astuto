require 'rails_helper'

# The legacy UI's JSON endpoints must not hand out other people's email
# addresses. Moderators and the person themselves still see them.
RSpec.describe 'legacy JSON endpoints: author emails', type: :request do
  let(:author) { FactoryBot.create(:user).tap(&:confirm) }
  let(:voter) { FactoryBot.create(:user).tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:visitor) { FactoryBot.create(:user).tap(&:confirm) }
  let!(:post_record) { FactoryBot.create(:post, user: author) }

  before do
    FactoryBot.create(:comment, post: post_record, user: author)
    FactoryBot.create(:like, post: post_record, user: voter)
    FactoryBot.create(:post_status_change, post: post_record, user: moderator)
  end

  def fetch_all
    get post_comments_path(post_record.id), as: :json
    comments = JSON.parse(response.body)
    get post_likes_path(post_record.id), as: :json
    likes = JSON.parse(response.body)
    get post_post_status_changes_path(post_record.id), as: :json
    changes = JSON.parse(response.body)
    { comments: comments, likes: likes, changes: changes }
  end

  def all_bodies
    [post_comments_path(post_record.id), post_likes_path(post_record.id), post_post_status_changes_path(post_record.id)]
      .map { |path| get(path, as: :json) && response.body }
      .join
  end

  it 'gives anonymous visitors Gravatar hashes but no emails' do
    data = fetch_all

    expect(all_bodies).not_to include(author.email, voter.email, moderator.email)
    expect(data[:comments].first['user_gravatar_hash']).to eq(User.gravatar_hash(author.email))
    expect(data[:likes].first['gravatar_hash']).to eq(User.gravatar_hash(voter.email))
    expect(data[:changes].first['user_gravatar_hash']).to eq(User.gravatar_hash(moderator.email))
  end

  it 'hides other people\'s emails from signed-in users' do
    sign_in visitor

    expect(all_bodies).not_to include(author.email, voter.email, moderator.email)
  end

  it 'shows people their own email (used by the legacy UI for ownership checks)' do
    sign_in author
    data = fetch_all

    expect(data[:comments].first['user_email']).to eq(author.email)
    expect(data[:likes].first['email']).to be_nil
  end

  it 'shows moderators all emails' do
    sign_in moderator
    data = fetch_all

    expect(data[:comments].first['user_email']).to eq(author.email)
    expect(data[:likes].first['email']).to eq(voter.email)
    expect(data[:changes].first['user_email']).to eq(moderator.email)
  end

end
