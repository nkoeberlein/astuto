# A fake identity provider for SAML specs: a throwaway key and certificate, and responses signed
# with them like a real IdP would (XML signature over the whole response)
module SamlHelper
  ISSUER = 'https://idp.example.com/saml'.freeze

  def self.key
    @key ||= OpenSSL::PKey::RSA.new(2048)
  end

  def self.certificate
    @certificate ||= begin
      cert = OpenSSL::X509::Certificate.new
      name = OpenSSL::X509::Name.parse('/CN=Test IdP')
      cert.version = 2
      cert.serial = 1
      cert.subject = name
      cert.issuer = name
      cert.public_key = key.public_key
      cert.not_before = Time.now - 3600
      cert.not_after = Time.now + (365 * 24 * 3600)
      cert.sign(key, OpenSSL::Digest.new('SHA256'))
      cert
    end
  end

  # ID of the AuthnRequest in a redirect to the IdP (HTTP-Redirect binding: deflate + base64)
  def saml_request_id(idp_redirect)
    query = Rack::Utils.parse_query(URI.parse(idp_redirect).query)
    xml = Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(Base64.decode64(query['SAMLRequest']))
    [Nokogiri::XML(xml).root['ID'], query['RelayState']]
  end

  def saml_response(destination:, audience:, in_response_to:, email:, name: 'Ada Lovelace', issuer: ISSUER,
                    sign_with: SamlHelper.key, expires_at: 5.minutes.from_now)
    now = Time.now.utc.iso8601
    until_time = expires_at.utc.iso8601
    xml = <<~XML
      <samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="_r#{SecureRandom.hex(10)}" Version="2.0" IssueInstant="#{now}" Destination="#{destination}" InResponseTo="#{in_response_to}">
        <saml:Issuer>#{issuer}</saml:Issuer>
        <samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status>
        <saml:Assertion ID="_a#{SecureRandom.hex(10)}" Version="2.0" IssueInstant="#{now}">
          <saml:Issuer>#{issuer}</saml:Issuer>
          <saml:Subject>
            <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">#{email}</saml:NameID>
            <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
              <saml:SubjectConfirmationData NotOnOrAfter="#{until_time}" Recipient="#{destination}" InResponseTo="#{in_response_to}"/>
            </saml:SubjectConfirmation>
          </saml:Subject>
          <saml:Conditions NotBefore="#{(Time.now - 60).utc.iso8601}" NotOnOrAfter="#{until_time}">
            <saml:AudienceRestriction><saml:Audience>#{audience}</saml:Audience></saml:AudienceRestriction>
          </saml:Conditions>
          <saml:AuthnStatement AuthnInstant="#{now}" SessionIndex="_s1">
            <saml:AuthnContext><saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef></saml:AuthnContext>
          </saml:AuthnStatement>
          <saml:AttributeStatement>
            <saml:Attribute Name="displayName"><saml:AttributeValue>#{name}</saml:AttributeValue></saml:Attribute>
          </saml:AttributeStatement>
        </saml:Assertion>
      </samlp:Response>
    XML
    document = XMLSecurity::Document.new(xml.gsub(/>\s+</, '><'))
    document.sign_document(sign_with, SamlHelper.certificate, XMLSecurity::Document::RSA_SHA256, XMLSecurity::Document::SHA256)
    Base64.strict_encode64(document.to_s)
  end
end
