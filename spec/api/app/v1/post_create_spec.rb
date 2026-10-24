require 'swagger_helper'

RSpec.describe 'api/app/v1 create post', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let!(:board) { FactoryBot.create(:board) }
  let(:user) { FactoryBot.create(:user).tap(&:confirm) }
  let(:setting) { Current.tenant.tenant_setting }
  let(:form) { { title: 'Dark mode please', description: 'For late nights', formRenderedAt: 10.seconds.ago.to_i } }

  path '/api/app/v1/boards/{board_id}/posts' do
    parameter name: :board_id, in: :path, type: :string, description: 'Board id or slug'

    post('Create post') do
      tags 'Posts'
      description 'Signed-in users post under their name. Anonymous posts need allowAnonymousFeedback. ' \
                  'Depending on the approval policy the post starts as pending.'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :new_post, in: :body, schema: { '$ref' => '#/components/schemas/NewPost' }
      let(:board_id) { board.slug }

      response(201, 'created by a signed-in user, approved and followed') do
        schema '$ref' => '#/components/schemas/Post'
        let(:new_post) { form }
        before { sign_in user }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('approvalStatus' => 'approved', 'followed' => true)
          expect(body['author']['id']).to eq(user.id)
        end
      end

      response(201, 'anonymous, pending moderator approval') do
        schema '$ref' => '#/components/schemas/Post'
        let(:new_post) { form.merge(isAnonymous: true) }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('approvalStatus' => 'pending', 'author' => nil)
        end
      end

      response(201, 'policy always_require_approval keeps even signed-in posts pending') do
        schema '$ref' => '#/components/schemas/Post'
        let(:new_post) { form }
        before do
          setting.update!(feedback_approval_policy: 'always_require_approval')
          sign_in user
        end

        run_test! { |response| expect(JSON.parse(response.body)['approvalStatus']).to eq('pending') }
      end

      response(401, 'not anonymous and not signed in') do
        schema '$ref' => '#/components/schemas/Error'
        let(:new_post) { form }

        run_test!
      end

      response(403, 'anonymous feedback disabled') do
        schema '$ref' => '#/components/schemas/Error'
        let(:new_post) { form.merge(isAnonymous: true) }
        before { setting.update!(allow_anonymous_feedback: false) }

        run_test!
      end

      response(422, 'spam: honeypot filled') do
        schema '$ref' => '#/components/schemas/Error'
        let(:new_post) { form.merge(honeypot: 'http://spam.example') }
        before { sign_in user }

        run_test! do
          Current.tenant = Tenant.first # reset after the request
          expect(Post.count).to eq(0)
        end
      end

      response(422, 'spam: form submitted too fast') do
        schema '$ref' => '#/components/schemas/Error'
        let(:new_post) { form.merge(formRenderedAt: Time.now.to_i) }
        before { sign_in user }

        run_test!
      end

      response(422, 'invalid title') do
        schema '$ref' => '#/components/schemas/Error'
        let(:new_post) { form.merge(title: 'ab') }
        before { sign_in user }

        run_test!
      end
    end
  end
end
