# Upgrading

## From Astuto 1.x to Astuto Evolution 2.0

The database is migrated automatically when the container starts. Keep
`SECRET_KEY_BASE` unchanged: sessions, API keys and the encrypted webhook
settings depend on it.

- **Logins stay valid.** Session and "remember me" cookies from 1.x keep
  working and are re-written with the new key derivation on the next visit.
- **Password reset links** sent before the update stop working. Request a new one.
- **Webhooks:** URLs and headers are re-encrypted in a portable JSON format on
  first start (migration `ReencryptWebhooksAsJson`). Nothing to do.
- **Sidekiq** (only with `ACTIVE_JOB_BACKEND=sidekiq`): needs Redis 7 or newer
  (see below). Queues come from `config/sidekiq.yml`; if you start Sidekiq with
  your own `-q` flags, include `webhooks`, otherwise webhooks never run.
- **Billing is gone** (it only applied to multi-tenant hosting): the migration
  `DropTenantBillings` deletes the trial and subscription data, and feedback spaces whose
  trial had ended are writable again. Remove `STRIPE_*`, `TRIAL_PERIOD_DAYS` and
  `ASTUTO_CNAME_API_*` from your environment; the `notify_tenants_trial_period` rake task no
  longer exists. Multi-tenant setups: see docs/multi-tenancy.md.
- The image no longer contains Node.js; Astuto does not need it at runtime.
- **Old JSON endpoints are gone** (`/posts.json`, `/boards`, `/posts/:id/comments`, ...,
  used by the old interface). Scripts that called them need the REST API (`/api/v1`
  with an API key, see `/api-docs`) or the MCP server.
- **New user interface at `/`.** Every page now comes from the new frontend. Links to
  the old pages keep working: `/next/...` (the preview of 2.0) redirects to `/...`, and
  `/users/sign_in`, `/users/sign_up`, `/users/password/new|edit` and `/users/edit` lead to
  `/login`, `/register`, `/password/forgot|reset` and `/profile`. Board, post, roadmap,
  moderation and settings addresses stay the same.
- **Embedded roadmap:** existing `<iframe src=".../embedded_roadmap?...">` codes keep working
  with the same parameters (`show_boards`, `show_statuses`, `show_board_filter`,
  `show_status_filter`). Posts open in a new tab. In a private feedback space the embed
  shows nothing to visitors who are not logged in.
- **Custom CSS** was written for the old markup (Bootstrap classes). Check it after the
  update and adjust selectors in Site settings › Appearance; the preview there shows the
  result before saving.

## PostgreSQL 14 → 19

PostgreSQL 14 reaches end of life on 2026-11-12. Major versions cannot read each
other's data directories, so the data has to be dumped and restored once.

PostgreSQL 19 is planned for 2026-11-19. If you do not want to wait, use
`postgres:18-trixie` (supported until 2030) with the same steps; moving from 18
to 19 later works the same way.

Two things change in the `docker-compose.yml`:

- the image: `postgres:14.5` → `postgres:19-trixie`
- the volume mount: Postgres ≥ 18 stores its data in `/var/lib/postgresql/<major>/docker`,
  so mount the volume at `/var/lib/postgresql` (not `/var/lib/postgresql/data`)
  and use a **new** volume name, so the old data stays untouched as a fallback.

```yaml
services:
  db:
    image: postgres:19-trixie
    volumes:
      - pgdata:/var/lib/postgresql

volumes:
  pgdata:
```

### Steps

Run these in the folder that contains your `docker-compose.yml`.
Replace `astuto` with your `POSTGRES_USER`.

1. Stop the app so nothing writes to the database:
   `docker compose stop web`
2. Dump everything from the old server:
   `docker compose exec -T db pg_dumpall -U astuto > astuto-backup.sql`
3. Check the dump is not empty (it should contain `CREATE TABLE` lines):
   `grep -c "CREATE TABLE" astuto-backup.sql`
4. Stop the old stack:
   `docker compose down`
5. Edit `docker-compose.yml` as shown above.
6. Start only the new database and wait until it accepts connections:
   `docker compose up -d db`
   `docker compose exec db pg_isready -U astuto`
7. Restore the dump:
   `docker compose exec -T db psql -U astuto -d postgres < astuto-backup.sql`
   The errors `role "astuto" already exists` and `database "astuto" already exists`
   are expected and harmless (the container created both on first start).
8. Start the app:
   `docker compose up -d`
9. Log in and check boards, posts and users. Once everything looks right, remove
   the old volume (`docker volume ls`, then `docker volume rm <project>_dbdata`).
   Keep `astuto-backup.sql` somewhere safe.

### Rollback

Restore the old `image` and volume lines in `docker-compose.yml` and run
`docker compose up -d`. The old volume was not modified.

## Sidekiq (optional background jobs)

If you run Astuto with `ACTIVE_JOB_BACKEND=sidekiq`, Astuto Evolution uses
Sidekiq 8, which requires **Redis 7 or newer**. Check with
`redis-cli INFO server | grep redis_version` and upgrade Redis first if needed.

## Content Security Policy

2.0 sends a Content Security Policy header. Scripts may only come from the
instance itself; inline scripts are blocked.
Custom CSS keeps working, including fonts or images loaded over `https`.
If a reverse proxy or an integration of yours injects scripts, they are now
blocked. Set `CSP_REPORT_ONLY=true` to only report violations while you adapt,
and optionally `CSP_REPORT_URI` to collect the reports.

## Fresh installs: admin account

On the first start the image creates an admin account. Without configuration
its email is `admin@example.com` and its password is random; it is printed once
in the container log. To choose them yourself, set before the first start:

```
ADMIN_EMAIL=you@example.com
ADMIN_PASSWORD=a-long-secret
```

Existing installations are not affected: the database is only seeded when it is empty.

## Docker image

The image moved from `riggraz/astuto` (Docker Hub) to
`ghcr.io/nkoeberlein/astuto-evo` and is available for amd64 and arm64.
Update the `image:` line of the `web` service accordingly.
