require 'rails_helper'

RSpec.describe Webhook, 'encryption', type: :model do
  let(:key) { Digest::SHA256.digest(Rails.application.secret_key_base) }
  let(:raw) { ActiveSupport::MessageEncryptor.new(key, serializer: ActiveSupport::MessageEncryptor::NullSerializer) }
  let(:marshal) { ActiveSupport::MessageEncryptor.new(key, serializer: Marshal) }

  it 'stores url and headers encrypted as JSON' do
    webhook = FactoryBot.create(:webhook, url: 'https://example.com/hook', http_headers: [{ 'key' => 'X-Token', 'value' => 'secret' }])
    stored = Webhook.where(id: webhook.id).pick(:url, :http_headers)

    expect(stored.join).not_to include('example.com', 'secret')
    expect(raw.decrypt_and_verify(stored[0])).to eq('"https://example.com/hook"')
    expect(JSON.parse(JSON.parse(raw.decrypt_and_verify(stored[1])))).to eq([{ 'key' => 'X-Token', 'value' => 'secret' }])
  end

  it 'decrypts url and headers when loaded' do
    webhook = FactoryBot.create(:webhook, url: 'https://example.com/hook', http_headers: [{ 'key' => 'A', 'value' => 'B' }])
    loaded = Webhook.find(webhook.id)

    expect(loaded.url).to eq('https://example.com/hook')
    expect(loaded.http_headers).to eq([{ 'key' => 'A', 'value' => 'B' }])
  end

  it 'still reads values written with Marshal by older versions' do
    webhook = FactoryBot.create(:webhook)
    webhook.update_columns(url: marshal.encrypt_and_sign('https://old.example.com'), http_headers: marshal.encrypt_and_sign('[]'))
    loaded = Webhook.find(webhook.id)

    expect(loaded.url).to eq('https://old.example.com')
    expect(loaded.http_headers).to eq([])
  end
end
