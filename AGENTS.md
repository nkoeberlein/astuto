# AGENTS.md

## Purpose
Astuto Evolution: community continuation of Astuto, a self-hosted customer feedback tool (boards, roadmap, votes, comments, moderation, OAuth2, webhooks, REST API). Upstream `astuto/astuto` is archived (EOL 01/2026). Project name and links live in `config/initializers/project.rb` and `frontend/src/lib/project.ts`. Plan: `roadmap.md`, tasks: `todo.md`, competitor analysis: `competitors.md`.

## Structure
- `app/controllers` – Rails controllers; `app/controllers/api/v1` – public REST API (API keys); `app/controllers/api/app/v1` – JSON API for the v2 frontend (session + CSRF); `app/controllers/instance_admin` – operator pages at `/instance` (multi-tenancy, HTTP Basic with `INSTANCE_ADMIN_PASSWORD`, plain ERB without JS)
- `app/serializers/api/app/v1` – camelCase JSON for the app API (never expose author emails); `app/queries` – query objects (e.g. `BoardPostsQuery`)
- `frontend/` – v2 frontend (React 19, TS 7, TanStack Router/Query, Tailwind 4, shadcn/ui, Biome), serves every page at `/` (`SpaController`; built files under `/next/assets`, old `/next/*` URLs redirect); see `frontend/README.md`
- `app/policies` – Pundit authorization (one policy per model)
- `app/workflows` – service objects for multi-step logic (OAuth exchange, sign-in, tenant creation); `CreatePostWorkflow` is the only way to create posts with follow and initial status (app API, REST API, MCP)
- `app/services/mcp` – MCP server on the official `mcp` gem: `server.rb` builds it, one class per tool in `tools/` (inherit `Mcp::Tools::Base`, implement `self.run(user:, **args)`), shared queries in `post_data.rb`; endpoint `McpController` (`/mcp`, API key of a moderator)
- `app/services/ai/client.rb` – opt-in AI provider (OpenAI-compatible, Ollama, Anthropic; needs `AI_PROVIDER` and `AI_MODEL`); used by `Api::App::V1::SummariesController`
- `app/lib` – small helpers (`SafeUrl` for admin-entered link URLs, `SafeUrl.local_path?` for return targets after sign-in, `ApiToken` reads API keys for MCP and Rack::Attack, `PostSpamCheck` honeypot/fill-time checks, Liquid filters)
- `app/jobs` – ActiveJob (`RunWebhook`, recap emails); backend is async or Sidekiq via `ACTIVE_JOB_BACKEND`
- `config/locales` – i18n for backend and frontend (Crowdin); `en.yml` top-level keys plus `activerecord` and `devise` go to the frontend via `/api/app/v1/translations/:locale`
- `spec/` – RSpec: models, policies, requests, API (rswag); about 630 examples. Browser tests are Playwright in `frontend/e2e`. Spec files must end in `_spec.rb`, or RSpec skips them

## Commands
- Dev: `docker compose up` (app on :3000, override with `ASTUTO_PORT`; default admin `admin@example.com` / `password` in development; elsewhere a random password unless `ADMIN_PASSWORD` is set, see `DefaultAdminCredentials`)
- Tests: `docker compose exec web bundle exec rspec`
- API docs: `RSWAG_SWAGGERIZE=true RAILS_ENV=test bundle exec rake rswag:specs:swaggerize` (writes `swagger/v1/swagger.yaml` and `swagger/app/v1/openapi.yaml`)
- Frontend: `docker compose up` → http://localhost:5173/; in `frontend/`: `npm run lint|typecheck|test|build`, `npm run api:types` after API changes; `npm run e2e` (Playwright) against a running instance, also in CI (`run-tests.yml`)
- Local CI: `docker compose exec web bin/ci` (bundler-audit, npm audit of frontend/ for critical advisories, Brakeman, RuboCop, RSpec, seeds)
- Lint: `BUNDLE_GEMFILE=lint/Gemfile bundle exec rubocop` (own bundle; `.rubocop.yml` enables Lint, Security and a few Rails/RSpec cops, no style rules; CI `lint.yml`)
- Prod image: `docker build --build-arg ENVIRONMENT=production --target prod .`

## Patterns
- Multi-tenancy via `Current.tenant` (subdomain = labels in front of the `BASE_URL` host, or a custom domain, when `MULTI_TENANCY=true`); every model is tenant-scoped. No billing: feedback spaces come from `bin/rails tenants:create` (docs/multi-tenancy.md).
- All configuration via ENV (SMTP `EMAIL_*`, `POSTGRES_*`, `BASE_URL`, `TRUSTED_PROXY`).
- The DB is prepared on container start by `docker-entrypoint.sh` → `rake astuto:prepare_db` (schema + seeds when fresh, else migrations; Postgres advisory lock, so several containers can start at once). `docker-entrypoint-prod.sh` runs a passed command afterwards (worker: `bundle exec sidekiq`).
- Probes `/health/live`, `/health/ready`, metrics `/metrics` (`METRICS_TOKEN`) are exempt from `RAILS_HOSTS` and `FORCE_SSL`; Helm chart in `deploy/helm/astuto-evolution` (CI: `helm.yml`).
- v2 frontend is RTL-ready: use CSS logical properties only (`ms-`/`me-`, `ps-`/`pe-`, `start`/`end`), never `left`/`right` utilities.
- Keep the schema portable for the v3 TypeScript rewrite: no `serialize`/`store` columns (use `jsonb`), no polymorphic associations, no Active Storage, no Ruby-specific formats (Marshal) in the database.

## Gotchas
- Backend is on Ruby 4.0 / Rails 8.1 / Devise 5 / Sidekiq 8.1 (`load_defaults` 8.1). The React 16/Redux/Bootstrap 4 frontend, webpack, Sass, Sprockets and react-rails are gone; `frontend/` is the only UI. v3 plans a full TypeScript rewrite (see `roadmap.md`).
- The test env never reloads code (`enable_reloading = false`): a dev server in the same container writes files on boot, which used to reload classes mid-run.
- `config/initializers/cookie_rotator.rb` keeps cookies signed with pre-7.0 SHA1 keys valid; it can go in 2027.
- New ActiveJob queues (`queue_as`) must be added to `config/sidekiq.yml`, or Sidekiq never runs them.
- The production image build generates API docs with `RAILS_ENV=test` without test gems installed: gems in the test group must not be auto-required (`require: false`).
- Postgres ≥ 18 images store data under `/var/lib/postgresql/<major>/docker`; see `UPGRADING.md`.
- Behind a reverse proxy, `X-Forwarded-Proto` must be set or OAuth callbacks use `http` (upstream #478).
- OAuth `token_state` cookie: domain `.<BASE_URL host>` on subdomains (shared with `login.`, where default providers call back), host-only on custom domains; a callback without the cookie continues on the tenant's custom domain (#472).
- Webhook bodies are Liquid templates that must render valid JSON; use the `escape_json` filter.
- Content Security Policy (`config/initializers/content_security_policy.rb`): no inline `<script>` without `javascript_tag nonce: true`, no inline event handlers (`onclick=` etc.), no `eval`. `spec/system/content_security_policy_spec.rb` fails on browser console violations.
- `public/**/index.html` is never served for bare directories (`public_file_server.index_name`), so `/next/` reaches the redirect to `/`.
- Pages of the v2 frontend are listed in `config/routes.rb` (`spa#show`); a new frontend route needs a Rails route too. Named routes (`post_url`, `roadmap_url`, `moderation_feedback_url`, ...) keep mail links working.
- Devise's HTML pages (`/users/sign_in`, `/users/sign_up`, `/users/password/new|edit`, `/users/edit`) redirect to the v2 pages and keep the flash; `SpaController` hands it to the frontend in `<meta name="astuto-flash">`. Confirmation and unlock links from emails (`/users/confirmation`, `/users/unlock`) redirect to the v2 pages `/confirmation/new` and `/unlock/new` on errors. Plain Rails views without JS (`layouts/plain`): pending/blocked notices, OAuth test page, instance admin. There is no tenant self-signup.
- Widget (`/embed`, `public/widget.js`, docs/widget.md): visitors authenticate with `Authorization: Bearer` (access token from `POST /api/app/v1/widget/session`), not the session cookie; `Api::App::BaseController#current_user` and `#verified_request?` handle it. Bearer users are never staff. New app API code must use `current_user`/`user_signed_in?`, never `warden` directly.
- Logins: only `POST /api/app/v1/session` (+ `/session/two_factor` for 2FA, concern `TwoFactorLogin`); Devise's HTML create actions redirect. Anything new that signs a user in must respect `User#two_factor_enabled?` (see `OAuthsController#sign_in_from_oauth_token`).
- Personal data (docs/privacy.md): `User#anonymize!` for deletion, `User#export_data` for access requests; new personal fields belong in both and, if they expire, in `PurgeExpiredData`. Avatars via `User#avatar_url` (nil when the space switched Gravatar off).
- Admin and moderator actions write an audit entry: `audit('category.verb', subject, changes: record.saved_changes)` in app API (`Api::App::BaseController`), REST API (`Api::BaseController`) and MCP (`Mcp::Tools::Base.audit`). New categories go into `AuditEvent::CATEGORIES`, `AUDIT_CATEGORIES` in `frontend/src/api/queries.ts` and the `site_settings.audit_log` translations; secret fields are filtered by `AuditEvent::SECRET_FIELD`.
- Admin-entered URLs that end up in an `href` (header links, logo link) must pass `SafeUrl.safe?`; render via `TenantSetting#safe_custom_links` / `#safe_logo_custom_url`.
- Password reset emails have two templates: `reset_password_instructions` (Devise default, links to `/users/password/edit`, which redirects to v2) and `reset_password_instructions_next` (v2, sent by `User#send_next_reset_password_instructions` from the app API).
- v2 login links pass `?redirect=<path>` (`useLoginRedirect`); OAuth carries it as `return_to` in the `oauth_return_to` cookie, because the callback may run on another host.
- `gh` defaults to the archived upstream repo: pass `-R nkoeberlein/astuto-evo`.
