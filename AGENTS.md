# AGENTS.md

## Purpose
Fork of Astuto, a self-hosted customer feedback tool (boards, roadmap, votes, comments, moderation, OAuth2, webhooks, REST API). Upstream `astuto/astuto` is archived (EOL 01/2026); this fork is maintained independently. Plan: `roadmap.md`, tasks: `todo.md`, competitor analysis: `konkurrenz.md`.

## Structure
- `app/controllers` – Rails controllers; `app/controllers/api` – REST API v1 (API keys)
- `app/policies` – Pundit authorization (one policy per model)
- `app/workflows` – service objects for multi-step logic (OAuth exchange, sign-in, custom domain)
- `app/jobs` – ActiveJob (`RunWebhook`, recap emails); backend is async or Sidekiq via `ACTIVE_JOB_BACKEND`
- `app/javascript` – React 16 + Redux + TypeScript (`actions/`, `reducers/`, `components/`, `containers/`), mounted via react-rails
- `config/locales` – backend i18n; `app/javascript/translations` – frontend i18n (i18n-js, Crowdin)
- `spec/` – RSpec: models, policies, requests, API (rswag), system tests (Capybara + Chrome)

## Commands
- Dev: `docker compose up` (app on :3000, default admin `admin@example.com` / `password`)
- Tests: `docker compose exec web bundle exec rspec`
- API docs: `RSWAG_SWAGGERIZE=true RAILS_ENV=test bundle exec rake rswag:specs:swaggerize`
- Prod image: `docker build --build-arg ENVIRONMENT=production --target prod .`

## Patterns
- Multi-tenancy via `Current.tenant` (subdomain-based when `MULTI_TENANCY=true`); every model is tenant-scoped.
- All configuration via ENV (SMTP `EMAIL_*`, `POSTGRES_*`, `BASE_URL`, `TRUSTED_PROXY`).
- The DB is migrated automatically by `docker-entrypoint.sh` on container start.

## Gotchas
- Stack is outdated (Ruby 3.0, Rails 6.1, React 16, Bootstrap 4); see roadmap phase 1 before adding dependencies.
- Behind a reverse proxy, `X-Forwarded-Proto` must be set or OAuth callbacks use `http` (upstream #478).
- OAuth `token_state` cookie uses `domain: ".#{request.domain}"`, which breaks on multi-part TLDs and IPs (upstream #472).
- Webhook bodies are Liquid templates that must render valid JSON; use the `escape_json` filter.
