# Changelog

All notable changes to Astuto Evolution. Versions follow [Semantic Versioning](https://semver.org).
Issue numbers refer to the archived [astuto/astuto](https://github.com/astuto/astuto) repository.

## [2.0.0-alpha.1] – 2026-10-25

First alpha of Astuto Evolution, the community continuation of Astuto 1.x.
Image: `ghcr.io/nkoeberlein/astuto:2.0.0-alpha.1` (amd64 + arm64).
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
