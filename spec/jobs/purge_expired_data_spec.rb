require 'rails_helper'

RSpec.describe PurgeExpiredData do
  it 'removes old unconfirmed sign-ups without content, old IPs and old invitations' do
    stale = FactoryBot.create(:user, confirmed_at: nil)
    stale.update_columns(created_at: 40.days.ago)
    with_post = FactoryBot.create(:user, confirmed_at: nil)
    with_post.update_columns(created_at: 40.days.ago)
    FactoryBot.create(:post, user: with_post)
    fresh = FactoryBot.create(:user, confirmed_at: nil)

    signed_in_long_ago = FactoryBot.create(:user).tap(&:confirm)
    signed_in_long_ago.update_columns(last_sign_in_at: 100.days.ago, last_sign_in_ip: '203.0.113.1', current_sign_in_ip: '203.0.113.1')
    recent = FactoryBot.create(:user).tap(&:confirm)
    recent.update_columns(last_sign_in_at: 1.day.ago, last_sign_in_ip: '203.0.113.2')

    audit = AuditEvent.record!(action: 'board.reorder', actor: recent, ip: '203.0.113.3')
    audit.update_columns(created_at: 100.days.ago)

    old_invitation = Invitation.create!(email: 'old@example.com', token_digest: 'x')
    old_invitation.update_columns(updated_at: 200.days.ago)
    accepted = Invitation.create!(email: 'yes@example.com', token_digest: 'y', accepted_at: 200.days.ago)
    accepted.update_columns(updated_at: 200.days.ago)

    result = described_class.perform_now

    expect(User.exists?(stale.id)).to be(false)
    expect(User.exists?(with_post.id)).to be(true)
    expect(User.exists?(fresh.id)).to be(true)
    expect(signed_in_long_ago.reload.last_sign_in_ip).to be_nil
    expect(recent.reload.last_sign_in_ip).to eq('203.0.113.2')
    expect(audit.reload.ip).to be_nil
    expect(Invitation.exists?(old_invitation.id)).to be(false)
    expect(Invitation.exists?(accepted.id)).to be(true)
    expect(result).to include(unconfirmed_accounts: 1, invitations: 1)
  end

  it 'keeps everything when a period is 0' do
    stale = FactoryBot.create(:user, confirmed_at: nil)
    stale.update_columns(created_at: 400.days.ago)
    stub_const('ENV', ENV.to_h.merge('UNCONFIRMED_ACCOUNT_RETENTION_DAYS' => '0'))

    described_class.perform_now
    expect(User.exists?(stale.id)).to be(true)
  end
end
