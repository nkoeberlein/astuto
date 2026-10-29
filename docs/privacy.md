# Privacy and GDPR

What Astuto Evolution stores about people, where data leaves the instance, and the tools for
access requests, deletion and storage limits. It is meant for operators and data protection
officers; it is not legal advice.

## What is stored

Everything is in the PostgreSQL database of the instance; there are no uploaded files.

| Data | Purpose | Kept |
|---|---|---|
| Name, email, encrypted password, role, notification settings | account | until the account is deleted |
| User id from your own app (`widget_external_id`), when the person came through the [widget](widget.md) | linking the account | until the account is deleted; part of the data export |
| Posts, comments, votes, followed posts | the feedback itself | with the account; after deletion posts and comments stay without a name |
| Sign-in count, times and IP addresses of the current and last sign-in (Devise) | security | IPs: `IP_RETENTION_DAYS` (90) after the last sign-in |
| Unconfirmed sign-ups | confirmation link | `UNCONFIRMED_ACCOUNT_RETENTION_DAYS` (30) if nothing was posted |
| Invitations (email address) | invitation link | `INVITATION_RETENTION_DAYS` (180) if not accepted |
| Audit log: admin and moderator actions with name and IP | accountability of moderation | `AUDIT_LOG_RETENTION_DAYS` (365), IPs `IP_RETENTION_DAYS` (90) |
| Webhook delivery log | troubleshooting | newest 50 per webhook |

A daily job removes what is past its period (with Sidekiq at 03:30, `PURGE_EXPIRED_DATA_CRON`;
without Sidekiq run `bin/rails astuto:purge_expired_data` from cron). Setting a period to `0`
switches that part off.

Server logs (Rails, reverse proxy) contain IP addresses and paths; their retention is up to the
operator. Backups contain everything above until they are rotated.

## Cookies

Only technically necessary cookies, no tracking:

| Cookie | Content | Lifetime |
|---|---|---|
| `_app_session` | signed-in user, CSRF token, flash messages (signed and encrypted) | browser session |
| `remember_user_token` | "Remember me" on login | 1 year, ends on sign-out |
| `token_state`, `oauth_return_to` | OAuth login in progress | until the login finishes |

The frontend stores nothing in `localStorage`.

## Where data leaves the instance

| Recipient | When | What |
|---|---|---|
| Gravatar (Automattic) | while **Site settings › General › Show avatars from Gravatar** is on (default) | every visitor's browser loads pictures from gravatar.com with an MD5 hash of the author's email address. Switch it off to show initials instead |
| SMTP server | emails (confirmation, notifications, recaps, invitations) | recipient address and content |
| OAuth providers (GitHub, Keycloak, ...) | sign-in through them | the provider learns that the person signs in here |
| Webhook receivers | webhooks configured by admins | what the templates contain, e.g. post text and author name |
| AI provider | only with `AI_PROVIDER` set and only when a moderator requests a summary | post and comment texts of that discussion |

Nothing else is loaded from third parties: fonts, scripts and styles come from the instance
itself (Content Security Policy).

## Requests from people

- **Access (Art. 15):** signed-in people download their data in **Profile settings › My data**
  (JSON with profile, posts, comments, votes and followed posts). For requests by email, an admin
  downloads the same file in **Moderation › Users** (download icon); the download is recorded in
  the audit log.
- **Erasure (Art. 17):** people delete their account in **Profile settings**; admins can do it in
  **Moderation › Users** (bin icon). The account becomes "Deleted user": email, name, sign-in IPs,
  API key and followed posts are removed, posts and comments stay without a name, so discussions
  remain readable. If the content itself must go, a moderator deletes those posts or comments.
- **Rectification (Art. 16):** name and email are editable in Profile settings.

The owner of a feedback space cannot delete their own account, because the space would have no
owner. The owner's data goes when the feedback space itself is deleted (instance admin page in a
multi-tenant setup, or dropping the database).
