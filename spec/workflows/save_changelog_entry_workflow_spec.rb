require 'rails_helper'

RSpec.describe SaveChangelogEntryWorkflow do
  let(:moderator) { FactoryBot.create(:moderator) }
  let(:post_a) { FactoryBot.create(:post, title: 'Dark mode') }
  let(:post_b) { FactoryBot.create(:post, title: 'Export') }
  let(:follower) { FactoryBot.create(:user, email: 'follower@example.com') }

  def save(entry = ChangelogEntry.new, **options)
    workflow = described_class.new(entry: entry, actor: moderator, attributes: options.delete(:attributes) || { title: 'Release 1' }, **options)
    [workflow.run, entry]
  end

  before do
    [post_a, post_b].each { |post| Follow.create!(user: follower, post: post) }
    Follow.create!(user: FactoryBot.create(:user, notifications_enabled: false), post: post_a)
    Follow.create!(user: moderator, post: post_a)
  end

  it 'links approved posts only and keeps drafts quiet' do
    pending_post = FactoryBot.create(:post, approval_status: 'pending')

    ok, entry = nil
    expect { ok, entry = save(post_ids: [post_a.id, pending_post.id], published: false) }
      .not_to have_enqueued_mail(UserMailer, :notify_follower_of_changelog_entry)

    expect(ok).to be(true)
    expect(entry.posts).to eq([post_a])
  end

  it 'emails each follower once on the first publication, not the publisher' do
    _, entry = save(post_ids: [post_a.id, post_b.id], published: false)

    expect { save(entry, attributes: {}, published: true) }
      .to have_enqueued_mail(UserMailer, :notify_follower_of_changelog_entry).once
    expect(entry.reload.followers_notified_at).to be_present

    save(entry, attributes: {}, published: false)
    expect { save(entry, attributes: {}, published: true) }
      .not_to have_enqueued_mail(UserMailer, :notify_follower_of_changelog_entry)
  end

  it 'replaces the linked posts' do
    _, entry = save(post_ids: [post_a.id])
    save(entry, attributes: {}, post_ids: [post_b.id])

    expect(entry.reload.posts).to eq([post_b])
  end

  it 'returns false with errors for invalid entries' do
    ok, entry = save(attributes: { title: '' }, post_ids: [post_a.id])

    expect(ok).to be(false)
    expect(entry.errors[:title]).to be_present
    expect(ChangelogEntryPost.count).to eq(0)
  end

  it 'mails the followed posts of the entry' do
    _, entry = save(post_ids: [post_a.id, post_b.id], published: true)
    mail = UserMailer.notify_follower_of_changelog_entry(user: follower, entry: entry)

    expect(mail.subject).to include('Release 1')
    expect(mail.body.encoded).to include('Dark mode', 'Export', "/changelog#entry-#{entry.id}")
  end
end
