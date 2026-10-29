require 'rails_helper'

# Legacy JSON endpoints around a post must not show more than the post page itself
RSpec.describe 'legacy read access', type: :request do
  let(:setting) { Current.tenant.tenant_setting }
  let(:approved) { FactoryBot.create(:post) }
  let(:pending) { FactoryBot.create(:post, approval_status: 'pending') }
  let(:json) { { 'Accept' => 'application/json' } }

  %w[comments likes post_status_changes].each do |resource|
    it "hides the #{resource} of a post waiting for approval from everyone but moderators" do
      get "/posts/#{pending.id}/#{resource}", headers: json
      expect(response).to have_http_status(:not_found)

      sign_in FactoryBot.create(:user).tap(&:confirm)
      get "/posts/#{pending.id}/#{resource}", headers: json
      expect(response).to have_http_status(:not_found)

      sign_in FactoryBot.create(:moderator).tap(&:confirm)
      get "/posts/#{pending.id}/#{resource}", headers: json
      expect(response).to have_http_status(:ok)
    end

    it "shows the #{resource} of approved posts" do
      get "/posts/#{approved.id}/#{resource}", headers: json
      expect(response).to have_http_status(:ok)
    end

    it "requires a login for the #{resource} of a private feedback space" do
      setting.update!(is_private: true)

      get "/posts/#{approved.id}/#{resource}", headers: json
      expect(response).to redirect_to(new_user_session_path)
    end
  end

end
