# Single sign-on

Besides email and password, people can sign in through:

- **OAuth 2.0 / OpenID Connect providers** (GitHub, GitLab, Google, Microsoft Entra ID, Keycloak,
  ...): Site settings › Authentication › OAuth
- **SAML 2.0** (Microsoft Entra ID, Okta, Keycloak, ADFS, Google Workspace, ...): Site settings ›
  Authentication › SAML single sign-on, described below
- **LDAP / Active Directory**: login name and password of the company directory, described below

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

## LDAP / Active Directory

The login page then asks for the **login name and password of the company account** first (with a
link to email and password, unless only SSO is allowed). Astuto connects to the directory, finds
the person's entry with a service account and checks the password by binding as that entry. The
password is never stored.

Site settings › Authentication › LDAP / Active Directory:

| Setting | Active Directory | OpenLDAP |
|---|---|---|
| Server, port | `dc1.corp.example.com`, 389 (StartTLS) or 636 (LDAPS) | `ldap.example.com`, 389 or 636 |
| Base DN | `DC=corp,DC=example,DC=com` | `ou=people,dc=example,dc=com` |
| Service account | `CN=astuto,OU=Service Accounts,DC=corp,DC=example,DC=com` | `cn=astuto,ou=services,dc=example,dc=com` |
| User filter | `(&(objectClass=user)(sAMAccountName=%{login}))` | `(uid=%{login})` |
| Email / name attribute | `mail` / `displayName` | `mail` / `displayName` (falls back to `cn`) |

`%{login}` is replaced by what the person types, escaped, so characters like `*` or `)` cannot
change the filter. The default filter accepts `uid`, `sAMAccountName` or the email address. A
search that finds more than one entry is refused.

- **Encryption:** StartTLS or LDAPS with certificate check by default. Unencrypted connections
  send passwords in clear text; use them only inside a trusted network. A self-signed directory
  certificate can be trusted through the CA certificates of the container (see
  [reverse-proxy-and-smtp.md](reverse-proxy-and-smtp.md)) instead of switching the check off.
- **Service account:** needs read access to the attributes above; its password is stored
  encrypted and never sent to the browser. Without one, Astuto searches anonymously.
- **Test with a login name** checks connection, service account and filter and shows the entry it
  found.
- **Accounts:** the email address from the directory identifies the account. On the first login an
  account is created (or only existing accounts are admitted), and an unconfirmed account is
  confirmed, since the directory vouches for the address. Wrong passwords and unknown logins get
  the same answer; blocked accounts are refused. Logins are rate-limited like email logins.
- Accounts with two-factor authentication enter their code after the directory password.

