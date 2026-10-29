# Changelog

All notable changes to Astuto Evolution. Versions follow [Semantic Versioning](https://semver.org).
Issue numbers refer to the archived [astuto/astuto](https://github.com/astuto/astuto) repository.

## [Unreleased]

### Removed
- **The old user interface** (React 16, Redux, Bootstrap, Turbolinks, webpack, Sass and the asset pipeline) and its JSON endpoints (`/posts`, `/boards`, `/posts/:id/comments`, `/likes`, `/follows`, `/post_status_changes`, `/users`, `/webhooks`, `/o_auths` CRUD, `/tenants`, `/invitations`, `/api_keys`). Integrations should use the REST API (`/api/v1`, API key) or MCP. Node.js is only needed to build `frontend/`.
- Self-service sign-up for new feedback spaces (it was switched off); see docs/multi-tenancy.md.
- `GET /users/send_set_password_instructions`, which sent password reset emails to any address without rate limit.
- **Billing.** Astuto Evolution has no paid plans: the Stripe billing of the former astuto.io hosting is gone (billing pages, trial period, read-only mode after the trial, trial and subscription emails, `stripe` gem, `STRIPE_*` and `TRIAL_PERIOD_DAYS` variables). The table `tenant_billings` is dropped. The Content Security Policy no longer allows Stripe.
- The astuto.io promo banner and the call to the astuto.io certificate API when a custom domain is saved (`ASTUTO_CNAME_API_URL`, `ASTUTO_CNAME_API_KEY`).

### Changed
- Emails are sent from `EMAIL_MAIL_FROM` or, without it, `noreply@<host of BASE_URL>` (before: `noreply@astuto.io`, the discontinued hosted service). `EMAIL_MAIL_REPLY_TO` defaults to the sender.
- **The new user interface replaces the old one at `/`.** Every page – boards, posts, roadmap, embedded roadmap, login, sign-up, password reset, profile, moderation and site settings – comes from the v2 frontend. `/next/...` redirects to `/...` (301), and the Devise pages `/users/sign_in`, `/users/sign_up`, `/users/password/new|edit` and `/users/edit` redirect to the new pages, keeping their notices (e.g. after confirming an email). See UPGRADING.md for custom CSS.
- The Capybara system specs of the old UI are gone; Playwright end-to-end tests cover the new pages, including a Content Security Policy check in the browser console.

### Security
- Private feedback spaces: votes (`/posts/:id/likes`), status history (`/posts/:id/post_status_changes`) and the embedded roadmap (`/embedded_roadmap`) were readable without logging in. They now require a login like the rest of the space.
- Comments, votes and status history of posts waiting for approval or rejected were readable by everyone; like the post itself, they are now visible to moderators only.
- Legacy webhook endpoints `PUT /webhooks/:id/test` and `PUT /webhooks_preview` checked no permissions: anyone, even without an account, could fire a feedback space's webhooks with test data and read the target's response. Both now require an admin.

### Features
- **GDPR tools** (docs/privacy.md): people download their data in Profile settings › My data; admins download or delete (anonymize) any account in Moderation › Users. A daily job removes unconfirmed sign-ups after 30 days, sign-in IPs after 90 days and unaccepted invitations after 180 days (`*_RETENTION_DAYS`; `bin/rails astuto:purge_expired_data` without Sidekiq). Gravatar avatars can be switched off in Site settings › General (they send a hash of the email address to gravatar.com); initials show instead.
- **Audit log** (Site settings › Audit log, admins): who changed what in moderation (posts, comments, users), boards, statuses, site settings, sign-in providers, webhooks, invitations and API keys, with old and new values, source (UI, REST API, MCP) and IP. Secrets are never stored. Entries are kept for `AUDIT_LOG_RETENTION_DAYS` (default 365). `GET /api/app/v1/site_settings/audit_events`.
- Operations (docs/operations.md): `/health/live` and `/health/ready` probes, Prometheus metrics at `/metrics` (with `METRICS_TOKEN`), a backup and restore guide, and a Helm chart (`deploy/helm/astuto-evolution`) with an optional Sidekiq worker. The production image runs a command you pass (`bundle exec sidekiq` for a worker) after preparing the database, and containers starting at the same time prepare it one after another.
- New pages to request the email confirmation or account unlock link again (`/confirmation/new`, `/unlock/new`, linked from the login page; `POST /api/app/v1/confirmation` and `/api/app/v1/unlock`). Links in emails keep working and land there on errors (expired or already used).
- Multi-tenancy is documented (docs/multi-tenancy.md): DNS, TLS, custom domains. Instance admin page at `/instance` on the `BASE_URL` host (#76, protected by `INSTANCE_ADMIN_PASSWORD`): list, create, edit, block and delete feedback spaces; `bin/rails tenants:create|list|block|unblock` does the same from the command line. `/custom_domain_check` answers Caddy's on-demand TLS, so certificates for custom domains come automatically. The custom domain hint names this instance instead of `cname.astuto.io`.
- Webhooks are signed: every request carries `X-Astuto-Signature` (HMAC-SHA256 of timestamp and body with a per-webhook secret), `X-Astuto-Timestamp` and `X-Astuto-Event`. Existing webhooks got a secret during the update; receivers can start checking whenever they like. See docs/webhooks.md.
- Webhook delivery log (#458): the newest 50 runs per webhook with status, HTTP code, duration and the template, JSON or network error, under Site settings › Webhooks › Deliveries. Requests time out after 15 seconds.
- Site settings › General › Emails: **Send test email** checks the email configuration and shows the server's error (e.g. SMTP authentication) right away, even with `EMAIL_RAISE_DELIVERY_ERRORS=false`.
- OAuth providers can send extra headers with the profile request, e.g. the `User-Agent` GitHub requires or a `Client-Id` (#485). An own `Authorization` header replaces the default bearer token. Set them in Site settings › Authentication.
- v2 frontend is ready for right-to-left languages: `lang` and `dir` come from the feedback space's language (also in the server-rendered HTML, so the page never flips after loading), the last left/right utilities became logical ones, and directional icons mirror.
- End-to-end tests for the v2 frontend with Playwright (`frontend/e2e`, `npm run e2e`): public pages, embedding, login, settings, moderation and profile pages, the admin journey from a new board to a comment, and anonymous feedback through the approval queue. They run in CI against the production container.
- v2 frontend: profile settings at `/next/profile` (click your name in the header): name, email, password, notifications and recap frequency, API key for moderators, deleting the account. Name and notifications no longer need the current password; email, password and deleting the account still do. Accounts created via OAuth can request a password first. The owner cannot delete their own account (the feedback space would have no owner). New endpoints `GET/PATCH/DELETE /api/app/v1/profile` and `POST /api/app/v1/profile/api_key`.
- v2 frontend: site settings › Invitations at `/next/site_settings/invitations`: invite up to 20 people at once, send a test email to yourself, see which invitations are pending, accepted or expired. Links lead to the v2 sign-up page. The limit and the `%link%` placeholder are now checked on the server too (`SendInvitationsWorkflow`, shared with the legacy UI). With this, every site settings section exists in the v2 frontend.
- v2 frontend: site settings › Webhooks at `/next/site_settings/webhooks`: create, edit, switch on or off, delete; headers as key/value rows; template variables of the chosen trigger insert at the cursor; preview renders URL and body with example data and explains JSON errors; the test button sends the saved webhook and shows status and response. New endpoints under `/api/app/v1/site_settings/webhooks` (including `variables`, `preview`, `:id/test`); the variables per trigger now live in one place in the backend.
- v2 frontend: site settings › Authentication at `/next/site_settings/authentication`: email registration rules (everyone, certain domains, nobody) and OAuth providers – create, edit, switch on or off, test in a popup, copy the callback URL, delete; default providers of the instance can be switched on or off per feedback space. The client secret is never sent to the browser; leaving it empty when editing keeps the current one. New endpoints under `/api/app/v1/site_settings/o_auths`.
- v2 frontend: site settings › Appearance at `/next/site_settings/appearance`: custom CSS with live preview before saving (`customCss` in `GET/PATCH /api/app/v1/site_settings/general`).
- v2 frontend: site settings › Roadmap at `/next/site_settings/roadmap`: move statuses into or out of the roadmap, and build the embed code for `/next/embedded_roadmap` (filters, boards, statuses) with a copy button.
- v2 frontend: site settings › Boards and › Statuses at `/next/site_settings/boards` and `/next/site_settings/post_statuses` (admins): create, edit (boards with their URL slug, statuses with color and roadmap flag), delete after a confirmation, and reorder with up/down buttons that also work with the keyboard. New app API endpoints: `POST/PATCH/DELETE /api/app/v1/boards(/:id)`, `PUT /api/app/v1/boards/reorder`, and the same for `/api/app/v1/post_statuses`.
- v2 frontend: site settings › General at `/next/site_settings/general` (admins): name, logo, favicon, language, root page, default sorting, privacy, moderation rules, OAuth-only login, header, email logo size and visibility options, with a warning before leaving unsaved changes. Admins reach it through a settings icon in the header; the other settings sections still open in the legacy UI. New endpoints `GET/PATCH /api/app/v1/site_settings/general`.
- v2 frontend: user moderation at `/next/moderation/users` – search by name or email, filter by role and status, block and unblock (moderators), change roles (admins). Same rules as the legacy UI: nobody changes themselves or the owner, moderators only manage users. Unlike the legacy list, the server searches and pages through the users (50 at a time). New endpoints `GET /api/app/v1/moderation/users` and `PATCH /api/app/v1/moderation/users/:id`.
- v2 frontend: feedback moderation at `/next/moderation/feedback` – posts waiting for approval and rejected posts, approve or reject with one click. Moderators get a moderation link in the header with the number of pending posts. New endpoint `GET /api/app/v1/moderation/posts`; the session tells moderators the pending count (`pendingPostsCount`).
- v2 frontend: embeddable roadmap at `/next/embedded_roadmap` for an iframe on another site, without header and footer; posts open in a new tab. It takes the legacy embed parameters (`show_boards`, `show_statuses`, `show_board_filter=false`, `show_status_filter=false`), so existing embed codes keep working after the switch from `/next` to `/`. Only this page may be framed by other sites, and only while the roadmap is enabled.

### Fixes
- `REDIS_PASSWORD` was inserted into `REDIS_URL` at a fixed position, which broke `rediss://` URLs and passwords with special characters.
- OAuth login on a custom domain failed silently, because the provider calls back on the subdomain where the browser has no login state cookie (#472). The callback now continues on the custom domain. The cookie no longer uses the parent domain of the request (which broke on hosts like `feedback.example.co.uk`), and a callback with an unknown state shows the login page with an error instead of crashing.
- The pages for pending and blocked feedback spaces crashed (500); they now render without the old interface.
- Multi-tenancy: feedback spaces were not found when the `BASE_URL` host had more than two labels (`acme.feedback.example.com`, `feedback.example.co.uk`), because the subdomain depended on Rails' `tld_length`. The subdomain is now everything in front of the `BASE_URL` host, also behind a proxy (`X-Forwarded-Host`). Cookies for OAuth logins are set for the `BASE_URL` host instead of its parent domain.
- Multi-tenancy: custom domains with top-level domains longer than six letters (`.solutions`, `.community`) were rejected, and with `RAILS_HOSTS` set, every custom domain had to be listed there too. They are now allowed automatically.
- "Use browser language" had no effect on the new interface and the app API.
- German: every text of the new interface is translated now (about 100 entries were English or missing), including invitation emails and recap subjects (#466).
- The reply field under a comment was labelled with its raw translation key for screen readers.
- The general settings page counted as changed right after loading when the header links came back from the database with their keys in another order.
- Webhooks set to PUT, PATCH or DELETE were always sent as POST.
- After saving a webhook, the legacy UI got its URL and headers back encrypted.

## [2.0.0-alpha.3] – 2026-10-26

Image: `ghcr.io/nkoeberlein/astuto-evo:2.0.0-alpha.3` (amd64 + arm64).

### Security
- The legacy UI no longer hands visitors the email addresses of authors, voters and moderators; they get a Gravatar hash instead. Moderators and the person themselves still see the email.
- Account lockout: sign-in with email and password now uses Devise `:lockable`, so a single account locks after too many failed attempts – effective against distributed brute-force, independent of the IP-based anti-spam rules. Unlock happens via emailed link and/or after a configurable time (`LOCKABLE_LOCK_STRATEGY`, `LOCKABLE_UNLOCK_STRATEGY`, `LOCKABLE_MAXIMUM_ATTEMPTS`, `LOCKABLE_UNLOCK_IN_HOURS`; defaults: 10 attempts, 2 h, both). See docs/account-lockout.md.
- Rate limits for brute-force-sensitive endpoints: `/mcp` (per IP and per API key) no longer runs into the general request limit, and logins – the legacy form and `POST /api/app/v1/session` – are throttled by IP and by email.
- API keys only work while their user is an active moderator; keys are removed on any demotion (admin → user counts) and on blocking.
- Fresh installs no longer start with the password `password`: outside development the admin gets a random password, printed once in the log, or the one from `ADMIN_PASSWORD` (`ADMIN_EMAIL` sets the email).
- Content Security Policy: scripts only from the instance itself, Stripe (hosted billing) or with a nonce. `CSP_REPORT_ONLY=true` switches to report-only. See UPGRADING.md.
- `SECURITY.md`: report vulnerabilities privately via GitHub.

### Features
- v2 frontend: login, sign-up and password reset pages under `/next`, with OAuth buttons and the legacy rules (registration policy, allowed email domains, invitations, email confirmation, OAuth-only login). Locked accounts show the lockout warning, the last failed attempt before it.

### Fixes
- `/next` and `/next/` were served as a static file, without the server-side meta tags.
- Gravatar images in the legacy UI loaded over plain `http` on `http` pages.
- The app API anti-spam measures the form fill time client-side (`formFillMs` via `performance.now()`) instead of a browser-sent timestamp, so a clock a few seconds ahead no longer rejected people who took their time.

## [2.0.0-alpha.2] – 2026-10-25

Fixes fresh installs. Use this instead of 2.0.0-alpha.1.
Image: `ghcr.io/nkoeberlein/astuto-evo:2.0.0-alpha.2` (amd64 + arm64).

### Fixes
- A fresh install was migrated but not seeded (no tenant, no admin), so every page returned an error. The entrypoint compared the whole `db:version` output, which since Rails 7.1 also contains the database name. Upgrades of existing installations were not affected.
- The production image now sets `RAILS_ENV=production`, so migrations and seeds in the entrypoint use the production configuration like the server
- CI checks that a fresh install comes up seeded

## [2.0.0-alpha.1] – 2026-10-25

First alpha of Astuto Evolution, the community continuation of Astuto 1.x.
Image: `ghcr.io/nkoeberlein/astuto-evo:2.0.0-alpha.1` (amd64 + arm64).
Upgrading from 1.x: read [UPGRADING.md](UPGRADING.md) and back up your database first.

### Platform
- Ruby 3.0 → 4.0.9, Rails 6.1 → 8.1.4 (framework defaults 8.1), Devise 5, Puma 8, Sidekiq 8.1 (needs Redis ≥ 7), Stripe 20 with pinned API version
- Debian 13 trixie base image; the runtime image no longer contains Node.js
- Multi-arch image (amd64 + arm64) on GitHub Container Registry instead of `riggraz/astuto`
- PostgreSQL 18 recommended (14 reaches end of life on 12.11.2026); upgrade steps in UPGRADING.md
- Existing sessions and "remember me" cookies stay valid after the upgrade

### Operations
- `ASSUME_SSL` / `FORCE_SSL` for reverse proxies, correct `https` OAuth callbacks (#478, #201)
- `POSTGRES_DB` separate from `POSTGRES_USER`, optional `DATABASE_URL` (#326, #207)
- SMTP verifies TLS certificates by default; custom CA certificates via volume (#330, #203)
- Devise mails go through ActiveJob; delivery errors are always logged; a broken SMTP setup no longer locks users out when changing their email (#444, #476)
- Comment notifications work again (#431); all Sidekiq queues configured
- Webhooks: template errors are reported when saving, testing and running; URLs and headers are re-encrypted in a portable JSON format (#458)
- OAuth state cookie works without subdomain tenancy, `secure` and `SameSite=Lax` (#472)

### Features
- New user interface (preview under `/next`): boards with search, sorting and status filter, post page with comments and replies, voting, following, roadmap, editing and moderation of posts and comments; dark mode, mobile layout, server-side meta tags
- App API `/api/app/v1` (session + CSRF, OpenAPI documented) for the new interface
- MCP server under `/mcp` on the official MCP Ruby SDK: search, read, create and triage posts from Claude, Cursor and other assistants (moderator API key)
- Opt-in AI discussion summary for moderators (`AI_PROVIDER`, `AI_MODEL`; OpenAI-compatible, Ollama, Anthropic)
- Full-text search and duplicate suggestions while writing a post (#455)
- Quick wins: roadmap can be turned off (#361), default sorting (#193, #363), login only via OAuth (#471), custom favicon (#452), mail logo size (#474), custom header links (#479, #351), status selection when creating a post (#119), warning before leaving unsaved settings (#106)
- Translations enabled: Turkish, Czech, Greek, Hindi, Dutch, Polish, Serbian, Swedish

### Fixes
- Pending feedback counter and comment count after deleting replies (#445, #220)
- Creating and updating posts is atomic with follow and status history (#169)
- User search in Site Settings › Users (#159)
- Custom CSS can no longer close its `<style>` tag (#468)
- Header and logo links only accept `http(s)`, `mailto` and site paths
- Anti-spam check for new posts no longer fails with an error on incomplete requests

### Known limitations of this alpha
- Login, registration, moderation queue and Site Settings still use the old interface; the new one lives under `/next`
- The old JSON endpoints still return author email addresses (fixed in the new app API)
- The seeded admin account uses `admin@example.com` / `password`: change it right away
- No Content Security Policy yet; PostgreSQL 19 support follows its release (19.11.2026)
- AI board/tag suggestions, changelog drafts and translation are not wired yet
