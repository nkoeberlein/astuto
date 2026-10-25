# Checks URLs that admins enter for links (header links, logo link) before they
# land in an href. Only http(s), mailto and same-site paths are allowed, so a
# "javascript:" or "data:" URL can never run script in a visitor's browser.
module SafeUrl
  SCHEMES = %w[http https mailto].freeze

  def self.safe?(url)
    value = url.to_s.strip
    return false if value.empty?
    # Same-site path, but not a protocol-relative "//host" URL
    return true if value.start_with?('/') && !value.start_with?('//')

    uri = URI.parse(value)
    scheme = uri.scheme.to_s.downcase
    return false unless SCHEMES.include?(scheme)

    scheme == 'mailto' || uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  # Returns the URL if it is safe, otherwise nil
  def self.sanitize(url)
    safe?(url) ? url.to_s.strip : nil
  end
end
