# Roadmap – Astuto Evolution

As of: 30.10.2026 · Repository: [nkoeberlein/astuto-evo](https://github.com/nkoeberlein/astuto-evo) · Branch `develop`

Astuto Evolution continues the archived [astuto/astuto](https://github.com/astuto/astuto) as a community project. Name and origin stay recognizable, and so does the fresh start: a current stack, a new interface, AI features. The goal is **not personal use** but an independent open-source project for the niche identified in the [competitor analysis](competitors.md). Concrete tasks: [todo.md](todo.md).

## 1. Vision and niche

**Positioning:** *The lean, self-hosted feedback portal without user limits, with anonymous feedback, GDPR-friendly and AI-native over MCP.*

| Audience | Why Astuto Evolution |
|---|---|
| Small and mid-size SaaS teams | No price per user or seat like Canny or Featurebase; one Docker image |
| **Mid-size companies (commercial)** | Self-hosting in their own data center, several products/brands per instance (multi-tenancy), SSO, privacy, optional support and SLA |
| EU/DACH companies, agencies, education | Data stays in-house, no telemetry, AI optional with a local model |
| Open-source projects | Free, AGPL, public roadmap, feedback without an account |
| Internal IT / company portals | Self-hosting, OAuth/SSO, LDAP later |

**Deliberate differentiation:**
- **Quackback** is becoming a support suite (inbox, help center, status page). Astuto Evolution stays a feedback portal on purpose: less operations, less attack surface.
- **Fider** is simple but has no roadmap and no changelog, and moderation sits in the cloud behind a paywall. Astuto Evolution has both already and stays completely free.
- **Proprietary tools** compete on price per user. Astuto Evolution knows no limits.

**Deliberately not planned** (checked against the competition, 25.10.2026), to keep the portal lean:
- Help center, support inbox, status page (the Quackback direction)
- Surveys (NPS/CSAT): a product of its own
- Prioritization frameworks (RICE/ICE): belong in Jira, Linear or Productboard; Astuto provides the data over API, MCP and integrations
- Revenue linkage (Canny Business): needs CRM or billing data of customers; at most later via user segments
- Own Slack- or Teams-apps: with self-hosting every installation would have to register its own app; webhook templates and MCP cover the need
- Reactions, budget or credit voting: the simple vote model is a feature (also question Downvotes #421 before implementing one)
- Own connectors that automatically collect feedback (Canny Autopilot): instead via MCP, see phase 4

**Principles:**
1. Runs with one image plus PostgreSQL, no further mandatory services.
2. AI is optional ("bring your own model": OpenAI-compatible API, Anthropic, local via Ollama). Everything works without AI.
3. No telemetry. Free self-hosting with full features, commercially too. The project earns money at most with services (hosting, support, SLA), never with locked features (see 7.).
4. Compatible with Astuto 1.x: existing installations can migrate with a documented guide.

## 2. Starting point

| Item | Finding |
|---|---|
| Upstream | `astuto/astuto` archived, end of life since 09.01.2026 (#487). 2,343 stars, 186 forks, no active successor. |
| Open upstream issues | 72 (~15 bugs or operational problems, ~45 feature wishes). They form the starting stock for planning. |
| Code base | ~4,900 lines of Ruby, ~16,000 lines of TS/TSX, 374 tests. Cleanly structured (Controllers → Policies → Workflows → Models). |
| Multi-tenancy and SaaS parts | `tenant_id` in all tables, tenant sign-up, custom domains, Stripe billing of the discontinued astuto.io offering (~20 files) |
| License | AGPL-3.0 (stays) |

### Platform – state and goal

| Component | Upstream | Now (`develop`) | Target 2.0 |
|---|---|---|---|
| Ruby | 3.0.6 (EOL) | **4.0.9** | 4.0 ✓ |
| Rails | 6.1 (EOL) | **8.1.4** | 8.1 ✓ |
| Devise | 4.7.3 | **5.0.4** | 5.x ✓ |
| PostgreSQL | 14.5 (EOL 12.11.2026) | 18 (dev; the 19rc1 volume was discarded) | 19 (GA 19.11.2026) |
| Node (build) | 20 (EOL) | **26** (runtime image without Node) | 26 LTS ✓ |
| Debian base | 11 (EOL, image no longer built) | 13 trixie | 13 trixie |
| Docker image | `riggraz/astuto`, amd64 | CI: `ghcr.io/nkoeberlein/astuto-evo`, amd64 + arm64 | ✓ |
| Frontend | React 16, Redux, Bootstrap 4 | **replaced**: the v2 React 19 SPA serves every page at `/` (see 3.); v3: full TypeScript | ✓ |

## 3. Version strategy

| Version | Goal |
|---|---|
| **v2** | Modernize packages (✅ backend done), throw away and replace the entire React-16/Redux/Bootstrap-4 part: either with clean **Rails 8 (Hotwire)** or a **strictly separated, modern frontend** against a Rails JSON API. Plus MCP and operational fixes. |
| **v3** | Move to **full TypeScript**: TanStack Start with Drizzle (PostgreSQL) and Tailwind. Rails goes away. (Decision made, see todo.md) |

### The v3 choice drives the v2 frontend (decided: TanStack)

| v3 stack | Matching v2 frontend | Why |
|---|---|---|
| **TanStack Start (React)** ✅ decided | **Separate frontend:** React 19 + TypeScript 7 + TanStack Router/Query + Tailwind 4 + shadcn/ui, built with Vite, shipped as an SPA against a versioned Rails JSON API (OpenAPI from rswag → generated TS client) | The v2 UI lives on in v3. In v3 only the backend is replaced (Rails → TanStack Start server functions + Drizzle). The transition is gradual, endpoint by endpoint ("strangler"). |
| **SvelteKit** | *(rejected)* **Rails 8 with Hotwire** (Turbo + Stimulus, ViewComponent, Tailwind) | A React frontend would be throwaway work next to SvelteKit. Hotwire would have been the cheapest clean path for v2; only design and Tailwind classes could have been carried over. |

**Decision: TanStack.** The team stays with React, the work on the v2 frontend is not lost, and v3 becomes a backend swap instead of a second full rebuild. The ecosystem (shadcn/ui, TanStack Table/Query/Form) covers admin tables, forms and the widget.

**Consequences of the decision for v2:**
- Rails becomes a pure API and auth layer. Today's JSON endpoints of the old frontend become a documented `/api/app/v1` interface (session cookie + CSRF); the public `/api/v1` for integrations (API key) stays.
- Delivery still as **one image**: Rails serves the built SPA as static files. SSR for public board SEO arrives with v3 (TanStack Start). Until then, meta tags are set server-side.
- Devise stays for login, OAuth and emails; the login pages become SPA pages against JSON endpoints.
- The old frontend gets replaced page by page and removed completely at the end (`react-rails`, `react_ujs`, Redux, Bootstrap, jQuery, Turbolinks, Webpack, `i18n-js` 3, the `connection_pool` pin).

**Requirements for the new UI:** mobile first, dark mode, WCAG 2.2 AA, branding via CSS variables, one component set that also serves the embeddable widget, translations from the existing YAML files (exported as JSON), RTL-ready (CSS logical properties, `dir` from the locale; RTL translations as soon as someone contributes them).

**Multi-tenancy stays (decided).** Several feedback portals per instance matter to companies with several products or brands and to agencies (#76), and they are the basis of a possible hosted variant. **No billing (decided):** the Stripe billing and trial of the discontinued astuto.io offering are removed. Custom domains stay (TLS via Caddy on-demand TLS, see `docs/multi-tenancy.md`); the disabled tenant sign-up falls away with the old frontend, tenants are created in the instance admin at `/instance` or via a rake task (#76).

## 4. Phases

### Phase 0 – Take over the fork ✅
- Upstream PRs #477, #470, #459, #463, #460 adopted; #463 (broken YAML) and #460 (filters without effect, broken backend filter) reworked
- CI builds multi-arch images for GHCR
- Rename to **Astuto Evolution**, links to `nkoeberlein/astuto`, README and CONTRIBUTING rewritten
- Starting state: 374 tests

### Phase 1 – Platform (backend done) · P0
- [x] Ruby 4.0.9, Rails 8.1.4 with `load_defaults` 8.1, Devise 5, Puma 8, Sidekiq 8.1, Debian trixie, Node 26 – tests green, no deprecations, production image runs
- [x] Dependabot, `bundler-audit`, Brakeman, local `bin/ci`
- [ ] PostgreSQL 19 at GA (the guide in [UPGRADING.md](UPGRADING.md) is ready and tested)
- [x] Security policy (`SECURITY.md`)
- [x] Multi-tenancy mode tested and documented (`docs/multi-tenancy.md`: subdomains, custom domains, TLS, tenant administration via rake); billing removed

### Phase 2 – Operations and bugfixes · P1
The most frequent problems from the upstream issues: HTTPS behind a reverse proxy (#478, #201), the OAuth cookie (#472), SMTP (#330 and others), make webhook errors visible (#458), configurable database (#326, #207), default admin password, insecure SMTP default. Details in todo.md.

### Phase 3 – Replace the old frontend · P1 (core of v2) ✅
1. ✅ Decision: v3 will be **TanStack Start + Drizzle + Tailwind** → v2 gets a separate React frontend
2. ✅ `frontend/` with Vite 8, React 19, **TypeScript 7**, TanStack Router/Query, Tailwind 4, shadcn/ui, **Biome** (instead of ESLint/Prettier), Vitest; own CI workflow; build goes into the image
3. ✅ App API `/api/app/v1` (reads: session, translations, boards, statuses, posts, comments), OpenAPI via rswag, generated TS types
4. ✅ Board page (search, sorting, status filter, load more) and post detail with comments
5. ✅ Write actions: create post (also anonymous, with approval rules and spam protection), vote (optimistic), comment and reply, moderator updates, follow, edit/delete, status changes; CSRF flow tested
6. ✅ Roadmap page, server-side meta tags
7. ✅ Auth pages (login, sign-up, password, OAuth) and the embedded roadmap
8. ✅ Moderation (feedback queue, users), site settings (all areas) and profile settings
9. ✅ Cutover: the new frontend serves every page at `/` (`/next/*` redirects)
10. ✅ Old frontend removed: React 16, Redux, Bootstrap, jQuery, Turbolinks, Webpack, Sass, Sprockets, `react-rails`, `i18n-js`, the old JSON endpoints and the disabled tenant sign-up. Only the build of `frontend/` needs Node.js

### Phase 4 – AI and MCP · P1 (MCP in 2.0, rest 2.x)
- ✅ **MCP server** (Streamable HTTP at `/mcp` on the official `mcp` gem, auth via API key, OAuth later). Tools: search, read, create and re-status posts, comment, query votes and trends, read the roadmap. Claude, Cursor and other assistants can triage feedback directly. Among the self-hosted tools only Quackback has this otherwise.
- **Duplicate detection** while creating (#455): ✅ Postgres full-text search · open: optionally semantic with pgvector and embeddings, merging (post merge) with consolidated votes – so far only planned in the v3 schema (6.), but useful for v2 as well
- **AI features (opt-in, own model):** ✅ summarizing long discussions (moderators), ✅ suggested board and tags, ✅ changelog drafts, ✅ translating feedback
- Privacy: what goes to the AI provider is documented and can be switched off; a local model via Ollama is supported
- **Feedback from other sources via MCP** instead of own connectors: an assistant in Slack or Teams reads a thread and creates the post. All it needed was a "source/link" field on the post and "on behalf of" in `create_post`

### Phase 5 – Niche features · P2 (mostly done in 2.0.0-beta.1)
- ✅ **Changelog** with RSS and email to followers; ✅ **RSS per board** with the same technique
- ✅ **Digest for users** (opt-in: top requests, status changes of followed posts), extension of the existing recap emails for moderators
- ✅ **Trust levels:** check the first N posts of an account, then approve automatically (#362 family)
- ✅ **Private boards** (#414), ✅ **tags** (#171); ⬜ **attachments** (#253, #482; mind the storage rule: no Active Storage, decide between S3-compatible and Postgres, see todo.md)
- ⬜ **Import** from Canny, Fider and CSV (#368) to welcome switchers
- ✅ **Widget with visitor identification** (signed JWT per tenant from your own app): attributes widget votes to real customers, and "login from your own app" without OAuth
- ✅ **Embeddable widget**, ✅ **webhook templates** for Slack, Discord and Teams (#419), ✅ **signed webhooks** (HMAC header)
- ✅ **LDAP/SAML** (#8) for companies and agencies
- Later: **user segments** (filter or weight votes by customer group; needs visitor identification and custom fields #420, weighting is in the v3 schema) and **stale rules** (filter "X months without activity", automatic archiving as opt-in only)
- ✅ Quick wins from the issues: roadmap can be switched off (#361), default sorting (#193, #363, #483), OAuth-only login (#471), favicon (#452)

### Cross-cutting – project and community
- Take over the documentation from `astuto/astuto-docs` (check the license first) and update it for the new version → decided to write own guides in `docs/` (the upstream docs repository has no license)
- Translations: own platform (e.g. Weblate, free for open source), activate the 10 existing but disabled languages
- Release process: SemVer, `CHANGELOG.md`, signed images, release notes
- Visibility: entries at awesome-selfhosted and AlternativeTo, demo instance, announcement for earlier Astuto users
- Optional: rename the GitHub repository to `astuto-evolution` (GitHub redirects old links)

## 5. Milestones

| Version | Content | Criterion |
|---|---|---|
| `2.0.0-alpha` | Phase 1 + 2 | Rails 8.1, Ruby 4.0, PG 19, tests green, image on GHCR, migration from 1.x documented → ✅ alpha.3 (26.10.2026) |
| `2.0.0-beta` | + Phase 3 (public pages), MCP server | New frontend for all visitor pages, MCP with basic tools → ✅ **beta.1 (30.10.2026)**; open until GA: RTL translations, the sign-up-requirements decision (#30), a migration test against real data |
| `2.0.0` | + Phase 3 complete | React 16/Redux/Bootstrap 4 fully removed, docs adopted |
| `2.1` | Phase 4 | Duplicate detection, AI features, changelog → largely delivered in beta.1; still open: semantic duplicates (pgvector) |
| `2.2+` | Phase 5 | Widget, import, private boards, LDAP → largely delivered in beta.1; still open: attachments (#253), imports (#368) |
| `3.0.0` | Full TypeScript | TanStack Start + Drizzle + Tailwind, Rails gone, automatic data migration from v2 |

## 6. Preparing v3 – data model, migration, license

**New data model in v3, seamless upgrade from v2.** v3 gets its own clean schema (Drizzle). Existing v2 installations are migrated automatically at the first start of v3. For admins the upgrade stays a swap of the image tag.

| Area | v2 (Rails) | v3 (Drizzle) |
|---|---|---|
| IDs | sequential `bigint` | UUIDv7 (or internal `bigint` + public ID/slug), no enumerability |
| Tenants | `tenant_id` in every table (present) | carried over as `workspace` |
| Auth | Devise columns in `users`, own OAuth tables | separated: `user`, `session`, `account` (several OAuth providers, passkeys), e.g. Better Auth |
| Order (boards, statuses, roadmap) | integer `order` | fractional indexing: one `UPDATE` per drag-and-drop |
| Activity | `comments`, `post_status_changes` separate | one timeline (comments, status changes, merges) |
| Duplicates | – | `merged_into_post_id`, votes are merged |
| Votes | `likes` (user, post) | `votes` with weight/"on behalf of", cached counters |
| Search | `ILIKE` | `tsvector`, optionally `pgvector` for similar posts |

**Automatic migration v2 → v3** at container start: detect (`schema_migrations` present), then one transaction: move the data into the new schema, move old tables into `v2_archive`. Portability verified:
- Passwords: Devise uses bcrypt (cost 11, no pepper). The hashes are directly verifiable in Node/Bun, nobody must reset their password.
- API keys: HMAC with `SECRET_KEY_BASE`, reproducible in TypeScript.
- **Webhook URL and headers:** encrypted with `ActiveSupport::MessageEncryptor` (AES-256-GCM), content as **JSON** since 2.0 (the `ReencryptWebhooksAsJson` migration rewrote the old Marshal values). Decipherable in TypeScript with `node:crypto`: key = SHA-256 of `SECRET_KEY_BASE`, format `base64(data)--base64(iv)--base64(tag)`.

**The contract between v2 and v3 is the app API** (`/api/app/v1`, OpenAPI). The v2 frontend does not depend on the database schema. v3 implements the same endpoints on the new schema, and the frontend keeps running.

**Rules for v2 to keep the migration easy** (also in AGENTS.md): no `serialize`/`store` columns (native `jsonb`), no polymorphic associations, no Active Storage for files, no Ruby-specific formats in the database. The current state fulfils this.

**License (decided: AGPL-3.0):**
- v2 is a derived work and stays **AGPL-3.0** with the original copyright notices.
- **v3 stays AGPL-3.0**, dual-licensed if needed. The translated texts (YAML/JSON), the logo, schema knowledge and community contributions may be reused directly, and the AGPL protects the niche (self-hosting) from closed SaaS derivatives.
- If v3 should additionally get a commercial license for mid-size companies (section 7), a CLA is required from the first v3 commit.

**GitHub (decision open):** have GitHub detach the fork from the archived upstream (GitHub support) so code search and visibility work normally. Develop v3 in the same repository (orphan branch, moved to `main` at release, v2 as a `v2` branch) or in an organization `astuto-evolution`.

## 7. Commercial use in mid-size companies

**Goal:** free self-hosting stays the core. At the same time Astuto Evolution shall be fit for commercial use in mid-size companies (roughly 50–1,000 employees): internally, for customer portals and for several products.

**What this audience expects** (flows into the priorities of todo.md):
- **Identity:** SSO over OIDC (present: any OAuth2 provider), additionally **SAML** and **LDAP/AD** (#8), login only via SSO (#471), automatic roles from groups, **2FA/MFA for admins and moderators**
- **Tenants:** several portals per instance with their own domain and branding (present, tested and documented), administration via the instance admin `/instance`
- **Compliance:** audit log (who changed what), GDPR features (export and deletion per person, retention periods), data processing without third parties, AI only opt-in with their own model
- **Operations:** backup/restore guide, several web instances behind a load balancer, health-check endpoint, Prometheus metrics, Helm chart, signed images with SBOM
- **Trust:** `SECURITY.md` with a reporting path, security updates with deadlines, documented versions with a support window (LTS)
- **Integration:** Jira, Azure DevOps, Teams, Slack (webhook templates first), REST API and MCP

**License and mid-size companies:** AGPL-3.0 allows commercial use without restriction. Obligations only arise when someone *modifies* the code and offers it to users over the network: then they must publish the changes. Some legal departments reject AGPL on principle. Options:
- **v2:** an additional commercial license is not possible because the upstream code stands under third-party AGPL. Remedy: the ["AGPL in companies" FAQ](docs/agpl-faq.md) (unmodified operation obligates nothing).
- **v3 (new development):** dual licensing (AGPL + commercial license) becomes possible, but only with a **CLA** for all contributions from the beginning of v3 and without adopted upstream content (translations, logo). The license is decided: **v3 stays AGPL-3.0** (section 6).

**Possible revenue without a paywall** (decision open):

| Model | Fits | Prerequisite |
|---|---|---|
| Hosted variant (managed, EU hosting) | Companies without their own operations | Multi-tenancy (present); billing outside the software (billing is removed) |
| Support and SLA | Mid-size companies with their own installation | Versioning with LTS, a contact person |
| Commercial license | Legal departments that shy away from AGPL | only in v3, CLA |
| Setup and integration (services) | SSO, migration from Canny/UserVoice | Import feature (#368) |