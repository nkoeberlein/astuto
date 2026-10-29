require 'rails_helper'

RSpec.describe OAuthSignInUserWorkflow do
  let(:o_auth) { FactoryBot.create(:o_auth, is_enabled: true, json_user_email_path: 'email', json_user_name_path: 'name') }

  def run(email)
    described_class.new(user_profile: { 'email' => email, 'name' => 'Olga OAuth' }, o_auth: o_auth).run
  end

  it 'creates new accounts that wait for approval when the space requires it, and tells admins' do
    Current.tenant.tenant_setting.update!(require_user_approval: true)
    FactoryBot.create(:admin)

    user = nil
    expect { user = run('olga@example.com') }.to have_enqueued_mail(AdminMailer, :user_pending_approval)
    expect(user).to be_pending_approval
    expect(user.active_for_authentication?).to be(false)
  end

  it 'lets invited people and existing accounts in' do
    Current.tenant.tenant_setting.update!(require_user_approval: true)
    Invitation.create!(email: 'invited@example.com', token_digest: 'x')
    existing = FactoryBot.create(:user, email: 'known@example.com')

    expect(run('invited@example.com')).to be_active
    expect(run('known@example.com')).to eq(existing)
  end
end
