require 'rails_helper'

RSpec.describe WidgetToken do
  let(:secret) { 'wsk_test_secret' }
  let(:claims) { { 'email' => 'ann@example.com', 'exp' => 1.hour.from_now.to_i } }

  it 'reads tokens signed with the secret' do
    expect(described_class.decode(described_class.encode(claims, secret), secret)).to eq(claims)
  end

  it 'refuses wrong signatures, other algorithms and broken tokens' do
    expect { described_class.decode(described_class.encode(claims, 'other'), secret) }.to raise_error(WidgetToken::Invalid, 'signature')

    header = Base64.urlsafe_encode64({ alg: 'none' }.to_json, padding: false)
    payload = Base64.urlsafe_encode64(claims.to_json, padding: false)
    expect { described_class.decode("#{header}.#{payload}.", secret) }.to raise_error(WidgetToken::Invalid, 'algorithm')

    expect { described_class.decode('not-a-token', secret) }.to raise_error(WidgetToken::Invalid)
    expect { described_class.decode('a.b.c', secret) }.to raise_error(WidgetToken::Invalid)
    expect { described_class.decode(described_class.encode(claims, secret), nil) }.to raise_error(WidgetToken::Invalid)
  end

  it 'needs a short expiry' do
    expired = claims.merge('exp' => 10.minutes.ago.to_i)
    forever = claims.merge('exp' => 1.year.from_now.to_i)

    expect { described_class.decode(described_class.encode(claims.except('exp'), secret), secret) }.to raise_error(WidgetToken::Invalid, 'expired')
    expect { described_class.decode(described_class.encode(expired, secret), secret) }.to raise_error(WidgetToken::Invalid, 'expired')
    expect { described_class.decode(described_class.encode(forever, secret), secret) }.to raise_error(WidgetToken::Invalid, 'lifetime')
  end
end
