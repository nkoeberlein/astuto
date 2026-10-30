# Account lockout (protects accounts against brute force)

Signing in with email and password uses Devise `:lockable`: after too many
failed login attempts **the individual account** is locked — independent of
the IP address and therefore also effective against distributed attacks. This
complements the IP-based rack-attack limiting (`/posts` anti-spam, planned
rules for `/api/v1` and `/mcp`) but does not replace it.

Affected logins: the old form (`/users/sign_in`) and the app API
(`POST /api/app/v1/session`).

## Behaviour

- Failed attempts are counted per account; after `LOCKABLE_MAXIMUM_ATTEMPTS`
  attempts the account is locked.
- When the account is locked, the person receives an email with an unlock
  link (unlock strategies `email` and `both`).
- With the strategies `time` and `both`, Devise allows sign-in again
  automatically once the lock is older than `LOCKABLE_UNLOCK_IN_HOURS`.
- A successful login resets the failed-attempt counter.

## Configuration

All thresholds are configurable via environment variables:

| Variable                    | Default             | Values                            |
|-----------------------------|---------------------|-----------------------------------|
| `LOCKABLE_LOCK_STRATEGY`    | `failed_attempts`   | `failed_attempts`, `none`         |
| `LOCKABLE_UNLOCK_STRATEGY`  | `both`              | `both`, `email`, `time`, `none`   |
| `LOCKABLE_MAXIMUM_ATTEMPTS` | `10`                | integer                           |
| `LOCKABLE_UNLOCK_IN_HOURS`  | `2`                 | integer (hours)                   |

Description:

- **`LOCKABLE_LOCK_STRATEGY`** – how accounts are locked. `failed_attempts`
  locks after too many failed attempts, `none` disables the protection
  entirely (recommended only for special cases).
- **`LOCKABLE_UNLOCK_STRATEGY`** – how locked accounts are released again:
  `both` = email with an unlock link **and** automatic release after the
  configured time, `email` = email only, `time` = time only, `none` = neither
  (release only manually via the database, e.g. by an administrator).
- **`LOCKABLE_MAXIMUM_ATTEMPTS`** – the number of failed login attempts
  before the account is locked.
- **`LOCKABLE_UNLOCK_IN_HOURS`** – hours until the automatic release (only
  relevant for the strategies `time` and `both`).

The values are read at application start (`config/initializers/devise.rb`);
changes require a container restart.