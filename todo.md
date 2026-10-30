# TODO – Astuto Evolution

Priorities: **P0** = blocking or security · **P1** = important bugs and operations · **P2** = improvements and quick wins · **P3** = later / nice to have
Issue numbers refer to `astuto/astuto`. See [roadmap.md](roadmap.md) for the phases.

## P0 – Take over the fork and secure the platform

### Setup
- [x] Check the local setup: the original image no longer built (Debian 11 EOL). After the Ruby 3.3 upgrade: 374 tests, 2 failures (UserMailer, keyword arguments under Rails 6.1 + Ruby ≥ 3.2, fixed with Rails 7.0)
- [x] Rename `spec/system/user_o_auth_sign_up_and_log_in.rb` to `…_spec.rb` (it never ran); same for `spec/requests/posts_controller_test.rb` and `post_statuses_controller_test.rb`, adapted to the current behaviour. The OAuth system spec could not be checked locally (no Chromium in the dev container) and only runs in CI
- [ ] Local port 3000 is occupied by an SSH tunnel here; `docker-compose.override.yml` maps the app to `:3005`
- [x] Point `.github/workflows/push-to-registry.yml` at GHCR (`ghcr.io/nkoeberlein/astuto`), remove `riggraz/astuto`
- [x] `run-tests.yml`: runner `ubuntu-24.04`
- [x] README and CONTRIBUTING rewritten as Astuto Evolution, links to `nkoeberlein/astuto`
- [ ] Treat the remote `upstream` as an archive only; save the upstream branch `add-image-upload`
- [x] Matched open upstream issues (25.10.2026): all are in the todo or roadmap, except #165 (authenticityToken props, moot with the old frontend) and #451 and #465 (empty). Gaps against the competition and deliberate exclusions: roadmap.md §1 and phases 4/5

### Adopt upstream PRs
- [x] #477 Gravatar avatar fix (1 line)
- [x] #470 `config/initializers/hosts.rb` with `RAILS_HOSTS` (review, merge with the phase-2 proxy configuration)
- [x] #460 User search in Site Settings › Users (closes #159). Reworked: the list was not filtered, the backend filter was broken
- [x] #463 Turkish translation (file adopted, language not selectable yet, see P2)
- [x] #459 `serialize-javascript` 6.0.2

### Platform upgrade
- [x] Ruby 3.0.6 → 3.3.13, Debian 11 → 13 trixie (`.ruby-version`, `Gemfile`, `Dockerfile` ×2) (#456)
- [x] Rails 6.1 → 7.0 → 7.1 → 7.2 → 8.0 → 8.1.4, each step with 374/0 tests and no deprecations
- [x] Devise 5.0.4 (Rails-8 lazy routes, CVE fixes), Spring removed, Puma 8, factory_bot 6, debug instead of byebug
- [x] `Rails.application.secrets` replaced; `SECRET_KEY_BASE` remains the source in all environments (webhook encryption, API keys, Devise tokens unchanged)
- [x] Ruby 3.3 → 4.0.9 (Bundler 4.0.20), 374/0 tests
- [x] `load_defaults` 6.1 → 7.0 → 7.1 → 7.2 → 8.0 → 8.1, each step with the full suite green. Cookie rotation (SHA1 → SHA256) keeps sessions and remember-me cookies valid (verified with real old cookies), `allow_other_host` for tenant, OAuth and billing redirects, Active Storage disabled. Side effect: the test environment reloaded code whenever the dev server wrote files (sporadic `AssociationTypeMismatch`), now `enable_reloading = false`
- [x] Sidekiq 8.1.7 and `connection_pool` 3 without a pin: `react-rails` 3.3 no longer hangs on connection_pool (npm `react_ujs` stays 2.6 because 3.x pulls in React 18). `config/sidekiq.yml` with all queues — before this, webhook jobs never ran without `-q webhooks`. Verified with Redis 8
- [x] Stripe gem 11 → 20 with the pinned API version `2024-04-10` (the webhook reads `price` on invoice line items, which is missing since 2025-03-31). Higher versions only with a test against a Stripe test account
- [x] `i18n-js` removed (with the old frontend)
- [x] `bundler-audit`, `brakeman` and `bin/ci` (gem audit, yarn audit, Brakeman, RSpec, seeds), the same checks in the test workflow. 6 transitive gems with vulnerabilities updated (nokogiri, rails-html-sanitizer, loofah, crass, addressable, concurrent-ruby)
- [x] Upgrade note: Sidekiq 8 needs Redis ≥ 7 (in `UPGRADING.md`)
- [x] Node 20 → 24 LTS in the Dockerfile (builder)
- [x] Node 26 (builder, compose service, frontend CI); runtime image without Node at all (Debian's Node 20 was EOL and not needed)
- [x] `yarn audit` without critical findings (old UI: 15 high, 17 moderate, 4 low; moot with its removal), verified via `bin/yarn-audit-critical`
- [ ] **Urgent (PG 14 EOL 12.11.2026):** PostgreSQL 14.5 → 18 (#247): dev compose runs on `postgres:18-trixie` (fresh volume; the 19rc1 dev volume was discarded, dev data was scratch), guide in `UPGRADING.md` (dump/restore tested). Open: the GA of PG 19 is announced for **19.11.2026**, one week after PG 14's EOL. Then switch to `postgres:19-trixie` (same steps, see `UPGRADING.md`)
- [x] Docker multi-arch build amd64 + arm64 with `docker/build-push-action` + QEMU (#399, #254, #475), running green in CI since 2.0.0-beta.1
- [x] Dependabot: Bundler, npm (frontend; old UI only security updates), Docker, compose, Actions; minor/patch grouped. Enable "Dependabot security updates" in the repository settings

### Security
- [x] Old read endpoints: votes, status history and the `/embedded_roadmap` of private spaces were readable without login; comments, votes and status history of unapproved posts were readable by everyone. Now login required or moderators only (`hide_unless_post_visible`, `spec/requests/legacy_read_access_spec.rb`)
- [x] Webhook test and preview of the old UI (`PUT /webhooks/:id/test`, `PUT /webhooks_preview`) checked no permissions: anyone, even without an account, could fire webhooks and read the target's response; now admins only (`spec/requests/webhooks_authorization_spec.rb`)
- [x] **Prerequisite for v3:** webhook URL/headers encrypted as JSON instead of Marshal (`Webhook.encryptor`, reads both formats), migration `ReencryptWebhooksAsJson` rewrites existing values
- [x] **Privacy:** the old JSON endpoints (comments, likes, status history, post page) exposed `user_email` of all authors publicly. Now only for moderators and the person themselves, otherwise the Gravatar hash (`Legacy::AuthorFields`); the new app API via `AuthorSerializer`
- [x] Default admin: `ADMIN_EMAIL` / `ADMIN_PASSWORD`; without a password outside development a random one is generated and logged once (`DefaultAdminCredentials`)
- [x] SMTP default `openssl_verify_mode: "none"` → `"peer"` (`config/environments/production.rb`)
- [x] Header links and the logo link: only `http(s)`, `mailto` and paths allowed (`SafeUrl`, validated in `TenantSetting`); before, a `javascript:` link could be stored that the old header rendered
- [x] `rack-attack` anti-spam for `/posts` crashed with `TypeError` on missing fields (500); a missing timestamp now counts as spam
- [x] App API spam protection (`POST /api/app/v1/boards/:id/posts`) aligned with the old UI: a filled honeypot blocks the IP for an hour on both endpoints (`/posts` and the app API); submitting too fast (`formFillMs` < 2 s, measured in the browser) is rejected only by the controller with 422 (`config/initializers/rack_attack.rb`, `PostSpamCheck`, `spec/requests/rack_attack_spec.rb`)
- [x] Content Security Policy active: scripts only from the instance, from Stripe or with a nonce; `CSP_REPORT_ONLY` as a safety valve; a system spec checks the browser console. Fixed on the side: `/next` was served as a static file past the `SpaController` (no meta tags), Gravatar images loaded over `http`
- [x] Rate limiting made concrete: `/api/v1` (`api/ip`, `api/key`), `/mcp` (`mcp/ip` 60/min, `mcp/key` 120/min) and the app API auth endpoints (`/api/app/v1/session`, `/api/app/v1/registration`, `/api/app/v1/password`) secured against brute force; `logins/email` also reads `user[email]` for Devise forms and JSON bodies (`config/initializers/rack_attack.rb`)
- [x] Short security review (`rack-attack` rules, API key handling): API tokens hashed with SHA-256 in cache keys; `Api::BaseController` checks `user.active? && user.moderator?`; `Api::V1::UsersController#block` and `DestroyApiKeyIfNeededWorkflow` delete API keys reliably also when blocking via the API, on a direct `admin → user` demotion and on simultaneous role and status changes (`spec/models/api_key_spec.rb`, `spec/api/v1/users_spec.rb`)
- [x] Account lockout: added Devise `:lockable` (stops brute force per account, independent of rack-attack), thresholds configurable via ENV (`LOCKABLE_LOCK_STRATEGY`/`LOCKABLE_UNLOCK_STRATEGY`/`LOCKABLE_MAXIMUM_ATTEMPTS`/`LOCKABLE_UNLOCK_IN_HOURS`, defaults: 10 attempts, 2 h, "both" = unlock email + time); the app API login now counts failed attempts too (`valid_for_authentication?`), `UnlocksController` loads tenant data, documented in [docs/account-lockout.md](docs/account-lockout.md)

## P1 – Operations and bugs

### Reverse proxy / HTTPS
- [x] Make `config.assume_ssl` and `config.force_ssl` configurable via ENV (since Rails 7.1) (`ASSUME_SSL`, `FORCE_SSL`)
- [x] The OAuth `callback_url` must deliver `https` behind the proxy (#478)
- [x] "The change you wanted was rejected" behind the proxy (CSRF/origin): reproduce and fix (#201) (`ASSUME_SSL=true` + proxy headers)
- [x] Docs: example configurations for nginx, Caddy and Traefik (incl. `X-Forwarded-Proto`) in [docs/reverse-proxy-and-smtp.md](docs/reverse-proxy-and-smtp.md)

### OAuth
- [x] The `token_state` cookie (#472) in `app/controllers/o_auths_controller.rb`: set `domain: ".#{request.domain}"` only with subdomain tenancy, otherwise omit; add `secure: request.ssl?` and `same_site: :lax`; spec for it (`spec/requests/o_auths_cookie_spec.rb`)
- [x] Own CA certificates / self-signed via volume + `update-ca-certificates` in the entrypoint (#203)
- [x] Configurable headers for the profile API call (#485): `o_auths.profile_headers` (jsonb), a custom `Authorization` header replaces the bearer token, header rows in the OAuth form (`HeaderRows`, also for webhooks)

### Email
- [x] "Send test email" (Site Settings › General › E-Mails, `POST /api/app/v1/site_settings/test_email`): sends to the admin immediately, reports SMTP errors directly, even with `EMAIL_RAISE_DELIVERY_ERRORS=false`
- [x] Always log delivery errors, even when `EMAIL_RAISE_DELIVERY_ERRORS=false` (`config/initializers/mailer_logging.rb`)
- [x] SMTP docs with working examples (SES, Brevo, SMTP2GO, Exchange; note on `EMAIL_SMTP_AUTH=login`) (#330, #446, #294, #385) in [docs/reverse-proxy-and-smtp.md](docs/reverse-proxy-and-smtp.md)
- [x] Changing the email with broken SMTP must not lock the user out (#476) (`skip_reconfirmation!` without configured SMTP in production)
- [x] Send Devise mails via ActiveJob/Sidekiq (#444) (`User#send_devise_notification`)

### Webhooks
- [x] Webhooks signed with HMAC: `X-Astuto-Signature: sha256=HMAC(secret, "<timestamp>.<body>")`, `X-Astuto-Timestamp`, `X-Astuto-Event`; secret per webhook (encrypted, rotatable), existing webhooks via migration; verification guide in [docs/webhooks.md](docs/webhooks.md)
- [x] Delivery log per webhook (#458): `webhook_deliveries` (last 50), status, HTTP code, duration, Liquid/JSON/network error or start of the response; in the UI under Webhooks › Deliveries; timeout 15 s
- [x] Validate the template on save and test, point to `escape_json` (`WebhooksController#preview/test`, `RunWebhook`)
- [x] Fix comment notifications (#431) (`config/initializers/global_id.rb`, `SendNotificationForCommentWorkflow`)

### Configuration
- [x] `POSTGRES_DB` separate from `POSTGRES_USER` (`config/database.yml`) (#326)
- [x] Document and test `DATABASE_URL` / an external Postgres instance (#207)

### Smaller bugs
- [x] The counter for pending posts does not update when approving or rejecting (#445) (`FeedbackModerationP.tsx`)
- [x] Comment counter wrong after deleting a comment with replies (#220) (`commentsReducer.ts`)
- [x] Custom CSS: special characters get HTML-escaped (#468) (`app/views/layouts/application.html.erb`)
- [x] Missing translation keys (#466): spec `spec/i18n/frontend_translation_keys_spec.rb` checks every static `t('...')` key of the frontend against English (found `post.new_comment.placeholder`); German complete (~100 English or missing entries translated). Other languages fall back to English until the translation platform exists
- [x] "Edit/delete post" (#210): the Capybara spec is gone with the old UI; the Playwright admin flow now edits and deletes a post

### Multi-tenancy and SaaS parts (decided: multi-tenancy stays)
- [x] Multi-tenancy mode tested in the browser (two tenants on `*.astuto.test`: separation of data, sessions, logins, custom domain) and documented (`docs/multi-tenancy.md`). Fixed along the way: the subdomain hung on `tld_length` (broken for `BASE_URL` hosts with more than two parts), custom domains with long TLDs rejected and blocked by `RAILS_HOSTS`, browser language ignored by the new frontend
- [x] Decision: **no billing.** Stripe billing, trial, billing emails (`TenantMailer`), the `tenant_billings` table and the `stripe` gem removed
- [x] astuto.io-specific parts removed: the promo banner, the certificate API `ASTUTO_CNAME_API_*` (replaced by `/custom_domain_check` for Caddy's on-demand TLS), the CNAME note on `cname.astuto.io`, the contact address on the "confirm email" page
- [x] Mailer default sender: `EMAIL_MAIL_FROM`, otherwise `noreply@<host from BASE_URL>` (`Rails.application.default_mail_from`); reply-to falls back to the sender
- [x] Manage tenants via rake: `bin/rails tenants:create|list|block|unblock`
- [x] OAuth login on custom domains (#472): the callback on the subdomain redirects to the same callback of the custom domain without the cookie (the browser binding stays); cookie domain from the `BASE_URL` host instead of `request.domain`, host-only on custom domains; a wrong `state` leads to the login page instead of a 500. Verified in the browser with a mock IdP
- [x] Unused translation keys of the old frontend removed (52 keys in all 19 languages, ~1,100 lines; they went to the browser with `/api/app/v1/translations`)
- [x] Instance admin interface for tenants (#76): `/instance` on the `BASE_URL` host, HTTP Basic with `INSTANCE_ADMIN_PASSWORD` (users belong to one tenant each, there is no instance account), server-side rendered without JavaScript; create (the owner's password is shown once), change name/domain/language, block, delete with confirmation. Shared logic with the rake task in `CreateTenantWorkflow`

### Mid-size companies (roadmap.md section 7)
- [x] SAML 2.0 (`docs/sso.md`, `ruby-saml` 1.18): SP metadata, signed responses, InResponseTo binding, nonce against login CSRF (the ACS POST arrives without a session cookie, completed via a short-lived token on the start host), account optional at first login, 2FA afterwards; metadata import without a URL fetch; verified in the browser with a mock IdP. "SSO only" via the existing "login only with OAuth" (#471)
- [x] LDAP/AD login (#8, `net-ldap`): search via a service account, password check by bind (empty password rejected up front), filter escaping (found along the way: `gsub` with a replacement string would have read `\\2a` as a backreference and undone the escaping), StartTLS/LDAPS with certificate validation, test search, login page with the company account first; verified against real OpenLDAP (`spec/fixtures/ldap`)
- [x] 2FA (`docs/two-factor-authentication.md`): TOTP with `rotp`, QR code as SVG (`rqrcode`, without JS), ten backup codes (digests only), secret encrypted; second login step after password and OAuth, codes valid only once, failed attempts count for the lockout; mandatory for staff via a site setting (app API 403, hint and redirect to the profile). Workarounds closed: the Devise HTML login and `PUT /users/password` (signed in without a code), password reset no longer signs in 2FA accounts
- [x] Audit log for moderation and settings: the `audit_events` table (actor, action, subject with a name snapshot, changed fields old/new, source app/REST API/MCP, IP; secrets filtered), recorded in the app API, REST API and MCP; page Site settings › Audit log with a filter by area; retention `AUDIT_LOG_RETENTION_DAYS` (365)
- [x] GDPR (`docs/privacy.md`): data export for the person themselves (profile › My data) and for admins (moderation › users), deletion/anonymization by admins (`User#anonymize!` now also removes IPs, OAuth tokens, followed posts), daily purge (`PurgeExpiredData`: unconfirmed accounts 30 days, IPs 90 days, invitations 180 days), Gravatar switchable (initials instead of images)
- [x] Operations (`docs/operations.md`): `/health/live` and `/health/ready` (DB, migrations, Redis; 503 with the failing checks), Prometheus endpoint `/metrics` with `METRICS_TOKEN` (counters per tenant, webhook errors, Sidekiq queues), backup/restore guide, Helm chart `deploy/helm/astuto-evolution` (web, optional Sidekiq worker, ingress, ServiceMonitor; checked in CI with `helm lint`, `helm template` and kubeconform). Plus: DB preparation at startup with an advisory lock (several containers at once), the prod entrypoint runs passed commands (`bundle exec sidekiq`), `REDIS_PASSWORD` was spliced into the URL at a fixed position (broken with `rediss://` and special characters)
- [x] FAQ "AGPL in companies" (`docs/agpl-faq.md`, linked from the README)

## P1 – Replace the old frontend (core of v2)

Recommendation (roadmap.md section 3): a separate frontend with React 19 + TS 7 + TanStack Router/Query + Tailwind 4 + shadcn/ui against a Rails JSON API, so it lives on in v3 (TanStack Start + Drizzle). Only keep the old frontend running in the meantime.

- [x] v3 stack decision: **TanStack Start + Drizzle + Tailwind** → separate React frontend in v2
- [x] App API `/api/app/v1` reads: `session`, `translations/:locale`, `boards`, `boards/:id/posts`, `post_statuses`, `posts/:id`, `posts/:id/comments` (rswag specs, OpenAPI `app/v1/openapi.yaml`, TS types generated)
- [x] `frontend/`: Vite 8, React 19, TS 7, TanStack Router + Query, Tailwind 4, shadcn/ui, Biome, Vitest; CI workflow `frontend.yml`
- [x] Served in the same image under `/next` (`SpaController`), compose service `frontend` for Vite
- [x] Write endpoints + UI: create post (anonymous, approval policy, honeypot + minimum time), vote (idempotent, optimistic), comment/reply (replies only within the same post), moderator update, follow; CSRF flow tested with the protection enabled
- [x] Edit/delete posts and comments, change status (moderation) in the new frontend (`PATCH/DELETE /api/app/v1/posts/:id`, `PATCH/DELETE /api/app/v1/posts/:post_id/comments/:id`, `PostPage.tsx`, `CommentList.tsx`)
- [x] Roadmap page (`/next/roadmap`, `GET /api/app/v1/roadmap`): columns per status, board and status filters in the URL, the start page without a root board shows the roadmap like the old UI
- [x] Embeddable roadmap (`/next/embedded_roadmap`) in the new frontend: without header/footer, posts in a new tab, the old parameters `show_boards`, `show_statuses`, `show_board_filter`, `show_status_filter`; only this page is framable by other sites (`SpaController`), and only when the roadmap is enabled
- [x] Login/sign-up/password as SPA pages (Devise JSON: `POST/DELETE /api/app/v1/session`, `POST /api/app/v1/registration`, `POST/PATCH /api/app/v1/password`), OAuth buttons (`/next/login`, `/next/register`, `/next/password/forgot`, `/next/password/reset`)
- [x] CI: regenerate the OpenAPI and compare with `frontend/src/api/schema.d.ts` (drift check in `run-tests.yml`, uses the OpenAPI file generated during the image build), running green in CI since 2.0.0-beta.1
- [x] Meta tags (title, description, Open Graph) for public pages set server-side in `SpaController` (`spec/requests/spa_meta_tags_spec.rb`)
- [x] `hide_unused_statuses_in_filter_by_status` and `custom_css` honoured in the new frontend (`GET /api/app/v1/post_statuses?board_id=`, `__root.tsx`)
- [x] Cutover `/next` → `/`: all pages via the `SpaController` (routes in `config/routes.rb`, named routes for mail links), `/next/*` → 301 to `/*`, Devise HTML pages redirect to the v2 pages (flash via `<meta name="astuto-flash">`), assets stay under `/next/assets`. Removed: the old page controllers (moderation, site settings, board/post page, roadmap) with views and Capybara system specs. Afterwards also into the new frontend or without JS: resend the confirmation and unlock links (`/confirmation/new`, `/unlock/new`, links in mails lead there on errors), the "pending"/"blocked" notice pages (own layout without JS, were broken with 500); only the disabled tenant sign-up remains
- [x] Design system: branding via CSS variables (existing site-settings colours), dark mode, WCAG 2.2 AA, mobile first, full screen area (2-column layout on desktop)
- [x] i18n: YAML translations via `GET /api/app/v1/translations/:locale`
- [x] RTL-ready: CSS logical properties only (also in shadcn `select`/`avatar`), `lang`/`dir` on `<html>` from the locale (server-side in `SpaController` and in the client, `textDirection()`), direction icons mirrored; checked with a forced `dir=rtl`. RTL translations are still missing
- [x] Public pages: board, post detail and comments, roadmap
- [x] Auth pages: login, sign-up, password, OAuth buttons (Devise with JSON endpoints)
- [x] Moderation › feedback queue (`/next/moderation/feedback`, `GET /api/app/v1/moderation/posts`): approve/reject pending and rejected posts, moderation link with a counter in the header (`pendingPostsCount` in the session)
- [x] Moderation › users (`/next/moderation/users`, `GET/PATCH /api/app/v1/moderation/users`): search by name/email, filter by role and status, block (moderators), roles (admins); rules from `UserPolicy`, filtered and paginated server-side (`ModerationUsersQuery`)
- [x] Site settings › General (`/next/site_settings/general`, `GET/PATCH /api/app/v1/site_settings/general`): all fields of the old tab, only changed fields are sent, warning on unsaved changes (`useBlocker`); gear icon in the header for admins, the remaining areas link into the old UI
- [x] Site settings › Boards and statuses (`/next/site_settings/boards`, `/next/site_settings/post_statuses`): create, edit, delete, sort with up/down buttons (keyboard accessible); app API `POST/PATCH/DELETE` and `PUT …/reorder` with the full ID list; shared `ListEditor`
- [x] Site settings › Roadmap (`/next/site_settings/roadmap`): statuses in/out of the roadmap, embed code for `/next/embedded_roadmap` with board/status selection and a copy button
- [x] Site settings › Appearance (`/next/site_settings/appearance`): custom CSS with live preview, saved via the General endpoint
- [x] Site settings › Authentication (`/next/site_settings/authentication`): email registration (policy, allowed domains) and OAuth providers (create, edit, on/off, test popup, copy callback URL, delete; default providers per tenant on/off); the client secret never leaves the server
- [x] Site settings › Webhooks (`/next/site_settings/webhooks`): CRUD, header rows, variables per trigger for insertion (the list now lives once in the backend: `CreateLiquidTemplateContextWorkflow::TEMPLATE_VARIABLES`), preview with a JSON error hint, test with status and response. Fixed along the way: PUT/PATCH/DELETE always went out as POST; after saving, URL and headers were shown encrypted in the form
- [x] Site settings › Invitations (`/next/site_settings/invitations`): up to 20 invitations, test to yourself, list with status; links to the v2 sign-up; sending in `SendInvitationsWorkflow` (also used by the old UI), the limit and `%link%` now checked server-side. With this, all site-settings areas are in the new frontend
- [x] Profile settings (`/next/profile`, `GET/PATCH/DELETE /api/app/v1/profile`, `POST …/api_key`): name, email, password, notifications, recap frequency, API key (moderators), delete account; the current password only for email, password and deletion; the owner cannot delete their own account
- [x] E2E tests with Playwright (`frontend/e2e`, `npm run e2e`): public pages, embed, login, all settings, moderation and profile pages, the admin flow (board → post → vote → comment) and anonymous feedback through approval; in `run-tests.yml` against the production container, running green in CI since 2.0.0-beta.1. The Capybara system specs could not run locally in the cloud session (chromedriver did not match the browser)
- [x] Old frontend removed: `app/javascript` (~200 files React 16/Redux), Sass/Bootstrap, Webpack, Sprockets, the gems `react-rails`, `i18n-js`, `turbolinks`, `jsbundling-rails`, `cssbundling-rails`, `sprockets-rails`, Capybara/Selenium; the old JSON controllers (boards, posts, comments, likes, follows, status history, users, webhooks, OAuth CRUD, tenants, invitations, API keys) with routes; the tenant sign-up; `yarn audit` in CI replaced by `npm audit` of `frontend/`. Along the way: `GET /users/send_set_password_instructions` sent reset emails to arbitrary addresses unchecked (removed); `sign_in_from_oauth_token` crashed on an invalid token
- [x] `app/controllers` reorganized: after removing the old UI 13 files at the top (Devise, OAuth, SPA, MCP, notice pages), the rest in `api/v1`, `api/app/v1` (with `moderation/`, `site_settings/`) and `instance_admin/`
- [x] Introduce RuboCop and run it in CI: own bundle `lint/Gemfile` (RuboCop's parser needs prism 1.x, the app has 2.0), `.rubocop.yml` only Lint, Security and some Rails/RSpec cops (no style, no mass reformatting before v3); all 51 findings fixed; `.github/workflows/lint.yml`, step in `bin/ci`
- [x] CI: work flows from `develop` branches via PRs against `main`; `run-tests.yml` runs on PRs and on pushes to `main`, `frontend.yml` also on pushes to `develop`
- [ ] TypeScript 7 also for `openapi-typescript` once supported (runs via `npx` with TS 5.9 until then)

## P3 – v3: full TypeScript (after 2.0)
- [x] Stack: TanStack Start + Drizzle + Tailwind (auth e.g. Better Auth)
- [x] License decision for v3: **AGPL-3.0 (stays)**, dual-licensed if needed; a CLA becomes necessary from the first v3 commit if a commercial license is added, see roadmap.md section 6
- [ ] GitHub structure (detach the fork, orphan branch or organization), see roadmap.md section 6
- [ ] New Drizzle schema (UUIDv7, auth tables, fractional indexing, timeline, merge, votes with weight, `tsvector`) and an automatic migrator v2 → v3 at startup (transaction, old tables into `v2_archive`)
- [ ] Replace the backend endpoint by endpoint (same API contracts as `/api/app/v1` and `/api/v1`)
- [ ] Webhooks (Liquid → e.g. LiquidJS), emails, background jobs (e.g. pg-boss), MCP server in TypeScript
- [ ] SSR for public pages

## P1 – AI and MCP

- [x] MCP server at `/mcp` (Streamable HTTP), auth via API key (`McpController`, `Mcp::Server`, `spec/requests/mcp_spec.rb`); since 25.10.2026 on the official `mcp` gem (protocol until 2025-11-25), one tool per class in `app/services/mcp/tools`
- [x] MCP tools: `search_posts`, `get_post`, `create_post`, `update_post_status`, `add_comment`, `list_boards`, `get_roadmap`, `top_requests` (votes/trend)
- [x] MCP docs with example configurations for Claude Desktop/Code and Cursor in [docs/mcp-and-ai.md](docs/mcp-and-ai.md)
- [x] Duplicate detection while creating with Postgres full-text search (#455) (`Post.search_by_name_or_description`, `Post.similar_to`, live suggestions in `NewPostForm.tsx`)
- [x] AI provider abstraction: OpenAI-compatible (including Ollama), Anthropic; everything opt-in via ENV (`AI_PROVIDER` and `AI_MODEL`, no build-in model), fully functional without AI (`Ai::Client`)
- [ ] Optional semantic duplicates with pgvector and embeddings
- [x] Feedback from other sources via MCP: `source_url`/`source_label` on the post (only moderators see them: post page, REST API, MCP; only http(s)/mailto), `create_post` with `author_email` (admins only, only existing accounts, audit entry), the "Slack thread → post" recipe in `docs/mcp-and-ai.md`
- [x] Merge duplicates: `merged_into_post_id` + the approval status `merged` (drops out of all lists that filter on `approved`), votes/followers/comments move along (one vote per person), the old link leads to the target (app API resolves it, frontend redirects), "merged from" on the target, the MCP tool `merge_posts`, an audit entry; deleting the target deletes the shells too
- [x] Summarize long discussions: button in the moderation area of the post page (`/next`), `POST /api/app/v1/posts/:id/summary`, cached for a day
- [x] Suggested board and tags: a "suggest board and tags" button in the moderation area, the model only chooses from existing boards/tags (made-up ones disappear), "apply" is a plain post update; `POST /api/app/v1/posts/:id/suggestion`, cached for a day
- [x] Changelog drafts from done posts: a "draft text with AI" button in the entry form (from the linked posts, in the UI language), `POST /api/app/v1/changelog_entries/draft`
- [x] Feedback translation: a "translate" link under the description and comments (moderators only, only with an AI provider), translated into the UI language, the result next to the original as "AI translation", nothing stored in the DB, cache per text for a week; `POST /api/app/v1/posts/:id/translation` and `…/comments/:id/translation`
- [x] Privacy disclosure: what data goes to the AI provider (`Ai::Client.privacy_disclosure`, [docs/mcp-and-ai.md](docs/mcp-and-ai.md))

## P2 – Quick wins
### Quick-win features
- [x] Enable the existing translations: `tr`, `cs`, `el`, `hi`, `nl`, `pl`, `sr`, `sv` enabled (the same completeness level as `es`/`fr`: ~45 missing keys fall back to English). `ja` and `ko` stay disabled (52 missing keys), enabling them once they are complete. Missing keys (mostly the webhooks UI) are a ticket for the translation backlog
- [x] Roadmap can be switched off (#361): the `roadmap_enabled` tenant setting; `/roadmap` and `/embedded_roadmap` redirect to the start page, the header link goes away, a checkbox in Site Settings › General
- [x] Instance-wide default sorting (#193, #363): the `default_post_sorting` tenant setting; `BoardPostsQuery` uses it when no `?sort=` is passed; the new frontend adopts it as default and into the URL. Per board remains for later
- [x] Login only via OAuth (#471): the `login_only_with_oauth` setting ties the email/password form and sign-up together when OAuth providers exist; password reset stays as an emergency entry, the Devise endpoints are not blocked
- [x] Configurable favicon (#452): `site_favicon` on the tenant (URL), falls back to the default favicon in both layouts
- [x] Logo size in the mail template (#474): the `mail_logo_size` setting (pixels, default 64); mails will use the tenant's own logo instead of the hard-coded astuto-assets link (overridable via `EMAIL_LOGO_URL`)
- [x] Confirmation when discarding unsaved site settings (#106): `useUnsavedChangesWarning` (beforeunload) in General, Authentication, Appearance and the webhook/OAuth forms
- [x] Combobox for the status in the post form (#119): moderators choose a status while creating; the app API takes `postStatusId` (moderators only), the timeline entry is covered
- [x] The roadmap shows votes and comments, sorted by "last updated" (#484) in the new frontend; only approved posts (the old UI also showed pending ones)
- [x] "My feedback" overview (#429): `/my-feedback` (icon in the header) with the tabs created / voted / followed and counters, most recently updated first; own posts also while pending, rejected or merged (with a hint), votes and follows only on visible posts; `GET /api/app/v1/my_posts`, `MyPostsQuery`
- [x] Trust levels: the approval rule `new_users_require_approval` ("check anonymous feedback and the first N posts of an account"), `trusted_after_posts` (default 3, 1–100) in Site Settings › General; only approved posts count, rejected ones do not
- [x] RSS feed per board: `/boards/:slug/feed` (30 newest approved posts, status as `category`), link on the board page and `<link rel="alternate">` in the head; only in public feedback spaces; the template `feeds/feed.rss.builder` is intended for the changelog RSS
- [x] Digest for users: `SendRecapEmails` sends to everyone with a chosen frequency (profile, default "never") and active notifications; the content comes from `RecapDigest`: new feedback (list), most-voted posts of the period, status changes of followed posts, for moderators also pending feedback; no mail without news
- [x] Sitemap.xml for public boards, posts and the roadmap (`SeoController`, up to 49,000 posts, `lastmod`); `robots.txt` now dynamic: names the sitemap, blocks the API, moderation, settings and account pages, private spaces completely
- [x] Custom links or a URL in the header (#479, #351): `custom_links` (jsonb: `{label, url}`), a textarea in the General tab, rendered in the legacy header and the new frontend
- [x] Database transactions in workflows (#169): post update/create each atomic with the follow or the status-change entry; emails are sent after the commit; the same safeguard in the public API v1. Creating runs for the old UI, app API and MCP through `CreatePostWorkflow` (`create!` inside the transaction, before this a failed follow did not roll back)

### Gaps against the competition (see competitors.md)
- [x] Changelog: `/changelog` (header link once an entry is published; always for moderators), entries with Markdown text and linked posts (search, posts with status first), drafts, publish/unpublish, the post page links "in the changelog"; an email to the followers of the linked posts on the first publication (once per person); RSS `/changelog/feed`, sitemap; audit category `changelog`; merging takes the links along
- [x] Webhook templates for Slack, Discord and Teams (#419): buttons "template for …" in the webhook form set the method, content type and one message per trigger (language of the space, Teams as an Adaptive Card for Workflows); `WebhookTemplates`, `GET /api/app/v1/site_settings/webhooks/templates`; guide in `docs/webhooks.md`
- [x] Embeddable widget (feedback, roadmap, changelog) **with visitor identification**: `public/widget.js` (button + iframe `/embed`), the visitor token is an HS256 JWT with a secret per tenant (`WidgetToken`, exp ≤ 1 day), exchanged for a bearer access token (12 h, no third-party cookies needed), linkage via `id` → `widget_external_id`, else email, else a new account (switchable); staff accounts never via the widget; allowed origins → CSP `frame-ancestors`; Site Settings › Widget; [docs/widget.md](docs/widget.md)

## P2 – Project and community
- [x] `SECURITY.md` with a reporting path (GitHub private vulnerability reporting), deadlines and scope
- [x] `CHANGELOG.md` and the release process (SemVer, release notes, image tags): CHANGELOG and the first tag `v2.0.0-alpha.1` exist; the version lives in `AstutoProject::VERSION` and `frontend/package.json`. The release checklist is in [docs/releasing.md](docs/releasing.md); images are signed keylessly with cosign and get provenance and an SBOM (`push-to-registry.yml`), running green in CI since 2.0.0-beta.1
- [x] Docs from `astuto/astuto-docs`: the license checked – the repository has **no license** (only "Copyright © Astuto"), so the text was not adopted. Instead own guides for the missing topics (`docs/appearance.md`, `docs/api.md`, OAuth providers with endpoints in `docs/sso.md`); the links in `project.rb`/`project.ts` point to the `docs/` of this repository (three of the four old links were dead anyway). Adopting text only with the author's permission
- [ ] Decide on a translation platform (e.g. Weblate)
- [ ] Demo instance, entries at awesome-selfhosted and AlternativeTo
- [ ] Decision: rename the GitHub repository to `astuto-evolution`

## P3 – Bigger features (on demand)

- [ ] Native integrations Linear, GitHub, Jira with status sync
- [ ] Import from Canny (besides CSV, #368)

- [ ] Image upload and attachments, building on upstream PR #454 (#253, #482); **decide first:** storage without Active Storage (the rule for v2/v3), e.g. S3-compatible or Postgres `bytea` — a new construction site would needlessly complicate the v3 migration again
- [x] Tags for posts (#171): Site Settings › Tags (name, colour, order), moderators assign them on the post page (audit `post.tag_ids`), shown in lists and on the post page, board filter `?tag=`, merging takes the tags along; the REST API and MCP deliver tags as well
- [x] Private boards (#414): visibility per board (everyone / logged-in only / moderators and admins only), central via `Board.visible_to` and `Post.on_boards_visible_to`: boards, posts, comments, votes, roadmap, my feedback, changelog entries, feeds, sitemap, page title, recap and notification mails; `spec/requests/private_boards_spec.rb`
- [x] Admin approval of new users (#362): the setting "approve new accounts", status `pending_approval` for sign-ups by email/OAuth (invitations, SAML, LDAP, widget stay automatic), email to the admins, "approve" in Moderation › Users, email to the person
- [ ] Own sign-up requirements (#30): scope unclear, decision needed
- [ ] Import/export (#368)
- [ ] Sort the roadmap by drag-and-drop (#473)
- [ ] Votes on comments (#408), downvotes (#421), a vote limit per month (#422); question downvotes before implementing one, reactions and budget voting are deliberately excluded (roadmap.md §1)
- [ ] Soft delete for comments (#162), private comments (#418)
- [ ] API: invitations and follows (#434), show user info (#322)
- [ ] Avatar upload instead of Gravatar only (#469)
- [ ] Custom fields for users (#420), default configurations for OAuth and webhooks (#419)
- [ ] User segments: filter or weight votes by customer group (needs visitor identification and custom fields; weighting is in the v3 schema)
- [ ] Stale rules: moderation filter "X months without activity", automatic archiving as opt-in only
- [x] LDAP/AD login (#8), see mid-size companies
- [ ] GitHub integration (#365)
- [ ] Custom JavaScript (#376), only with CSP and an admin warning
- [x] Several brands per instance (#76): multi-tenancy with the instance admin `/instance`
- [x] ~~Automatic login after tenant sign-up (#263)~~ moot, the tenant sign-up is removed
- [ ] Translations: adopt the Crowdin PR #417, Polish (#450), define the translation process (#121)
- [ ] Bounties (#438), not planned for now