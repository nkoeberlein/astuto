require 'rails_helper'

RSpec.describe MyPostsQuery do
  let(:user) { FactoryBot.create(:user) }
  let(:other) { FactoryBot.create(:user) }

  def titles(filter, **options)
    described_class.new(user: user, filter: filter, **options).call.posts.map(&:title)
  end

  it 'lists own posts in every approval state, most recently updated first' do
    FactoryBot.create(:post, user: user, title: 'Oldest', updated_at: 2.days.ago)
    FactoryBot.create(:post, user: user, title: 'Pending', approval_status: 'pending', updated_at: 1.day.ago)
    FactoryBot.create(:post, user: user, title: 'Rejected', approval_status: 'rejected')
    FactoryBot.create(:post, user: other, title: 'Someone else')

    expect(titles('created')).to eq(%w[Rejected Pending Oldest])
  end

  it 'lists voted and followed posts only while everybody can see them' do
    visible = FactoryBot.create(:post, user: other, title: 'Visible')
    hidden = FactoryBot.create(:post, user: other, title: 'Hidden', approval_status: 'pending')
    [visible, hidden].each do |post|
      FactoryBot.create(:like, user: user, post: post)
      Follow.create!(user: user, post: post)
    end
    FactoryBot.create(:like, user: other, post: visible)

    expect(titles('voted')).to eq(['Visible'])
    expect(titles('followed')).to eq(['Visible'])
    expect(described_class.new(user: user, filter: 'voted').call.posts.first.likes_count).to eq(2)
  end

  it 'falls back to created for unknown filters and pages through the results' do
    3.times { |i| FactoryBot.create(:post, user: user, title: "Post #{i}", updated_at: i.days.ago) }

    first = described_class.new(user: user, filter: 'bogus', per_page: 2).call
    expect(first.posts.map(&:title)).to eq(['Post 0', 'Post 1'])
    expect(first.has_more).to be(true)
    expect(titles('created', page: 2, per_page: 2)).to eq(['Post 2'])
  end

  it 'counts each filter' do
    post = FactoryBot.create(:post, user: user)
    FactoryBot.create(:like, user: user, post: post)

    expect(described_class.new(user: user, filter: 'created').counts).to eq('created' => 1, 'voted' => 1, 'followed' => 0)
  end
end
