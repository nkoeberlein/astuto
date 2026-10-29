# Single sign-on

Besides email and password, people can sign in through:

- **OAuth 2.0 / OpenID Connect providers** (GitHub, GitLab, Google, Microsoft Entra ID, Keycloak,
  ...): Site settings › Authentication › OAuth
- **SAML 2.0** (Microsoft Entra ID, Okta, Keycloak, ADFS, Google Workspace, ...): Site settings ›
  Authentication › SAML single sign-on, described below

**Log in only with OAuth or SAML** (Site settings › General) hides the email and password form.
Accounts with two-factor authentication still enter their code after the provider
([two-factor-authentication.md](two-factor-authentication.md)).

## SAML 2.0

Astuto is the service provider (SP), your identity provider (IdP) vouches for the person. Each
feedback space has its own SAML configuration.

### 1. Register Astuto at the identity provider

Site settings › Authentication › SAML single sign-on shows the two values the IdP needs:

| Field at the IdP | Value |
|---|---|
| Identifier / Entity ID / Audience | `https://feedback.example.com/saml/metadata` |
| Reply URL / ACS URL (HTTP-POST binding) | `https://feedback.example.com/saml/acs` |

Many IdPs can also read the metadata from the entity ID URL. With multi-tenancy both use the
subdomain of the feedback space (also when it has a custom domain), like OAuth callbacks.

The IdP should send the email address as NameID (format `emailAddress`) or as an attribute, and
optionally the display name. Astuto recognises the usual attribute names (`email`, `mail`,
`displayName`, the Microsoft and OID claim URIs); others can be entered in the settings.

**Microsoft Entra ID:** Enterprise applications › New application › Create your own
application › Integrate any other application (non-gallery) › Single sign-on › SAML. Basic SAML
configuration: identifier and reply URL from the table. Download *Federation Metadata XML*.

**Keycloak:** Clients › Create client › SAML, client ID = the entity ID, valid redirect URI = the
ACS URL, *Name ID format* email, *Sign documents* on. Realm settings › SAML 2.0 Identity Provider
Metadata has the metadata.

**Okta:** Applications › Create App Integration › SAML 2.0, *Single sign-on URL* = ACS URL,
*Audience URI* = entity ID, *Name ID format* EmailAddress. *View SAML setup instructions* shows the
metadata.

### 2. Enter the identity provider in Astuto

Paste the metadata XML of the IdP and click **Fill in from metadata** (it reads entity ID, SSO URL
and signing certificate; the XML is not stored and no URL is fetched), or enter the three fields by
hand. The SSO URL must use HTTPS.

**Create an account on the first login** (on by default) signs up people the IdP knows. Turn it
off to admit only existing accounts, for example people you invited. Blocked accounts never sign
in.

Turn on **Use SAML single sign-on** and save. The login page then shows a button with the text you
chose.

### What is checked

Every response must be signed with the certificate in the settings, be addressed to this feedback
space (audience and recipient), answer the request Astuto sent (no unsolicited responses) and be
current (one minute of clock drift). The login then finishes only in the browser that started it
(a nonce in the session), so nobody can sign someone else into their account by sending them a
response. Logins started on a custom domain finish there.

Identity-provider-initiated logins (starting from the IdP's app portal) are not supported; the app
link at the IdP should point to `https://feedback.example.com/saml/start`.
