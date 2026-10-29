require 'swagger_helper'

RSpec.describe 'api/app/v1/moderation/posts', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:user) { FactoryBot.create(:user).tap(&:confirm) }
  let!(:approved) { FactoryBot.create(:post, title: 'Approved idea') }
  let!(:old_pending) { FactoryBot.create(:post, approval_status: 'pending', user: user, created_at: 2.days.ago) }
  let!(:new_pending) { FactoryBot.create(:post, approval_status: 'pending', user: nil, created_at: 1.hour.ago) }
  let!(:rejected) { FactoryBot.create(:post, approval_status: 'rejected') }

  path '/api/app/v1/moderation/posts' do
    get('Feedback queue: pending and rejected posts (moderators)') do
      tags 'Moderation'
      produces 'application/json'

      response(200, 'newest first, without approved posts') do
        schema '$ref' => '#/components/schemas/ModerationQueue'
        before { sign_in moderator }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['posts'].map { |p| p['id'] }).to eq([rejected.id, new_pending.id, old_pending.id])
          expect(body['pendingCount']).to eq(2)
          expect(body['posts'][1]['author']).to be_nil
          expect(body['posts'][2]['author']).to include('id' => user.id)
          expect(body['posts'][2]['author']).not_to have_key('email')
          expect(body).to include('allowAnonymousFeedback' => true, 'feedbackApprovalPolicy' => 'anonymous_require_approval')
        end
      end

      response(403, 'not a moderator') do
        schema '$ref' => '#/components/schemas/Error'
        before { sign_in user }

        run_test!
      end

      response(401, 'not signed in') do
        schema '$ref' => '#/components/schemas/Error'

        run_test!
      end
    end
  end
end
