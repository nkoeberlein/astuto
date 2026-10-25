# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreatePostWorkflow do
  let(:author) { FactoryBot.create(:user) }
  let(:moderator) { FactoryBot.create(:moderator) }
  let(:board) { FactoryBot.create(:board) }
  let(:post_status) { FactoryBot.create(:post_status) }

  def build_post(**attrs)
    Post.new(board: board, title: 'Dark mode please', user: author, **attrs)
  end

  it 'saves the post and lets the follower follow it' do
    post = build_post

    expect(described_class.new(post: post, follower: author).run).to be(true)
    expect(post).to be_persisted
    expect(post.followers).to eq([author])
    expect(PostStatusChange.count).to eq(0)
  end

  it 'records an initial status in the timeline' do
    post = build_post(post_status: post_status)

    described_class.new(post: post, follower: author, status_actor: moderator).run!

    change = PostStatusChange.last
    expect(change.post_id).to eq(post.id)
    expect(change.post_status_id).to eq(post_status.id)
    expect(change.user_id).to eq(moderator.id)
  end

  it 'returns false and keeps validation errors on an invalid post' do
    post = build_post(title: 'x')

    expect(described_class.new(post: post, follower: author).run).to be(false)
    expect(post.errors[:title]).to be_present
    expect(Follow.count).to eq(0)
  end

  it 'rolls back the post when the follow cannot be saved (#169)' do
    failing_follow = Follow.new
    failing_follow.errors.add(:base, 'follow failed')
    allow(Follow).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordInvalid.new(failing_follow))

    post = build_post

    expect { expect(described_class.new(post: post, follower: author).run).to be(false) }
      .not_to change(Post, :count)
    expect(post.errors[:base]).to include('follow failed')
  end
end
