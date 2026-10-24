# AGENTS.md

## Purpose
Astuto Evolution: community continuation of Astuto, a self-hosted customer feedback tool (boards, roadmap, votes, comments, moderation, OAuth2, webhooks, REST API). Upstream `astuto/astuto` is archived (EOL 01/2026). Project name and links live in `config/initializers/project.rb` and `app/javascript/constants/project.ts`. Plan: `roadmap.md`, tasks: `todo.md`, competitor analysis: `konkurrenz.md`.

## Structure
- `app/controllers` – Rails controllers; `app/controllers/api/v1` – public REST API (API keys); `app/controllers/api/app/v1` – JSON API for the v2 frontend (session + CSRF)
- `app/serializers/api/app/v1` – camelCase JSON for the app API (never expose author emails); `app/queries` – query objects (e.g. `BoardPostsQuery`)
- `frontend/` – v2 frontend (React 19, TS 7, TanStack Router/Query, Tailwind 4, shadcn/ui, Biome), served under `/next`; see `frontend/README.md`
- `app/policies` – Pundit authorization (one policy per model)
- `app/workflows` – service objects for multi-step logic (OAuth exchange, sign-in, custom domain)
- `app/jobs` – ActiveJob (`RunWebhook`, recap emails); backend is async or Sidekiq via `ACTIVE_JOB_BACKEND`
- `app/javascript` – legacy React 16 + Redux frontend (being replaced by `frontend/`), mounted via react-rails
- `config/locales` – backend i18n; `app/javascript/translations` – frontend i18n (i18n-js, Crowdin)
- `spec/` – RSpec: models, policies, requests, API (rswag), system tests (Capybara + Chrome); 374 examples

## Commands
- Dev: `docker compose up` (app on :3000, override with `ASTUTO_PORT`; default admin `admin@example.com` / `password`)
- Tests: `docker compose exec web bundle exec rspec` (system specs on arm64: install `chromium chromium-driver`, set `CHROME_BIN`/`CHROMEDRIVER_PATH`)
- API docs: `RSWAG_SWAGGERIZE=true RAILS_ENV=test bundle exec rake rswag:specs:swaggerize` (writes `swagger/v1/swagger.yaml` and `swagger/app/v1/openapi.yaml`)
- Frontend: `docker compose up` → http://localhost:5173/next/; in `frontend/`: `npm run lint|typecheck|test|build`, `npm run api:types` after API changes
- Local CI: `docker compose exec web bin/ci` (bundler-audit, yarn audit for critical advisories, Brakeman, RSpec, seeds)
- Prod image: `docker build --build-arg ENVIRONMENT=production --target prod .`

## Patterns
- Multi-tenancy via `Current.tenant` (subdomain-based when `MULTI_TENANCY=true`); every model is tenant-scoped.
- All configuration via ENV (SMTP `EMAIL_*`, `POSTGRES_*`, `BASE_URL`, `TRUSTED_PROXY`).
- The DB is migrated automatically by `docker-entrypoint.sh` on container start.
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
