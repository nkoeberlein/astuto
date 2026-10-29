require 'swagger_helper'

RSpec.describe 'api/app/v1/site_settings/invitations', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  include ActiveJob::TestHelper

  let(:admin) { FactoryBot.create(:admin, email: 'admin@acme.example').tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:body_text) { "Hi!\n\n%link%\n\nBye" }

  before do
    FactoryBot.create(:user, email: 'member@acme.example')
    Invitation.create!(email: 'old@acme.example', token_digest: 'x', updated_at: 4.months.ago)
    Invitation.create!(email: 'joined@acme.example', token_digest: 'y', accepted_at: 1.day.ago)
  end

  path '/api/app/v1/site_settings/invitations' do
    get('Invitations sent (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'with status') do
        schema type: :array, items: { '$ref' => '#/components/schemas/Invitation' }
        before { sign_in admin }

        run_test! do |response|
          statuses = JSON.parse(response.body).to_h { |i| [i['email'], i['status']] }
          expect(statuses).to eq('old@acme.example' => 'expired', 'joined@acme.example' => 'accepted')
        end
      end

      response(403, 'moderators are not admins') do
        schema '$ref' => '#/components/schemas/Error'
        before { sign_in moderator }

        run_test!
      end
    end

    post('Send invitations (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :invitation, in: :body, schema: { '$ref' => '#/components/schemas/InvitationInput' }

      response(200, 'sends to new addresses, skips members, accepted and invalid ones') do
        schema '$ref' => '#/components/schemas/InvitationResult'
        let(:invitation) do
          { to: ['new@acme.example', 'member@acme.example', 'joined@acme.example', 'not-an-email', 'old@acme.example'], subject: 'Join us', body: body_text }
        end
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body)).to eq(
            'sent' => 2, 'skipped' => ['member@acme.example', 'joined@acme.example', 'not-an-email']
          )
          expect(Invitation.find_by(email: 'old@acme.example')).not_to be_expired
          invitation_mails = enqueued_jobs.select { |job| job['arguments'].first == 'InvitationMailer' }
          expect(invitation_mails.size).to eq(2)
        end
      end

      response(422, 'body without %link%') do
        schema '$ref' => '#/components/schemas/Error'
        let(:invitation) { { to: ['new@acme.example'], subject: 'Join us', body: 'No link here' } }
        before { sign_in admin }

        run_test! { expect(Invitation.find_by(email: 'new@acme.example')).to be_nil }
      end

      response(422, 'more than 20 addresses') do
        schema '$ref' => '#/components/schemas/Error'
        let(:invitation) { { to: (1..21).map { |n| "p#{n}@acme.example" }, subject: 'Join us', body: body_text } }
        before { sign_in admin }

        run_test!
      end
    end
  end

  path '/api/app/v1/site_settings/invitations/test' do
    post('Send a test invitation to oneself (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :invitation, in: :body, schema: { '$ref' => '#/components/schemas/InvitationTestInput' }

      response(200, 'sent to the admin, with a v2 sign-up link') do
        schema '$ref' => '#/components/schemas/InvitationTestResult'
        let(:invitation) { { subject: 'Join us', body: body_text } }
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body)).to eq('sentTo' => 'admin@acme.example')
          mail = ActionMailer::Base.deliveries.last
          expect(mail.to).to eq(['admin@acme.example'])
          expect(mail.subject).to eq('[TEST] Join us')
          expect(mail.body.encoded).to match(%r{/register\?[^"<]*invitation_token=})
          expect(Invitation.find_by(email: 'admin@acme.example')).to be_nil
        end
      end
    end
  end
end
