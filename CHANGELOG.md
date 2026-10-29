# Changelog

All notable changes to Astuto Evolution. Versions follow [Semantic Versioning](https://semver.org).
Issue numbers refer to the archived [astuto/astuto](https://github.com/astuto/astuto) repository.

## [Unreleased]

### Features
- v2 frontend: site settings › Roadmap at `/next/site_settings/roadmap`: move statuses into or out of the roadmap, and build the embed code for `/next/embedded_roadmap` (filters, boards, statuses) with a copy button.
- v2 frontend: site settings › Boards and › Statuses at `/next/site_settings/boards` and `/next/site_settings/post_statuses` (admins): create, edit (boards with their URL slug, statuses with color and roadmap flag), delete after a confirmation, and reorder with up/down buttons that also work with the keyboard. New app API endpoints: `POST/PATCH/DELETE /api/app/v1/boards(/:id)`, `PUT /api/app/v1/boards/reorder`, and the same for `/api/app/v1/post_statuses`.
- v2 frontend: site settings › General at `/next/site_settings/general` (admins): name, logo, favicon, language, root page, default sorting, privacy, moderation rules, OAuth-only login, header, email logo size and visibility options, with a warning before leaving unsaved changes. Admins reach it through a settings icon in the header; the other settings sections still open in the legacy UI. New endpoints `GET/PATCH /api/app/v1/site_settings/general`.
- v2 frontend: user moderation at `/next/moderation/users` – search by name or email, filter by role and status, block and unblock (moderators), change roles (admins). Same rules as the legacy UI: nobody changes themselves or the owner, moderators only manage users. Unlike the legacy list, the server searches and pages through the users (50 at a time). New endpoints `GET /api/app/v1/moderation/users` and `PATCH /api/app/v1/moderation/users/:id`.
- v2 frontend: feedback moderation at `/next/moderation/feedback` – posts waiting for approval and rejected posts, approve or reject with one click. Moderators get a moderation link in the header with the number of pending posts. New endpoint `GET /api/app/v1/moderation/posts`; the session tells moderators the pending count (`pendingPostsCount`).
- v2 frontend: embeddable roadmap at `/next/embedded_roadmap` for an iframe on another site, without header and footer; posts open in a new tab. It takes the legacy embed parameters (`show_boards`, `show_statuses`, `show_board_filter=false`, `show_status_filter=false`), so existing embed codes keep working after the switch from `/next` to `/`. Only this page may be framed by other sites, and only while the roadmap is enabled.

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
