# Astuto Evolution – v2 frontend

The new web frontend that replaces the legacy React 16 / Redux / Bootstrap 4 UI in v2.
It is a separate single-page app talking to Rails only through a JSON API, so it can
move unchanged to the v3 TypeScript backend (TanStack Start + Drizzle).

Until it covers every page it is served under **`/next`**; the legacy UI stays at `/`.

## Stack

React 19 · TypeScript 7 · TanStack Router (file-based routes) · TanStack Query ·
Tailwind CSS 4 · shadcn/ui (Radix) · Vite 8 · Vitest · Biome (lint + format)

## Architecture

```
Browser ──/, /boards/*, /posts/*, /login, /site_settings/*, …──▶ SPA (this folder, built to public/next)
        ──/api/app/v1/*──▶ Rails JSON API (session cookie + X-CSRF-Token)
        ──/users/*, /o_auths/*──▶ Devise / OAuth endpoints (their pages redirect into the SPA)
```

- **API contract:** `app/controllers/api/app/v1` and `app/serializers/api/app/v1` in Rails,
  documented by request specs in `spec/api/app/v1` (rswag). Those specs generate
  `swagger/app/v1/openapi.yaml`; `npm run api:types` turns it into
  `src/api/schema.d.ts`. Responses use camelCase and never include author emails.
- **Data loading:** each route's `loader` prefetches with `queryClient.ensureQueryData`,
  components read with `useSuspenseQuery` (`src/api/queries.ts`).
- **Translations:** reused from `config/locales/*.yml`, served by
  `GET /api/app/v1/translations/:locale` (`src/lib/i18n.tsx`, Rails-style `%{var}` and one/other).
- **Auth:** the Rails session cookie, set by the SPA's login and sign-up pages through the app API.
  Rails pages that redirect into the SPA (e.g. email confirmation) pass their flash message in
  `<meta name="astuto-flash">` (`FlashMessages`).
- **Writes:** `src/api/mutations.ts` (create post, vote, follow, comment). The CSRF token from
  `GET /session` is sent as `X-CSRF-Token`. Votes update the cache optimistically and roll back on errors.
  New posts carry a hidden honeypot field and the time the form was opened (server-side anti-spam).
- **Production:** the Docker build runs `npm run build` into `public/next`; Rails serves
  `public/next/index.html` for every page route in `config/routes.rb` (`SpaController`), the built
  files stay under `/next/assets`. Old `/next/*` URLs redirect to `/*`. A new page needs a route
  in `src/routes` and one in `config/routes.rb`.

```
src/
  api/        client (openapi-fetch + CSRF), query definitions, generated schema
  components/ shared components; ui/ = shadcn/ui
  features/   boards/, posts/, roadmap/, layout/ – page building blocks
  lib/        i18n, formatting, utils
  routes/     TanStack Router file routes (routeTree.gen.ts is generated)
```

## Development

With Docker (Rails, Postgres and Vite):

```
docker compose up
```

Open http://localhost:5173/. Vite proxies API and Devise requests to Rails.

On the host instead (Node ≥ 26), against a Rails server on another port:

```
cd frontend
npm install
BACKEND_URL=http://localhost:3000 npm run dev
```

## Commands

| Command                           |                                                                                                                                                                                                                                               |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `npm run dev`                     | Vite dev server on port 5173                                                                                                                                                                                                                  |
| `npm run build`                   | production build into `../public/next`                                                                                                                                                                                                        |
| `npm run lint` / `npm run format` | Biome check / fix                                                                                                                                                                                                                             |
| `npm run typecheck`               | TypeScript 7 (`tsc --noEmit`)                                                                                                                                                                                                                 |
| `npm test`                        | Vitest                                                                                                                                                                                                                                        |
| `npm run e2e`                     | Playwright end-to-end tests against a running instance (`E2E_BASE_URL`, default `http://localhost:3000`; admin from `E2E_ADMIN_EMAIL`/`E2E_ADMIN_PASSWORD`, default the development seeds). They create and delete their own boards and posts |
| `npm run api:types`               | regenerate `src/api/schema.d.ts` from the OpenAPI file (run `bundle exec rake rswag:specs:swaggerize` in Rails first)                                                                                                                         |

## Notes

- `openapi-typescript` does not support TypeScript 7 yet, so `api:types` runs it through
  `npx` with TypeScript 5.9 instead of adding it to the project.
- shadcn/ui: add components with `npm run ui:add -- <name>`, not with the shadcn CLI directly. The CLI
  cannot read tsconfig `paths` without `baseUrl` (gone in TypeScript 7) and would import `cn` from an
  unrelated npm package; `scripts/ui-add.mjs` repairs that.
- Install scripts are blocked by npm; `allowScripts` in `package.json` lists the decisions.
