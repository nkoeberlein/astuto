require 'rails_helper'

RSpec.describe RecapDigest do
  let(:user) { FactoryBot.create(:user) }
  let(:moderator) { FactoryBot.create(:moderator) }
  let(:from) { 1.day.ago }
  let(:to) { Time.current }

  def digest(for_user = user)
    described_class.new(user: for_user, from: from, to: to)
  end

  it 'lists new approved posts by others, also anonymous ones' do
    FactoryBot.create(:post, title: 'By someone', created_at: 2.hours.ago)
    FactoryBot.create(:post, title: 'Anonymous', user: nil, created_at: 1.hour.ago)
    FactoryBot.create(:post, title: 'Own post', user: user)
    FactoryBot.create(:post, title: 'Pending', approval_status: 'pending')
    FactoryBot.create(:post, title: 'Too old', created_at: 2.days.ago)

    expect(digest.new_posts.map(&:title)).to eq(['Anonymous', 'By someone'])
    expect(digest.new_posts_count).to eq(2)
  end

  it 'ranks posts by the votes cast in the period' do
    popular = FactoryBot.create(:post, title: 'Popular', created_at: 1.month.ago)
    other = FactoryBot.create(:post, title: 'Other post')
    3.times { FactoryBot.create(:like, post: popular) }
    FactoryBot.create(:like, post: other)
    FactoryBot.create(:like, post: other, created_at: 2.days.ago)

    expect(digest.top_posts.map { |post| [post.title, post.period_votes] }).to eq([['Popular', 3], ['Other post', 1]])
  end

  it 'reports the latest status change of followed posts made by others' do
    followed = FactoryBot.create(:post, title: 'Followed')
    Follow.create!(user: user, post: followed)
    planned = FactoryBot.create(:post_status, name: 'Planned')
    done = FactoryBot.create(:post_status, name: 'Done')
    PostStatusChange.create!(post: followed, user: moderator, post_status: planned, created_at: 3.hours.ago)
    PostStatusChange.create!(post: followed, user: moderator, post_status: done, created_at: 1.hour.ago)
    PostStatusChange.create!(post: FactoryBot.create(:post), user: moderator, post_status: done)

    expect(digest.status_changes.map { |change| [change.post.title, change.post_status.name] }).to eq([['Followed', 'Done']])
  end

  it 'counts pending feedback for moderators only' do
    FactoryBot.create(:post, approval_status: 'pending')

    expect(digest(moderator).pending_posts_count).to eq(1)
    expect(digest.pending_posts_count).to be_nil
    expect(digest(moderator)).to be_any
    expect(digest).not_to be_any
  end
end
