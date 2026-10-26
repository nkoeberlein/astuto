# Checks URLs that admins enter for links (header links, logo link) before they
# land in an href. Only http(s), mailto and same-site paths are allowed, so a
# "javascript:" or "data:" URL can never run script in a visitor's browser.
module SafeUrl
  SCHEMES = %w[http https mailto].freeze

  def self.safe?(url)
    value = url.to_s.strip
    return false if value.empty?
    return true if local_path?(value)

    uri = URI.parse(value)
    scheme = uri.scheme.to_s.downcase
    return false unless SCHEMES.include?(scheme)

    scheme == 'mailto' || uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  # Same-site path like "/next/posts/1", but not a protocol-relative "//host"
  # URL. Backslashes and line breaks are rejected because browsers treat "/\host"
  # like "//host". Use it for return targets after sign-in.
  def self.local_path?(value)
    return false unless value.is_a?(String)

    value.start_with?('/') && !value.start_with?('//') && !value.match?(/[\\\r\n]/)
  end

  # Returns the URL if it is safe, otherwise nil
  def self.sanitize(url)
    safe?(url) ? url.to_s.strip : nil
  end
end
