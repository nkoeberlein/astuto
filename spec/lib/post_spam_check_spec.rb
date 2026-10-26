require 'rails_helper'

RSpec.describe PostSpamCheck do
  it 'treats any honeypot value as spam' do
    expect(described_class.honeypot_filled?('https://spam.example')).to be(true)
    expect(described_class.honeypot_filled?('')).to be(false)
    expect(described_class.honeypot_filled?(nil)).to be(false)
  end

  it 'flags forms sent in under two seconds or without a duration' do
    expect(described_class.too_fast?(1999)).to be(true)
    expect(described_class.too_fast?(nil)).to be(true)
    expect(described_class.too_fast?('2500')).to be(false)
  end
end
