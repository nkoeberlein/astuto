require 'rails_helper'

RSpec.describe 'Personal data (GDPR)', type: :request do
  let(:admin) { FactoryBot.create(:admin).tap(&:confirm) }
  let(:person) { FactoryBot.create(:user, full_name: 'Grace Hopper', email: 'grace@example.com').tap(&:confirm) }

  before do
    post_record = FactoryBot.create(:post, user: person, title: 'Dark mode')
    FactoryBot.create(:comment, user: person, post: post_record, body: 'Please!')
    FactoryBot.create(:like, user: person, post: post_record)
    Follow.create!(user: person, post: post_record)
  end

  describe 'export' do
    it 'lets people download their own data' do
      sign_in person
      get '/api/app/v1/profile/export'

      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Disposition']).to include('attachment', 'astuto-my-data.json')
      data = JSON.parse(response.body)
      expect(data['profile']).to include('fullName' => 'Grace Hopper', 'email' => 'grace@example.com')
      expect(data['posts'].map { |p| p['title'] }).to eq(['Dark mode'])
      expect(data['comments'].map { |c| c['body'] }).to eq(['Please!'])
      expect(data['votes'].size).to eq(1)
      expect(data['follows'].size).to eq(1)
    end

    it 'lets admins download the data of a person, recorded in the audit log' do
      sign_in admin
      get "/api/app/v1/moderation/users/#{person.id}/export"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig('profile', 'email')).to eq('grace@example.com')
      expect(AuditEvent.sole).to have_attributes(action: 'user.export', subject_label: 'Grace Hopper')
    end

    it 'is not available to moderators' do
      sign_in FactoryBot.create(:moderator).tap(&:confirm)
      get "/api/app/v1/moderation/users/#{person.id}/export"
      expect(response).to have_http_status(:unauthorized).or have_http_status(:forbidden)
    end
  end

  describe 'deletion by an admin' do
    it 'anonymizes the account and keeps the content' do
      person.update!(current_sign_in_ip: '203.0.113.7', last_sign_in_ip: '203.0.113.7')
      sign_in admin

      delete "/api/app/v1/moderation/users/#{person.id}"

      expect(response).to have_http_status(:no_content)
      person.reload
      expect(person).to be_deleted
      expect(person.email).to end_with('@deleted.com')
      expect(person.full_name).to eq(I18n.t('defaults.deleted_user_full_name'))
      expect(person.current_sign_in_ip).to be_nil
      expect(Follow.where(user: person)).to be_empty
      expect(Post.where(user: person).count).to eq(1)
      expect(AuditEvent.sole).to have_attributes(action: 'user.delete', subject_label: 'Grace Hopper')
    end

    it 'refuses the owner and oneself' do
      sign_in admin
      owner = User.find_by(role: 'owner') || FactoryBot.create(:owner)
      delete "/api/app/v1/moderation/users/#{owner.id}"
      expect(owner.reload).not_to be_deleted
      delete "/api/app/v1/moderation/users/#{admin.id}"
      expect(admin.reload).not_to be_deleted
    end
  end

  describe 'Gravatar' do
    it 'sends no avatar URLs when switched off' do
      sign_in person
      get '/api/app/v1/session'
      expect(response.parsed_body.dig('user', 'avatarUrl')).to start_with('https://secure.gravatar.com/')

      Current.tenant.tenant_setting.update!(use_gravatar: false)
      get '/api/app/v1/session'
      expect(response.parsed_body.dig('user', 'avatarUrl')).to be_nil
    end
  end
end
