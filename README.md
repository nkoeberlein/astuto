<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="./images/logo-and-name-dark.png" />
    <img width="460" alt="Astuto Evolution (Evo)" src="./images/logo-and-name.png" />
  </picture>
</p>

<h1 align="center">Astuto Evolution (Evo) 🦊</h1>

<p align="center">
  The community continuation of Astuto – a free, open source, self-hosted customer feedback tool.<br/>
  Same roots, new start.
</p>

> **Astuto Evolution continues [astuto/astuto](https://github.com/astuto/astuto)**, created by [@riggraz](https://github.com/riggraz) and archived in January 2026 ([end-of-life announcement](https://github.com/astuto/astuto/issues/487)).
> It keeps everything Astuto already does and moves it forward: a current, secure stack, a new user interface and AI-native features such as an MCP server.
>
> **Status:** work in progress towards **2.0**. Not released yet – see the [roadmap](roadmap.md).

Astuto Evolution helps you collect, manage and prioritize feedback from your customers, so you can build a better product.

<img src="./images/hero-image.png" />

## Why Astuto Evolution

- **Self-hosted, no user limits:** no per-user or per-seat pricing, your data stays on your server.
- **Feedback without sign-up:** anonymous feedback with a moderation queue keeps participation high.
- **Simple to run:** one Docker image plus PostgreSQL.
- **Open integration:** REST API, flexible webhooks (Liquid templates), any OAuth2 provider.
- **AI-native (planned for 2.x):** MCP server so assistants like Claude can search, summarize and triage feedback; duplicate detection.

## Features

- **Roadmap:** show users what you're working on
- **Simple Sign In:** let users log in with email or any OAuth2 provider
- **Webhooks:** integrate with your existing tools (e.g. Jira, Trello, Slack)
- **API:** programmatically manage your feedback space with the REST API
- **Moderation Queue:** decide whether to show new feedback immediately or request approval (always, for anonymous feedback, or for the first posts of each account)
- **Anonymous Feedback:** enable unregistered users to publish feedback
- **... and more:** invitation system, brand customization, recap emails for administrators, private site settings, 10+ languages

## What changes compared to Astuto 1.x

| | Astuto 1.x (archived) | Astuto Evolution 2.0 |
|---|---|---|
| Ruby / Rails | 3.0 / 6.1 (end of life) | 4.0 / 8.1 |
| PostgreSQL | 14 (EOL 11/2026) | 18 (19 once it is released) |
| Docker image | `riggraz/astuto` (amd64) | `ghcr.io/nkoeberlein/astuto-evo` (amd64 + arm64) |
| User interface | React 16, Bootstrap 4 | rebuilt: React 19, TypeScript, Tailwind, every page at `/` |
| AI / MCP | – | MCP server, opt-in AI discussion summary |

Upgrading an existing Astuto installation: see [UPGRADING.md](UPGRADING.md).

## Planned features

> Nothing below is released yet. Status and priorities: [roadmap.md](roadmap.md), tasks: [todo.md](todo.md).

### In v2 (towards 2.0)

- **New UI** (React 19 + TanStack) for every page: boards, posts, roadmap, embedding, login / sign-up / password with OAuth, moderation, all site settings, profile. The legacy React 16 / Redux / Bootstrap 4 frontend and its gems and packages are gone
- **Design system:** branding over CSS variables (reusing your current site colors), dark mode, WCAG 2.2 AA, mobile first
- **AI-native features:** MCP server under `/mcp` with API-key auth (already part of the alpha) so assistants like Claude, Cursor and others can search, read, create and triage feedback; duplicate detection while posting (Postgres full-text search, optionally semantic with pgvector); discussion summaries and tag/board suggestions, all strictly opt-in per site settings
- **Operations:** webhook error visibility (delivery log per webhook), "send test mail" for site settings, configurable favicon and header links, roadmap can be disabled, instance-wide default sort order, OAuth-only login option
- **Several feedback spaces per instance** (multi-tenancy) with subdomains, custom domains with automatic TLS and an instance admin page, for companies with several products or brands

### In v3 (major upgrade, fully TypeScript)

- **Full TypeScript rewrite:** [TanStack Start](https://tanstack.com/start) + Drizzle (PostgreSQL) + Tailwind; Rails is dropped. The decision has been made (see roadmap, section 3); the v2 React frontend carries over unchanged, so v3 becomes a backend swap (endpoint by endpoint)
- **New data model** with upgrade-path guarantees: UUIDv7 ids, unified activity timeline, votes with weight, full-text search (optional pgvector). Existing 2.x installations migrate automatically on first start of v3, old tables are archived — for admins the upgrade stays a Docker image tag change
- **Modern auth:** e.g. Better Auth with multiple OAuth providers and passkeys
- **Everything ported:** webhooks (Liquid templates), mails, background jobs and the MCP server move to TypeScript; SSR for public boards for SEO
- **Licensing stays AGPL-3.0** in v3; a commercial dual-license is possible only via CLA from the first v3 commit (see roadmap, section 6/7)

## Get started

**2.0.0-alpha.3** is available as `ghcr.io/nkoeberlein/astuto-evo:2.0.0-alpha.3` (amd64 + arm64) for testing. It is an alpha: back up your database before trying it on existing data, and see [CHANGELOG.md](CHANGELOG.md) for what is done and what is missing.

To run it from source:

1. Install Docker and Docker Compose
2. Clone the repository:
   ```
   git clone https://github.com/nkoeberlein/astuto-evo.git astuto-evo
   cd astuto-evo
   ```
3. Start it:
   ```
   docker compose up
   ```
   If port 3000 is taken on your machine, use another one: `ASTUTO_PORT=3456 docker compose up`
4. Open http://localhost:3000. In development, a default account is created with email `admin@example.com` and password `password`. The production image instead generates a random password and prints it once in the container log on the first start; set `ADMIN_EMAIL` and `ADMIN_PASSWORD` to choose your own.

## Documentation

Guides in this repository:

- [Reverse proxy, HTTPS, database and SMTP](docs/reverse-proxy-and-smtp.md)
- [Operations: health checks, metrics, background jobs, backups, Kubernetes](docs/operations.md)
- [Multi-tenancy: several feedback spaces, custom domains, instance admin](docs/multi-tenancy.md)
- [Webhooks: templates, signatures, delivery log](docs/webhooks.md)
- [MCP server and AI features](docs/mcp-and-ai.md)
- [Single sign-on: OAuth and SAML](docs/sso.md)
- [Account lockout](docs/account-lockout.md) and [two-factor authentication](docs/two-factor-authentication.md)
- [Privacy and GDPR: stored data, export, deletion, retention](docs/privacy.md)
- [AGPL in companies: FAQ](docs/agpl-faq.md)

The original documentation of Astuto 1.x lives in the archived [astuto/astuto-docs](https://github.com/astuto/astuto-docs) repository and will move here over time.

## Contributing

Proposing features, reporting issues, translating and improving documentation are as welcome as code. Please read the [contributing guidelines](CONTRIBUTING.md) and use the [issue tracker](https://github.com/nkoeberlein/astuto-evo/issues).

## Credits

Astuto was created by [Riccardo Graziosi (@riggraz)](https://github.com/riggraz). Thank you for building it and for releasing it as open source.

Astuto logo and all image assets are credited [here](https://github.com/astuto/astuto-io/blob/main/src/pages/Credits.jsx).

A huge thank you to everyone who contributed code to the original project

<a href="https://github.com/astuto/astuto/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=astuto/astuto" />
</a>

and to the [translation contributors](https://crowdin.com/project/astuto/members)!

## License

[GNU AGPL-3.0](LICENSE), like the original project.
