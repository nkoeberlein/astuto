# Visitor tokens of the embeddable widget: a JWT signed with HS256 by the customer's app
# (claims: email, name, id = their user id, exp). Other algorithms are refused, and so are
# tokens without exp or valid for more than a day, so a leaked token does not last.
module WidgetToken
  class Invalid < StandardError; end

  MAX_LIFETIME = 1.day.to_i
  LEEWAY = 60

  def self.decode(token, secret)
    raise Invalid, 'no secret' if secret.blank?

    parts = token.to_s.split('.', -1)
    raise Invalid, 'malformed' unless parts.size == 3

    header = JSON.parse(Base64.urlsafe_decode64(parts[0]))
    raise Invalid, 'algorithm' unless header.is_a?(Hash) && header['alg'] == 'HS256'

    expected = OpenSSL::HMAC.digest('SHA256', secret, "#{parts[0]}.#{parts[1]}")
    raise Invalid, 'signature' unless ActiveSupport::SecurityUtils.secure_compare(expected, Base64.urlsafe_decode64(parts[2]))

    claims = JSON.parse(Base64.urlsafe_decode64(parts[1]))
    raise Invalid, 'claims' unless claims.is_a?(Hash)

    now = Time.now.to_i
    exp = claims['exp']
    raise Invalid, 'expired' unless exp.is_a?(Integer) && exp + LEEWAY >= now
    raise Invalid, 'lifetime' if exp > now + MAX_LIFETIME + LEEWAY

    claims
  rescue ArgumentError, JSON::ParserError
    raise Invalid, 'malformed'
  end

  # For tests and the docs: what the customer's app does
  def self.encode(claims, secret)
    segments = [{ alg: 'HS256', typ: 'JWT' }, claims].map { |part| Base64.urlsafe_encode64(part.to_json, padding: false) }
    signature = Base64.urlsafe_encode64(OpenSSL::HMAC.digest('SHA256', secret, segments.join('.')), padding: false)
    [*segments, signature].join('.')
  end
end
