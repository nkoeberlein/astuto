# AGENTS.md

## Purpose
Astuto Evolution: community continuation of Astuto, a self-hosted customer feedback tool (boards, roadmap, votes, comments, moderation, OAuth2, webhooks, REST API). Upstream `astuto/astuto` is archived (EOL 01/2026). Project name and links live in `config/initializers/project.rb` and `app/javascript/constants/project.ts`. Plan: `roadmap.md`, tasks: `todo.md`, competitor analysis: `konkurrenz.md`.

## Structure
- `app/controllers` – Rails controllers; `app/controllers/api/v1` – public REST API (API keys); `app/controllers/api/app/v1` – JSON API for the v2 frontend (session + CSRF)
- `app/serializers/api/app/v1` – camelCase JSON for the app API (never expose author emails); `app/queries` – query objects (e.g. `BoardPostsQuery`)
- `frontend/` – v2 frontend (React 19, TS 7, TanStack Router/Query, Tailwind 4, shadcn/ui, Biome), served under `/next`; see `frontend/README.md`
- `app/policies` – Pundit authorization (one policy per model)
- `app/workflows` – service objects for multi-step logic (OAuth exchange, sign-in, custom domain); `CreatePostWorkflow` is the only way to create posts with follow and initial status (legacy UI, app API, MCP)
- `app/services/mcp` – MCP server on the official `mcp` gem: `server.rb` builds it, one class per tool in `tools/` (inherit `Mcp::Tools::Base`, implement `self.run(user:, **args)`), shared queries in `post_data.rb`; endpoint `McpController` (`/mcp`, API key of a moderator)
- `app/services/ai/client.rb` – opt-in AI provider (OpenAI-compatible, Ollama, Anthropic; needs `AI_PROVIDER` and `AI_MODEL`); used by `Api::App::V1::SummariesController`
- `app/lib` – small helpers (`SafeUrl` for admin-entered link URLs, `SafeUrl.local_path?` for return targets after sign-in, `ApiToken` reads API keys for MCP and Rack::Attack, `PostSpamCheck` honeypot/fill-time checks, Liquid filters)
- `app/jobs` – ActiveJob (`RunWebhook`, recap emails); backend is async or Sidekiq via `ACTIVE_JOB_BACKEND`
- `app/javascript` – legacy React 16 + Redux frontend (being replaced by `frontend/`), mounted via react-rails
- `config/locales` – backend i18n; `app/javascript/translations` – frontend i18n (i18n-js, Crowdin)
- `spec/` – RSpec: models, policies, requests, API (rswag), system tests (Capybara + Chrome); about 445 examples without system specs. Spec files must end in `_spec.rb`, or RSpec skips them

## Commands
- Dev: `docker compose up` (app on :3000, override with `ASTUTO_PORT`; default admin `admin@example.com` / `password` in development; elsewhere a random password unless `ADMIN_PASSWORD` is set, see `DefaultAdminCredentials`)
- Tests: `docker compose exec web bundle exec rspec` (system specs on arm64: install `chromium chromium-driver`, set `CHROME_BIN`/`CHROMEDRIVER_PATH`)
- API docs: `RSWAG_SWAGGERIZE=true RAILS_ENV=test bundle exec rake rswag:specs:swaggerize` (writes `swagger/v1/swagger.yaml` and `swagger/app/v1/openapi.yaml`)
- Frontend: `docker compose up` → http://localhost:5173/next/; in `frontend/`: `npm run lint|typecheck|test|build`, `npm run api:types` after API changes; `npm run e2e` (Playwright) against a running instance, also in CI (`run-tests.yml`)
- Local CI: `docker compose exec web bin/ci` (bundler-audit, yarn audit for critical advisories, Brakeman, RSpec, seeds)
- Prod image: `docker build --build-arg ENVIRONMENT=production --target prod .`

## Patterns
- Multi-tenancy via `Current.tenant` (subdomain-based when `MULTI_TENANCY=true`); every model is tenant-scoped.
- All configuration via ENV (SMTP `EMAIL_*`, `POSTGRES_*`, `BASE_URL`, `TRUSTED_PROXY`).
- The DB is migrated automatically by `docker-entrypoint.sh` on container start.
- v2 frontend is RTL-ready: use CSS logical properties only (`ms-`/`me-`, `ps-`/`pe-`, `start`/`end`), never `left`/`right` utilities.
- Keep the schema portable for the v3 TypeScript rewrite: no `serialize`/`store` columns (use `jsonb`), no polymorphic associations, no Active Storage, no Ruby-specific formats (Marshal) in the database.

## Gotchas
- Backend is on Ruby 4.0 / Rails 8.1 / Devise 5 / Sidekiq 8.1 (`load_defaults` 8.1). The React 16/Redux/Bootstrap 4 frontend will be replaced in v2, not migrated: do not invest in it beyond fixes. v3 plans a full TypeScript rewrite (see `roadmap.md`).
- The test env never reloads code (`enable_reloading = false`): a dev server in the same container writes files on boot, which used to reload classes mid-run.
- `config/initializers/cookie_rotator.rb` keeps cookies signed with pre-7.0 SHA1 keys valid; it can go in 2027.
- Stripe's API version is pinned in `config/initializers/stripe.rb`; raise it only after testing billing against a Stripe test account.
- New ActiveJob queues (`queue_as`) must be added to `config/sidekiq.yml`, or Sidekiq never runs them.
- The production image build generates API docs with `RAILS_ENV=test` without test gems installed: gems in the test group must not be auto-required (`require: false`).
- Postgres ≥ 18 images store data under `/var/lib/postgresql/<major>/docker`; see `UPGRADING.md`.
- Behind a reverse proxy, `X-Forwarded-Proto` must be set or OAuth callbacks use `http` (upstream #478).
- OAuth `token_state` cookie uses `domain: ".#{request.domain}"`, which breaks on multi-part TLDs and IPs (upstream #472).
- Webhook bodies are Liquid templates that must render valid JSON; use the `escape_json` filter.
- Content Security Policy (`config/initializers/content_security_policy.rb`): no inline `<script>` without `javascript_tag nonce: true`, no inline event handlers (`onclick=` etc.), no `eval`. `spec/system/content_security_policy_spec.rb` fails on browser console violations.
- Legacy JSON must not expose other users' emails: build author fields with `Legacy::AuthorFields` (email only for moderators and the person themselves, Gravatar hash for everyone).
- `public/**/index.html` is never served for bare directories (`public_file_server.index_name`), so `/next` goes through `SpaController`.
- Admin-entered URLs that end up in an `href` (header links, logo link) must pass `SafeUrl.safe?`; render via `TenantSetting#safe_custom_links` / `#safe_logo_custom_url`.
- System specs need Chromium in the container; the dev image has none, so run them in CI (`run-tests.yml`, triggered by pull requests).
- Password reset emails have two templates: `reset_password_instructions` (legacy UI) and `reset_password_instructions_next` (v2, sent by `User#send_next_reset_password_instructions` from the app API).
- v2 login links pass `?redirect=<path>` (`useLoginRedirect`); OAuth carries it as `return_to` in the `oauth_return_to` cookie, because the callback may run on another host.
- `gh` defaults to the archived upstream repo: pass `-R nkoeberlein/astuto-evo`.
