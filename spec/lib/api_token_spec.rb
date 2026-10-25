require 'rails_helper'

RSpec.describe ApiToken do
  def request_with(headers)
    ActionDispatch::Request.new(Rack::MockRequest.env_for('/mcp', headers))
  end

  it 'reads Bearer and Rails token headers' do
    expect(described_class.extract(request_with('HTTP_AUTHORIZATION' => 'Bearer abc'))).to eq('abc')
    expect(described_class.extract(request_with('HTTP_AUTHORIZATION' => 'Token token="abc"'))).to eq('abc')
  end

  it 'falls back to the X-Api-Key header' do
    expect(described_class.extract(request_with('HTTP_X_API_KEY' => ' abc '))).to eq('abc')
  end

  it 'returns nil without a token' do
    expect(described_class.extract(request_with({}))).to be_nil
  end
end
