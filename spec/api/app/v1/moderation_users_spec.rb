require 'swagger_helper'

RSpec.describe 'api/app/v1/moderation/users', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:owner) { User.find_by(role: 'owner') || FactoryBot.create(:owner).tap(&:confirm) }
  let(:admin) { FactoryBot.create(:admin, full_name: 'Grace Admin').tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator, full_name: 'Mo Derator').tap(&:confirm) }
  let!(:ada) { FactoryBot.create(:user, full_name: 'Ada Lovelace', email: 'ada@example.com').tap(&:confirm) }
  let!(:blocked) { FactoryBot.create(:user, full_name: 'Bob Blocked', status: 'blocked').tap(&:confirm) }

  path '/api/app/v1/moderation/users' do
    parameter name: :search, in: :query, type: :string, required: false, description: 'Part of the name or email'
    parameter name: :role, in: :query, type: :string, required: false, enum: %w[user moderator admin owner]
    parameter name: :status, in: :query, type: :string, required: false, enum: %w[active blocked deleted]
    parameter name: :page, in: :query, type: :integer, required: false

    get('Users with role and status (moderators)') do
      tags 'Moderation'
      produces 'application/json'

      response(200, 'search by name or email, with permissions per user') do
        schema '$ref' => '#/components/schemas/ModerationUserPage'
        let(:search) { 'ADA@' }
        before { sign_in moderator }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['users'].map { |u| u['id'] }).to eq([ada.id])
          expect(body['users'][0]).to include('email' => 'ada@example.com', 'canChangeStatus' => true, 'canChangeRole' => false)
          expect(body['counts']).to include('blocked' => 1)
          expect(body['hasMore']).to be(false)
        end
      end

      response(200, 'filter by status') do
        schema '$ref' => '#/components/schemas/ModerationUserPage'
        let(:status) { 'blocked' }
        before { sign_in admin }

        run_test! do |response|
          users = JSON.parse(response.body)['users']
          expect(users.map { |u| u['id'] }).to eq([blocked.id])
          expect(users[0]).to include('canChangeStatus' => true, 'canChangeRole' => false)
        end
      end

      response(403, 'not a moderator') do
        schema '$ref' => '#/components/schemas/Error'
        before { sign_in ada }

        run_test!
      end

      response(401, 'not signed in') do
        schema '$ref' => '#/components/schemas/Error'

        run_test!
      end
    end
  end

  path '/api/app/v1/moderation/users/{id}' do
    parameter name: :id, in: :path, type: :integer

    patch('Block, unblock or change the role of a user') do
      tags 'Moderation'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :changes, in: :body, schema: { '$ref' => '#/components/schemas/UpdateModerationUser' }

      response(200, 'moderator blocks a user') do
        schema '$ref' => '#/components/schemas/ModerationUser'
        let(:id) { ada.id }
        let(:changes) { { status: 'blocked' } }
        before { sign_in moderator }

        run_test! do |response|
          expect(JSON.parse(response.body)).to include('status' => 'blocked', 'canChangeRole' => false)
          expect(ada.reload).to be_blocked
        end
      end

      response(200, 'admin makes a user moderator') do
        schema '$ref' => '#/components/schemas/ModerationUser'
        let(:id) { ada.id }
        let(:changes) { { role: 'moderator' } }
        before { sign_in admin }

        run_test! do
          expect(ada.reload.role).to eq('moderator')
        end
      end

      response(200, 'admin demotes a moderator, whose API key is removed') do
        schema '$ref' => '#/components/schemas/ModerationUser'
        let(:id) { moderator.id }
        let(:changes) { { role: 'user' } }
        before do
          FactoryBot.create(:api_key, user: moderator)
          sign_in admin
        end

        run_test! do
          expect(moderator.reload.role).to eq('user')
          expect(ApiKey.where(user_id: moderator.id)).to be_empty
        end
      end

      response(403, 'moderators cannot change roles') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { ada.id }
        let(:changes) { { role: 'moderator' } }
        before { sign_in moderator }

        run_test! { expect(ada.reload.role).to eq('user') }
      end

      response(403, 'moderators cannot block other moderators') do
        schema '$ref' => '#/components/schemas/Error'
        let(:other_moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
        let(:id) { other_moderator.id }
        let(:changes) { { status: 'blocked' } }
        before { sign_in moderator }

        run_test!
      end

      response(403, 'nobody changes the owner') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { owner.id }
        let(:changes) { { status: 'blocked' } }
        before { sign_in admin }

        run_test! { expect(owner.reload).to be_active }
      end

      response(403, 'nobody changes themselves') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { admin.id }
        let(:changes) { { role: 'user' } }
        before { sign_in admin }

        run_test!
      end

      response(422, 'owner cannot be assigned') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { ada.id }
        let(:changes) { { role: 'owner' } }
        before { sign_in owner }

        run_test! { expect(ada.reload.role).to eq('user') }
      end

      response(422, 'users cannot be marked deleted') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { ada.id }
        let(:changes) { { status: 'deleted' } }
        before { sign_in moderator }

        run_test!
      end
    end
  end
end
