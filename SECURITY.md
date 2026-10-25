# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 2.0 pre-releases (alpha/beta) | the latest pre-release only |
| 1.x (archived [astuto/astuto](https://github.com/astuto/astuto)) | no, end of life since January 2026 |

Security fixes go into the next release. Until 2.0.0 is out, update to the latest pre-release to get them.

## Reporting a vulnerability

Please **do not open a public issue** for security problems.

Report privately through GitHub: go to the [Security tab](https://github.com/nkoeberlein/astuto/security) and choose **Report a vulnerability**. Include:

- the affected version or commit
- steps to reproduce, or a proof of concept
- the impact as you see it (what an attacker can do, and which role they need)

## What happens next

| Step | Target |
|---|---|
| Acknowledgement of your report | within 7 days |
| First assessment (severity, affected versions) | within 14 days |
| Fix for critical and high severity issues | within 30 days |

We coordinate the disclosure with you: the advisory is published together with the fixed release, and we credit you unless you prefer otherwise.

## Scope

In scope: the Astuto Evolution application and its official Docker image (`ghcr.io/nkoeberlein/astuto`).

Expected behaviour, not vulnerabilities:

- Site admins and owners can change appearance and behaviour of their site, for example with custom CSS. Reports need to show a way across these boundaries, e.g. from a regular user to admin, or from one tenant to another.
- Self-hosted installations are operated by their admins: TLS, reverse proxy, backups, SMTP and secrets (`SECRET_KEY_BASE`) are their responsibility. Configuration guides are in [docs/](docs/).
- Missing hardening that cannot be exploited (e.g. a header that has no effect in this setup).
