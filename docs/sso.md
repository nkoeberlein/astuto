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

## OAuth 2.0 / OpenID Connect

Site settings › Authentication › OAuth › New. Register Astuto at the provider first; it asks for
a **redirect / callback URL**: `https://feedback.example.com/o_auths/<id>/callback`. The form
shows the exact URL after saving (with multi-tenancy it uses the subdomain of the feedback
space, also when it has a custom domain). Then fill in:

| Field | Meaning |
| --- | --- |
| Name, logo | text and image of the login button |
| Client ID, client secret | from the provider (the secret is stored and never shown again) |
| Authorize URL, token URL | the provider's OAuth endpoints |
| Profile URL | returns the signed-in person as JSON; several URLs separated by `;` are all fetched, their answers are then `profile0`, `profile1`, ... |
| Scope | space-separated, must allow reading email and name |
| JSON path of the email / name | where they are in the profile, e.g. `email`, `profile1[0].email` |
| Extra profile headers | sent with the profile request, if the provider needs them |

**Test** opens the provider and shows the profile Astuto received and what it read from it,
without signing in. Turn the provider on when the test finds email and name.

| Provider | Authorize URL | Token URL | Profile URL | Scope | Email / name path |
| --- | --- | --- | --- | --- | --- |
| Google | `https://accounts.google.com/o/oauth2/v2/auth` | `https://oauth2.googleapis.com/token` | `https://openidconnect.googleapis.com/v1/userinfo` | `openid email profile` | `email` / `name` |
| Microsoft Entra ID | `https://login.microsoftonline.com/<tenant>/oauth2/v2.0/authorize` | `https://login.microsoftonline.com/<tenant>/oauth2/v2.0/token` | `https://graph.microsoft.com/oidc/userinfo` | `openid email profile` | `email` / `name` |
| GitHub | `https://github.com/login/oauth/authorize` | `https://github.com/login/oauth/access_token` | `https://api.github.com/user;https://api.github.com/user/emails` | `read:user user:email` | `profile1[0].email` / `profile0.name` |
| GitLab | `https://gitlab.com/oauth/authorize` | `https://gitlab.com/oauth/token` | `https://gitlab.com/api/v4/user` | `read_user` | `email` / `name` |
| Keycloak | `https://<host>/realms/<realm>/protocol/openid-connect/auth` | `.../protocol/openid-connect/token` | `.../protocol/openid-connect/userinfo` | `openid email profile` | `email` / `name` |

Notes:

- **Microsoft:** `<tenant>` is the directory (tenant) ID, or `organizations` for any work account.
  The app registration needs the delegated Graph permissions `openid`, `email`, `profile`.
- **GitHub:** the second profile URL lists the email addresses, because the main profile only
  has a public one. GitHub lists the primary address first in most accounts; check with **Test**.
- **Self-hosted GitLab or Keycloak:** replace the host. Any OpenID Connect provider works the
  same way; its endpoints are in `/.well-known/openid-configuration`.

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

