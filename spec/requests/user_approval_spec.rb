require 'rails_helper'

# Admin approval of new accounts (#362)
RSpec.describe 'User approval', type: :request do
  let!(:admin) { FactoryBot.create(:admin, email: 'admin@example.com').tap(&:confirm) }

  before { Current.tenant.tenant_setting.update!(require_user_approval: true) }

  def register(email = 'new@example.com')
    post '/api/app/v1/registration', params: { fullName: 'New Person', email: email, password: 'password123', passwordConfirmation: 'password123' }, as: :json
  end

  it 'lets new accounts wait and tells the admins' do
    expect { register }.to have_enqueued_mail(AdminMailer, :user_pending_approval)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include('approvalRequired' => true)
    expect(User.find_by(email: 'new@example.com')).to be_pending_approval
  end

  it 'refuses the login with a clear message until an admin approves' do
    register
    user = User.find_by(email: 'new@example.com').tap(&:confirm)

    post '/api/app/v1/session', params: { email: user.email, password: 'password123' }, as: :json
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body['error']).to eq(I18n.t('errors.user_pending_approval'))

    sign_in admin
    expect do
      patch "/api/app/v1/moderation/users/#{user.id}", params: { status: 'active' }, as: :json
    end.to have_enqueued_mail(UserMailer, :account_approved)
    expect(user.reload).to be_active

    get '/api/app/v1/moderation/users', params: { status: 'pending_approval' }
    expect(response.parsed_body['counts']['pendingApproval']).to eq(0)
  end

  it 'lets invited people in without approval' do
    invitation = Invitation.create!(email: 'invited@example.com', token_digest: Digest::SHA256.hexdigest('tok'))
    allow(Invitation).to receive(:find_acceptable).and_return(invitation)

    post '/api/app/v1/registration', params: { email: 'invited@example.com', fullName: 'Invited', password: 'password123', invitationToken: 'tok' }, as: :json

    expect(User.find_by(email: 'invited@example.com')).to be_active
  end

  it 'keeps sign-ups active when approval is off' do
    Current.tenant.tenant_setting.update!(require_user_approval: false)
    register

    expect(User.find_by(email: 'new@example.com')).to be_active
    expect(response.parsed_body['approvalRequired']).to be(false)
  end

  it 'escapes names in the admin email once' do
    user = FactoryBot.create(:user, full_name: 'Tom & "Jerry"', status: 'pending_approval')
    body = AdminMailer.user_pending_approval(admin: admin, user: user).body.encoded

    expect(body).to include('<strong>Tom &amp; &quot;Jerry&quot;</strong>')
    expect(body).to include('/moderation/users?status=pending_approval')
  end
end
