require 'rails_helper'

RSpec.describe MergePostsWorkflow do
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:board) { FactoryBot.create(:board) }
  let(:target) { FactoryBot.create(:post, board: board, title: 'Dark mode') }
  let(:duplicate) { FactoryBot.create(:post, board: board, title: 'Night theme please') }
  let(:ada) { FactoryBot.create(:user) }
  let(:bob) { FactoryBot.create(:user) }

  def merge(source = duplicate, into = target)
    described_class.new(source: source, target: into, actor: moderator).run!
  end

  it 'moves votes, followers and comments, keeping one per person' do
    FactoryBot.create(:like, post: target, user: ada)
    FactoryBot.create(:like, post: duplicate, user: ada)
    FactoryBot.create(:like, post: duplicate, user: bob)
    Follow.create!(post: duplicate, user: bob)
    FactoryBot.create(:comment, post: duplicate, user: bob, body: 'Me too')

    merge

    expect(target.likes.pluck(:user_id)).to contain_exactly(ada.id, bob.id)
    expect(target.follows.pluck(:user_id)).to include(bob.id)
    expect(target.comments.pluck(:body)).to include('Me too')
    expect(duplicate.reload).to have_attributes(approval_status: 'merged', merged_into: target)
    expect(Like.where(post: duplicate)).to be_empty
  end

  it 'refuses merging a post into itself or merged posts' do
    expect { merge(target, target) }.to raise_error(described_class::Error)
    merge
    other = FactoryBot.create(:post, board: board)
    expect { merge(other, duplicate) }.to raise_error(described_class::Error)
  end

  it 'redirects earlier merges to the new target' do
    older = FactoryBot.create(:post, board: board)
    merge(older, duplicate)
    merge(duplicate, target)
    expect(older.reload.merged_into).to eq(target)
  end

  it 'deletes merged shells together with the target' do
    merge
    target.destroy!
    expect(Post.exists?(duplicate.id)).to be(false)
  end
end
