require 'rails_helper'

RSpec.describe SafeUrl do
  it 'allows http, https, mailto and same-site paths' do
    %w[https://example.com/docs http://example.com mailto:team@example.com /roadmap].each do |url|
      expect(described_class.safe?(url)).to be(true), url
    end
  end

  it 'rejects script, data and protocol-relative URLs' do
    [
      'javascript:alert(1)',
      'JavaScript:alert(1)',
      ' javascript:alert(1)',
      "java\tscript:alert(1)",
      'data:text/html,<script>alert(1)</script>',
      'vbscript:msgbox(1)',
      '//evil.example.com',
      'https:/no-host',
      '',
      nil
    ].each do |url|
      expect(described_class.safe?(url)).to be(false), url.inspect
    end
  end

  it 'sanitize returns nil for unsafe URLs' do
    expect(described_class.sanitize(' https://example.com ')).to eq('https://example.com')
    expect(described_class.sanitize('javascript:alert(1)')).to be_nil
  end

  describe '.local_path?' do
    it 'allows same-site paths' do
      %w[/ /next /next/posts/1?sort=new].each do |path|
        expect(described_class.local_path?(path)).to be(true), path
      end
    end

    it 'rejects other hosts, schemes and tricks browsers read as a host' do
      ['//evil.com', '/\\evil.com', '/\\/evil.com', 'evil.com', 'javascript:alert(1)',
       "/next\r\nSet-Cookie: x", 'https://evil.com', '', nil, ['/next']].each do |value|
        expect(described_class.local_path?(value)).to be(false), value.inspect
      end
    end
  end
end
