# Two-factor authentication

Every account can add a second login step with an authenticator app (TOTP, RFC 6238: Aegis,
Google Authenticator, Microsoft Authenticator, 1Password, ...). Admins can make it mandatory for
staff.

## For users

**Profile settings › Two-factor authentication › Set up** asks for the current password (accounts
created through an OAuth provider have none), shows a QR code and the key for manual entry, and
turns on after the first valid code. Then ten **backup codes** appear once: each signs in once
without the phone. New codes can be created with a current code; the old ones stop working.

After that, every login asks for a code after the password, also after an OAuth login (GitHub,
Keycloak, ...). A code works only once; one code before or after the current one is accepted for
clock drift. Wrong codes count as failed logins and lock the account like wrong passwords
([account-lockout.md](account-lockout.md)). The second step must follow within five minutes.

A password reset does not sign in an account with two-factor authentication; the person logs in
normally afterwards, with a code.

## For admins

**Site settings › General › Require two-factor authentication for admins and moderators**: staff
without it see a notice and can neither moderate nor change settings (the app API answers 403)
until they set it up in their profile. Normal users are not affected. Turning a user's 2FA off for
them (lost phone, no backup codes) is not possible in the UI: delete and re-invite the account, or
on the server:

```bash
bin/rails runner 'User.find_by!(email: "ada@example.com").disable_two_factor!'
```

With multi-tenancy, prefix the code with `Current.tenant = Tenant.find_by!(subdomain: "acme");`.

API keys (REST API, MCP) are separate credentials and work without a code. Creating a new API
key needs the 2FA setup when it is required.

## Storage

The TOTP secret is stored encrypted with a key derived from `SECRET_KEY_BASE`, backup codes only
as SHA-256 digests. Changing `SECRET_KEY_BASE` makes existing setups unusable (users then need the
command above).
