require 'swagger_helper'

RSpec.describe 'api/app/v1/site_settings/audit_events', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:admin) { FactoryBot.create(:admin, full_name: 'Ada Admin').tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator, full_name: 'Mo Derator').tap(&:confirm) }
  let(:author) { FactoryBot.create(:user).tap(&:confirm) }
  let(:headers) { { 'X-CSRF-Token' => 'skip' } }

  def events
    get '/api/app/v1/site_settings/audit_events'
    response.parsed_body['events']
  end

  path '/api/app/v1/site_settings/audit_events' do
    get('Audit log, newest first (admins)') do
      tags 'Site settings'
      produces 'application/json'
      parameter name: :category, in: :query, required: false, schema: { type: :string, enum: AuditEvent::CATEGORIES }
      parameter name: :before, in: :query, required: false, schema: { type: :integer }, description: 'nextBefore of the previous page'

      response(200, 'entries') do
        schema '$ref' => '#/components/schemas/AuditEventPage'
        let(:category) { 'board' }
        before do
          sign_in admin
          AuditEvent.record!(action: 'board.create', actor: admin, subject: FactoryBot.create(:board, name: 'Ideas'), changes: { 'name' => [nil, 'Ideas'] })
          AuditEvent.record!(action: 'webhook.delete', actor: admin)
        end

        run_test! do |response|
          body = response.parsed_body
          expect(body['events'].map { |e| e['action'] }).to eq(['board.create'])
          expect(body['events'][0]).to include('actorName' => 'Ada Admin', 'subjectLabel' => 'Ideas', 'source' => 'app')
          expect(body['events'][0]['changes']).to eq([{ 'field' => 'board.name', 'from' => nil, 'to' => 'Ideas' }])
          expect(body['nextBefore']).to be_nil
        end
      end

      response(403, 'moderators cannot read it') do
        schema '$ref' => '#/components/schemas/Error'
        before { sign_in moderator }
        run_test!
      end
    end
  end

  describe 'what gets recorded' do
    it "records moderation of other people's posts with the changed fields, but not own edits" do
      post_record = FactoryBot.create(:post, user: author, title: 'Dark mode')
      status = FactoryBot.create(:post_status)
      previous_status = post_record.post_status_id
      sign_in moderator

      patch "/api/app/v1/posts/#{post_record.id}", params: { postStatusId: status.id, approvalStatus: 'approved' }, as: :json
      expect(response).to have_http_status(:ok)
      own = FactoryBot.create(:post, user: moderator)
      patch "/api/app/v1/posts/#{own.id}", params: { title: 'Typo fixed' }, as: :json

      entries = AuditEvent.order(:id).to_a
      expect(entries.map(&:action)).to eq(['post.update'])
      expect(entries[0]).to have_attributes(user: moderator, subject_label: 'Dark mode', source: 'app')
      expect(entries[0].field_changes['post.post_status_id']).to eq([previous_status, status.id])
      expect(entries[0].ip).to be_present
    end

    it 'records role changes and site settings, and filters secrets' do
      member = FactoryBot.create(:user).tap(&:confirm)
      sign_in admin

      patch "/api/app/v1/moderation/users/#{member.id}", params: { role: 'moderator' }, as: :json
      patch '/api/app/v1/site_settings/general', params: { siteName: 'Acme Ideas', isPrivate: true }, as: :json
      post '/api/app/v1/site_settings/o_auths', params: {
        name: 'GitHub', clientId: 'id', clientSecret: 'very-secret', authorizeUrl: 'https://github.com/login/oauth/authorize',
        tokenUrl: 'https://github.com/login/oauth/access_token', profileUrl: 'https://api.github.com/user', scope: 'user:email',
        jsonUserEmailPath: 'email', isEnabled: true
      }, as: :json
      expect(response).to have_http_status(:created)

      by_action = AuditEvent.all.index_by(&:action)
      expect(by_action['user.update'].field_changes).to eq('user.role' => %w[user moderator])
      expect(by_action['site_settings.update'].field_changes).to include('tenant.site_name' => [anything, 'Acme Ideas'], 'tenant_setting.is_private' => [false, true])
      expect(by_action['o_auth.create'].field_changes['o_auth.client_secret']).to eq(%w[[filtered] [filtered]])
      expect(AuditEvent.pluck(:field_changes).to_json).not_to include('very-secret')
    end

    it 'records status changes through MCP with the source' do
      post_record = FactoryBot.create(:post)
      status = FactoryBot.create(:post_status)
      Mcp::Tools::UpdatePostStatus.run(user: moderator, post_id: post_record.id, post_status_id: status.id)

      expect(AuditEvent.sole).to have_attributes(action: 'post.update', source: 'mcp', user: moderator)
    end

    it 'removes entries older than the retention period' do
      old = AuditEvent.record!(action: 'board.reorder', actor: admin)
      old.update_column(:created_at, 400.days.ago)
      AuditEvent.record!(action: 'board.reorder', actor: admin)
      expect(AuditEvent.count).to eq(1)
    end
  end
end
