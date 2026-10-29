require 'swagger_helper'

RSpec.describe 'api/app/v1 confirmation and unlock', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  include ActiveJob::TestHelper

  def sent_mail_subjects(&block)
    ActionMailer::Base.deliveries.clear
    perform_enqueued_jobs(&block)
    ActionMailer::Base.deliveries.map(&:subject)
  end

  path '/api/app/v1/confirmation' do
    post('Send the email confirmation link again') do
      tags 'Session'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :email_input, in: :body, schema: { '$ref' => '#/components/schemas/EmailInput' }

      response(200, 'instructions sent (paranoid mode)') do
        schema '$ref' => '#/components/schemas/MessageResponse'
        let(:user) { FactoryBot.create(:user, confirmed_at: nil) }
        let(:email_input) { { email: user.email } }

        it 'sends the link to an unconfirmed account' do |example|
          user
          subjects = sent_mail_subjects { submit_request(example.metadata) }
          assert_response_matches_metadata(example.metadata)
          expect(subjects.size).to eq(1)
          expect(JSON.parse(response.body)['message']).to eq(I18n.t('devise.confirmations.send_paranoid_instructions'))
        end
      end

      response(200, 'same answer for confirmed or unknown addresses, nothing sent') do
        schema '$ref' => '#/components/schemas/MessageResponse'
        let(:confirmed) { FactoryBot.create(:user).tap(&:confirm) }

        context 'confirmed' do
          let(:email_input) { { email: confirmed.email } }

          it 'sends nothing' do |example|
            confirmed
            expect(sent_mail_subjects { submit_request(example.metadata) }).to be_empty
            assert_response_matches_metadata(example.metadata)
          end
        end

        context 'unknown' do
          let(:email_input) { { email: 'nobody@example.com' } }
          run_test!
        end
      end

      response(422, 'invalid email format') do
        schema '$ref' => '#/components/schemas/Error'
        let(:email_input) { { email: 'nope' } }
        run_test!
      end
    end
  end

  path '/api/app/v1/unlock' do
    post('Send the unlock link again') do
      tags 'Session'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :email_input, in: :body, schema: { '$ref' => '#/components/schemas/EmailInput' }

      response(200, 'instructions sent (paranoid mode)') do
        schema '$ref' => '#/components/schemas/MessageResponse'
        let(:user) { FactoryBot.create(:user).tap(&:confirm) }
        let(:email_input) { { email: user.email } }

        it 'sends the link to a locked account only' do |example|
          user
          expect(sent_mail_subjects { submit_request(example.metadata) }).to be_empty

          user.lock_access!(send_instructions: false)
          expect(sent_mail_subjects { submit_request(example.metadata) }.size).to eq(1)
          assert_response_matches_metadata(example.metadata)
          expect(JSON.parse(response.body)['message']).to eq(I18n.t('devise.unlocks.send_paranoid_instructions'))
        end
      end

      response(422, 'invalid email format') do
        schema '$ref' => '#/components/schemas/Error'
        let(:email_input) { { email: 'nope' } }
        run_test!
      end
    end
  end
end
