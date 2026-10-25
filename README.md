<p align="center">
  <img width="460" alt="Astuto Evolution (Evo)" src="./images/logo-and-name.png" />
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
- **Moderation Queue:** decide whether to show new feedback immediately or request approval
- **Anonymous Feedback:** enable unregistered users to publish feedback
- **... and more:** invitation system, brand customization, recap emails for administrators, private site settings, 10+ languages

## What changes compared to Astuto 1.x

| | Astuto 1.x (archived) | Astuto Evolution 2.0 |
|---|---|---|
| Ruby / Rails | 3.0 / 6.1 (end of life) | 4.0 / 8.1 |
| PostgreSQL | 14 (EOL 11/2026) | 18 (19 once it is released) |
| Docker image | `riggraz/astuto` (amd64) | `ghcr.io/nkoeberlein/astuto` (amd64 + arm64) |
| User interface | React 16, Bootstrap 4 | being rebuilt (React 19, TypeScript, Tailwind), public pages under `/next` |
| AI / MCP | – | MCP server, opt-in AI discussion summary |

Upgrading an existing Astuto installation: see [UPGRADING.md](UPGRADING.md).

## Get started

**2.0.0-alpha.2** is available as `ghcr.io/nkoeberlein/astuto:2.0.0-alpha.2` (amd64 + arm64) for testing. It is an alpha: back up your database before trying it on existing data, and see [CHANGELOG.md](CHANGELOG.md) for what is done and what is missing.

To run it from source:

1. Install Docker and Docker Compose
2. Clone the repository:
   ```
   git clone https://github.com/nkoeberlein/astuto.git astuto-evolution
   cd astuto-evolution
   ```
3. Start it:
   ```
   docker compose up
   ```
   If port 3000 is taken on your machine, use another one: `ASTUTO_PORT=3456 docker compose up`
4. Open http://localhost:3000. In development, a default account is created with email `admin@example.com` and password `password`. The production image instead generates a random password and prints it once in the container log on the first start; set `ADMIN_EMAIL` and `ADMIN_PASSWORD` to choose your own.

## Documentation

The original documentation still applies and lives in the archived [astuto/astuto-docs](https://github.com/astuto/astuto-docs) repository. It will move into this repository over time.

## Contributing

Proposing features, reporting issues, translating and improving documentation are as welcome as code. Please read the [contributing guidelines](CONTRIBUTING.md) and use the [issue tracker](https://github.com/nkoeberlein/astuto/issues).

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
