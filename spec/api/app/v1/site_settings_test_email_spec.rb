require 'swagger_helper'

RSpec.describe 'api/app/v1/site_settings/test_email', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:admin) { FactoryBot.create(:admin, email: 'admin@acme.example').tap(&:confirm) }

  path '/api/app/v1/site_settings/test_email' do
    post('Send a test email to oneself (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'sent at once') do
        schema '$ref' => '#/components/schemas/TestEmailResult'
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body)).to include('sentTo' => 'admin@acme.example', 'deliveryMethod' => 'test')
          mail = ActionMailer::Base.deliveries.last
          expect(mail.to).to eq(['admin@acme.example'])
          expect(mail.subject).to include('Test email')
        end
      end

      response(422, 'delivery error, even with delivery errors switched off') do
        schema '$ref' => '#/components/schemas/Error'
        before do
          allow_any_instance_of(Mail::Message).to receive(:deliver).and_raise(Net::SMTPAuthenticationError.new('535 Authentication failed'))
          sign_in admin
        end

        run_test! { |response| expect(JSON.parse(response.body)['error']).to include('Net::SMTPAuthenticationError', '535') }
      end

      response(403, 'moderators are not admins') do
        schema '$ref' => '#/components/schemas/Error'
        before { sign_in FactoryBot.create(:moderator).tap(&:confirm) }

        run_test!
      end
    end
  end
end
