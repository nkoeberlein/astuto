# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::Client do
  describe '#enabled?' do
    it 'is false when provider is blank or unsupported' do
      expect(described_class.new(provider: nil).enabled?).to be(false)
      expect(described_class.new(provider: 'unknown', api_key: 'secret').enabled?).to be(false)
    end

    it 'requires an API key for openai and anthropic, but not for local ollama' do
      expect(described_class.new(provider: 'openai', api_key: nil).enabled?).to be(false)
      expect(described_class.new(provider: 'openai', api_key: 'sk-test').enabled?).to be(true)
      expect(described_class.new(provider: 'anthropic', api_key: 'sk-ant').enabled?).to be(true)
      expect(described_class.new(provider: 'ollama', api_key: nil).enabled?).to be(true)
    end
  end

  describe '.privacy_disclosure' do
    it 'reports disabled when AI_PROVIDER is not set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('AI_PROVIDER').and_return(nil)

      expect(described_class.privacy_disclosure).to include(enabled: false, shared_fields: [])
    end
  end

  describe '#complete' do
    it 'raises ConfigurationError when called while disabled' do
      client = described_class.new(provider: nil)
      expect do
        client.complete(system_prompt: 'sys', user_prompt: 'hi')
      end.to raise_error(Ai::Client::ConfigurationError)
    end

    it 'formats OpenAI-compatible chat completion requests (including Ollama)' do
      client = described_class.new(
        provider: 'ollama',
        base_url: 'http://ollama.internal:11434/v1',
        model: 'qwen2.5'
      )

      fake_response = instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'choices' => [{ 'message' => { 'content' => 'Summary output' } }] }
      )
      expect(HTTParty).to receive(:post).with(
        'http://ollama.internal:11434/v1/chat/completions',
        hash_including(headers: { 'Content-Type' => 'application/json' })
      ).and_return(fake_response)

      expect(client.complete(system_prompt: 'sys', user_prompt: 'hello')).to eq('Summary output')
    end

    it 'formats Anthropic messages API requests' do
      client = described_class.new(
        provider: 'anthropic',
        api_key: 'sk-ant-123',
        model: 'claude-3-5-haiku-latest'
      )

      fake_response = instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'content' => [{ 'type' => 'text', 'text' => 'Anthropic summary' }] }
      )
      expect(HTTParty).to receive(:post).with(
        'https://api.anthropic.com/v1/messages',
        hash_including(headers: hash_including('x-api-key' => 'sk-ant-123', 'anthropic-version' => '2023-06-01'))
      ).and_return(fake_response)

      expect(client.complete(system_prompt: 'sys', user_prompt: 'hello')).to eq('Anthropic summary')
    end
  end
end
