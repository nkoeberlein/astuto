require 'rails_helper'

RSpec.describe RunWebhook do
  include ActiveSupport::Testing::TimeHelpers

  let(:webhook) do
    FactoryBot.create(
      :webhook, url: 'https://hooks.example/in', http_method: 'http_post', is_enabled: true,
      http_body: '{"title": "{{ post.title | escape_json }}"}',
      http_headers: [{ key: 'X-Astuto-Signature', value: 'forged' }, { key: 'X-Token', value: 't' }].to_json
    )
  end
  let(:ok) { instance_double(HTTParty::Response, code: 200, body: 'ok') }

  def run(webhook_id = webhook.id)
    described_class.perform_now(webhook_id: webhook_id, current_tenant_id: Current.tenant.id, is_test: true)
  end

  it 'signs the body with the webhook secret; own headers cannot replace the signature' do
    allow(HTTParty).to receive(:post).and_return(ok)
    travel_to(Time.zone.at(1_800_000_000)) { run }

    expect(HTTParty).to have_received(:post) do |url, options|
      expect(url).to eq('https://hooks.example/in')
      body = options[:body]
      expected = OpenSSL::HMAC.hexdigest('SHA256', webhook.signing_secret, "1800000000.#{body}")
      expect(options[:headers]).to include(
        'X-Astuto-Signature' => "sha256=#{expected}", 'X-Astuto-Timestamp' => '1800000000',
        'X-Astuto-Event' => 'new_post', 'X-Token' => 't'
      )
    end
  end

  it 'records successful and failed deliveries (#458)' do
    allow(HTTParty).to receive(:post).and_return(ok, instance_double(HTTParty::Response, code: 500, body: 'boom'))
    run
    run

    deliveries = webhook.deliveries.order(:id)
    expect(deliveries.map(&:success)).to eq([true, false])
    expect(deliveries.map(&:http_status)).to eq([200, 500])
    expect(deliveries.last.response_body).to eq('boom')
    expect(deliveries.first).to have_attributes(is_test: true, trigger: 'new_post')
  end

  it 'records template and JSON errors with a hint, and re-raises them' do
    webhook.update!(http_body: '{"title": {{ post.title }}}')

    expect { run }.to raise_error(JSON::ParserError)
    expect(webhook.deliveries.last).to have_attributes(success: false, http_status: nil)
    expect(webhook.deliveries.last.error).to include('JSON::ParserError', 'escape_json')
  end

  it 'records network errors' do
    allow(HTTParty).to receive(:post).and_raise(SocketError, 'getaddrinfo: Name or service not known')

    expect { run }.to raise_error(SocketError)
    expect(webhook.deliveries.last.error).to include('SocketError')
  end

  it 'keeps only the newest deliveries' do
    stub_const('WebhookDelivery::KEEP', 3)
    allow(HTTParty).to receive(:post).and_return(ok)
    5.times { run }

    expect(webhook.deliveries.count).to eq(3)
  end
end
