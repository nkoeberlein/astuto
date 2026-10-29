require 'swagger_helper'

RSpec.describe 'api/app/v1/site_settings/webhooks', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:admin) { FactoryBot.create(:admin).tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let!(:webhook) do
    FactoryBot.create(
      :webhook, name: 'Slack', url: 'https://hooks.example/abc', http_method: 'http_put',
      http_body: '{"text": "{{ post.title | escape_json }}"}',
      http_headers: [{ key: 'Authorization', value: 'Bearer secret' }].to_json
    )
  end

  path '/api/app/v1/site_settings/webhooks' do
    get('Webhooks (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'with decrypted URL and headers') do
        schema type: :array, items: { '$ref' => '#/components/schemas/Webhook' }
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body).first).to include(
            'name' => 'Slack', 'httpMethod' => 'put', 'url' => 'https://hooks.example/abc',
            'httpHeaders' => [{ 'key' => 'Authorization', 'value' => 'Bearer secret' }]
          )
        end
      end

      response(403, 'moderators are not admins') do
        schema '$ref' => '#/components/schemas/Error'
        before { sign_in moderator }

        run_test! { |response| expect(response.body).not_to include('secret') }
      end
    end

    post('Create a webhook (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :webhook_input, in: :body, schema: { '$ref' => '#/components/schemas/WebhookInput' }

      response(201, 'created, empty header rows dropped') do
        schema '$ref' => '#/components/schemas/Webhook'
        let(:webhook_input) do
          {
            name: 'Discord', trigger: 'new_comment', httpMethod: 'post', isEnabled: true,
            url: 'https://discord.example/hook', httpBody: '{"content": "{{ comment.body | escape_json }}"}',
            httpHeaders: [{ key: 'X-Token', value: '1' }, { key: '', value: '' }]
          }
        end
        before { sign_in admin }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('trigger' => 'new_comment', 'httpHeaders' => [{ 'key' => 'X-Token', 'value' => '1' }])
          expect(Webhook.where(id: body['id']).pick(:url)).not_to include('discord')
        end
      end

      response(422, 'unknown HTTP method') do
        schema '$ref' => '#/components/schemas/Error'
        let(:webhook_input) { { name: 'Odd', trigger: 'new_post', httpMethod: 'get', url: 'https://x.example' } }
        before { sign_in admin }

        run_test!
      end
    end
  end

  path '/api/app/v1/site_settings/webhooks/{id}' do
    parameter name: :id, in: :path, type: :integer

    patch('Update a webhook (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :webhook_input, in: :body, schema: { '$ref' => '#/components/schemas/WebhookInput' }

      response(200, 'switched on') do
        schema '$ref' => '#/components/schemas/Webhook'
        let(:id) { webhook.id }
        let(:webhook_input) { { isEnabled: true } }
        before { sign_in admin }

        run_test! { expect(webhook.reload.is_enabled).to be(true) }
      end
    end

    delete('Delete a webhook (admins)') do
      tags 'Site settings'

      response(204, 'deleted') do
        let(:id) { webhook.id }
        before { sign_in admin }

        run_test! { expect(Webhook.exists?(webhook.id)).to be(false) }
      end
    end
  end

  path '/api/app/v1/site_settings/webhooks/variables' do
    get('Template variables per trigger (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'variables') do
        schema '$ref' => '#/components/schemas/WebhookVariables'
        before { sign_in admin }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['delete_post']).to eq(['post.id', 'tenant.site_name', 'tenant.subdomain', 'tenant.custom_domain'])
          expect(body['new_comment']).to include('comment.body', 'comment_author.full_name', 'post.url')
        end
      end
    end
  end

  path '/api/app/v1/site_settings/webhooks/templates' do
    get('Ready-made bodies for Slack, Discord and Microsoft Teams per trigger (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'templates') do
        schema '$ref' => '#/components/schemas/WebhookTemplates'
        before { sign_in admin }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.keys).to eq(%w[slack discord teams])
          expect(body['slack']['new_post']).to include('"text":', '{{ post.title | escape_json }}')
        end
      end
    end
  end

  path '/api/app/v1/site_settings/webhooks/preview' do
    post('Render URL and body with example data (admins)') do
      tags 'Site settings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :preview, in: :body, schema: { '$ref' => '#/components/schemas/WebhookPreviewInput' }

      response(200, 'rendered') do
        schema '$ref' => '#/components/schemas/WebhookPreview'
        let(:preview) { { trigger: 'new_post', url: 'https://x.example/{{ post.id }}', httpBody: '{"t": "{{ post.title | escape_json }}"}' } }
        before { sign_in admin }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['url']).to eq('https://x.example/0')
          expect(JSON.parse(body['body'])['t']).to be_present
        end
      end

      response(422, 'body is not JSON') do
        schema '$ref' => '#/components/schemas/Error'
        let(:preview) { { trigger: 'new_post', url: 'https://x.example', httpBody: '{"t": {{ post.title }}}' } }
        before { sign_in admin }

        run_test! { |response| expect(JSON.parse(response.body)['error']).to include('escape_json') }
      end

      response(422, 'Liquid syntax error') do
        schema '$ref' => '#/components/schemas/Error'
        let(:preview) { { trigger: 'new_post', url: 'https://x.example/{{ post.id', httpBody: '' } }
        before { sign_in admin }

        run_test!
      end
    end
  end

  path '/api/app/v1/site_settings/webhooks/{id}/test' do
    parameter name: :id, in: :path, type: :integer

    post('Send the webhook with example data (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'sent with the configured method and headers') do
        schema '$ref' => '#/components/schemas/WebhookTestResult'
        let(:id) { webhook.id }
        before do
          allow(HTTParty).to receive(:put).and_return(instance_double(HTTParty::Response, code: 202, body: 'accepted'))
          sign_in admin
        end

        run_test! do |response|
          expect(JSON.parse(response.body)).to eq('status' => 202, 'body' => 'accepted')
          expect(HTTParty).to have_received(:put).with('https://hooks.example/abc', hash_including(headers: hash_including('Authorization' => 'Bearer secret', 'X-Astuto-Event' => 'new_post')))
        end
      end
    end
  end

  path '/api/app/v1/site_settings/webhooks/{id}/deliveries' do
    parameter name: :id, in: :path, type: :integer

    get('Recent deliveries of a webhook (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'newest first') do
        schema type: :array, items: { '$ref' => '#/components/schemas/WebhookDelivery' }
        let(:id) { webhook.id }
        before do
          WebhookDelivery.record!(webhook: webhook, trigger: 'new_post', is_test: false, success: true, duration_ms: 12, http_status: 200)
          WebhookDelivery.record!(webhook: webhook, trigger: 'new_post', is_test: true, success: false, duration_ms: 3, error: 'SocketError: nope')
          sign_in admin
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.map { |d| d['success'] }).to eq([false, true])
          expect(body.first).to include('error' => 'SocketError: nope', 'isTest' => true)
        end
      end
    end
  end

  path '/api/app/v1/site_settings/webhooks/{id}/rotate_secret' do
    parameter name: :id, in: :path, type: :integer

    post('New signing secret (admins)') do
      tags 'Site settings'
      produces 'application/json'

      response(200, 'rotated') do
        schema '$ref' => '#/components/schemas/Webhook'
        let(:id) { webhook.id }
        let!(:old_secret) { webhook.signing_secret }
        before { sign_in admin }

        run_test! do |response|
          secret = JSON.parse(response.body)['signingSecret']
          expect(secret).to start_with('whsec_')
          expect(secret).not_to eq(old_secret)
        end
      end
    end
  end
end
