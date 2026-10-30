# Competitor analysis – feedback boards (open source and proprietary)

As of: 24.10.2026. GitHub numbers queried directly. Prices and features come
mostly from vendor and comparison pages (often written by competitors). Verify
on the vendor page before making a decision.

## Summary

- **The market is crowded.** The upstream author names exactly that as the
  reason for shutting down: 3 paying customers in a year (#487).
- **Quackback is the strongest open-source competitor.** Very active (since
  12/2025, v0.14), AGPL like Astuto, but much broader: changelog, support
  inbox, help center, status page, AI, MCP server, 25+ integrations.
- **Fider is the mature classic** (since 2017, ~4,600 stars, Go, very lean in
  resources). Feature-wise narrower than Astuto, but steadily maintained.
- **Proprietary tools** differ mainly through **pricing models** (Canny: per
  tracked user — expensive when you succeed) and through **scope**: Featurebase
  and UserJot are growing into support suites with AI agents.
- **Astuto's gaps** versus practically everyone: changelog, duplicate
  detection, embeddable widget, native integrations (Linear, Jira, GitHub,
  Slack), private boards, file upload, AI.
- **Astuto's strengths:** anonymous feedback with a moderation queue, freely
  shaped Liquid webhooks, arbitrary OAuth2 providers, REST API, a single
  Docker image, low resource usage.

## Market overview

### Open source

| Tool | License | Stack | Activity | Hosting |
|---|---|---|---|---|
| **Astuto** (this fork) | AGPL-3.0 | Rails 6.1, React 16, Postgres | Upstream archived 01/2026 | Docker (1 image + Postgres) |
| **Fider** | AGPL-3.0 | Go, React, Postgres | active, v0.38.2 (10/2026), ★4,586 | Docker, ~256 MB RAM; Cloud Free/Pro |
| **Quackback** | AGPL-3.0 + CLA | TypeScript (TanStack Start, Bun), Postgres, S3 | very active, v0.14.1 (10/2026), ★327 | Docker Compose, Railway; Cloud with free plan |
| **LogChimp** | Open core (MIT + `ee/` license) | Node.js, Vue, Postgres | active, v0.9.2 (09/2026), ★1,132, 181 open issues/PRs | self-built image; per comparison sites no official Docker image |
| **ClearFlask** | Apache-2.0 (per GitHub) | Java/Tomcat, React, Node | active, v2.7.0 (10/2026), ★450 | Docker/Helm; needs DynamoDB-compatible, S3, MySQL or Elasticsearch; JVM ≥ 2 GB |

### Proprietary (SaaS)

| Tool | Pricing (~, per comparison sites) | Positioning |
|---|---|---|
| **Canny** | Free up to 25 tracked users; Pro from $79/month for 100 users, ~$529 at 1,000 | Market leader, "Autopilot" AI, many integrations |
| **Featurebase** | per admin seat from $29/month + fee per AI resolution; Free with 1 seat | Feedback + roadmap + changelog + help center + inbox + surveys (NPS/CSAT) |
| **UserJot** | Free (unlimited users, 2 boards), $29, $59 flat | Flat pricing, widget, live chat, AI agent, MCP server, Canny import |
| **Frill** | from $25/month (entry tier: 50 active ideas) | simple boards + roadmap + changelog |
| **Nolt** | $29 (1 board) / $69, no free plan | pretty UI, few features |
| **Upvoty** | from $15/month, no free plan | cheap, strict limits |
| **Sleekplan** | Free (1 admin), from $13/month | cheap widget + board + changelog |
| **ProductLift** | from $19/month, admins + AI credits | prioritization (RICE/ICE), anonymous voting |
| **Productboard** | Enterprise | product management suite; the feedback portal is just a part |
| **UserVoice** | Enterprise (~$899–1,333/month) | large enterprise feedback program |

## Individual analysis

### Quackback (open source)
**On top of Astuto:** duplicate detection while typing, including merging with
votes, private boards, segments, changelog with email and RSS, roadmap with
auto-sync from Linear and GitHub, support inbox (chat, email, tickets, SLAs),
help center, status page, one shared widget for web, iOS and Android, AI
(agent, summaries, translation), MCP server, signed webhooks, OpenAPI, 25+
integrations (Linear, Jira, GitHub, GitLab, Slack, Teams, Discord, Zendesk,
Intercom, HubSpot, Zapier, n8n …).
**Problems:** very young (first commit 12/2025, still v0.x), small community,
very fast restructuring. Telemetry is on by default. Contributions need a CLA,
which makes a license change by the vendor possible. Open wishes: file upload
(#193), email notifications (#258), Helm chart (#322), Teams integration
(#255). The focus is shifting towards a support suite.

### Fider (open source)
**On top of Astuto:** tags, file attachments, RTL languages, very low resource
usage (Go binary), long track record of stability, well-kept cloud.
**Problems:** feature-wise narrow: no changelog, per comparison sites no
dedicated roadmap view, no duplicate detection, no native tracker
integrations, no AI. Open core in the cloud (moderation and SEO indexing only
in the Pro plan at $25). Most-wanted open issues: LDAP (#1018), visitor tags
(#1211), auto-login (#1123), running under a subpath (#1453), OAuth logout bug
(#1093). These are the same topics as Astuto's.

### LogChimp (open source)
**On top of Astuto:** hardly anything; boards, roadmap, statuses, API and email
notifications are at a similar level.
**Problems:** open core (parts under `packages/server/ee` with their own
license), stuck at v0.x for years, 181 open issues/PRs, the most-wanted issues
are "Next Release?" (#902) and "Demo" (#816). Documentation is thin, there is
no ready-made Docker image. Open security topics: CORS (#1432), bcrypt (#1502).

### ClearFlask (open source)
**On top of Astuto:** several voting types (including credit voting and
reactions), roadmap with timeline and column views, changelog with
subscribers, user segments, simple analytics, fuzzy search (Elasticsearch),
white-label and custom domains, Helm charts.
**Problems:** very heavy to self-host: Java + Node + DynamoDB-compatible store
+ S3 + MySQL or Elasticsearch + KillBill billing. At least 2 GB RAM. Small
community, GitHub issues practically unused.

### Canny (proprietary)
**On top of Astuto:** "Autopilot" AI (extracts feedback from support tickets
and calls, detects duplicates), changelog, revenue linkage (Business plan), a
great many integrations (Intercom, Zendesk, Jira, Linear, HubSpot, Salesforce),
user identification via SDK.
**Problems:** price per tracked user — the jump from free to paid is often
criticized as "predatory", and costs grow with participation. "Powered by
Canny" on smaller plans. No anonymous posting, only identified users. No
knowledge base, no prioritization frameworks.

### Featurebase (proprietary)
**On top of Astuto:** an all-in-one package of feedback, roadmap, changelog,
help center, inbox, tickets, "Fibi" AI agent plus NPS, CSAT, CES and PMF
surveys; in-app widgets; Linear integration.
**Problems:** per-seat price plus a fee per AI resolution — expensive for teams
that only need a board. Slack integration is considered shallow. Custom domain
only on paid plans. Young company.

### UserJot (proprietary)
**On top of Astuto:** flat pricing with unlimited users, widget (feedback,
roadmap, updates, chat), guest posting with approval, duplicate detection,
Canny importer, CSV export, AI agent (answers chats, creates requests, drafts
changelogs), MCP server, dark mode.
**Problems:** SSO and unlimited integrations only from $59. Young product. The
comparison pages come from the vendor itself.

### Frill, Nolt, Upvoty, Sleekplan, ProductLift
**On top of Astuto:** changelog or widget (Frill, Sleekplan), prioritization
frameworks (ProductLift), anonymous voting (ProductLift, Upvoty).
**Problems:** tight limits in entry plans (Frill: 50 active ideas; Nolt: 1
board; Upvoty: strict limits, no free plan). Per comparison sites Sleekplan
lacks private boards and prioritization. Nolt has a nice UI but few features.

### Productboard, UserVoice
Enterprise product management with a feedback portal as one building block:
insights linkage, prioritization, roadmapping for stakeholders. **Problems:**
very expensive, oversized for a plain feedback board. UserVoice has weak public
ratings (Trustpilot ~2.8/5).

## Feature matrix (core features)

✓ = available · ~ = partial / paid only · ✗ = missing · ? = unclear

The **Astuto column reflects upstream Astuto 1.x.** Astuto Evolution
2.0.0-beta.1 has since closed most of these gaps: changelog, tags (#171),
private boards (#414), the embeddable widget with visitor identification,
duplicate detection with merging (#455), the MCP server, AI summaries,
suggestions and translation, Slack/Discord/Teams webhook templates (#419) and
signed webhooks. Still open: file upload (#253) and imports (#368).

| Feature | Astuto | Fider | Quackback | ClearFlask | Canny | Featurebase | UserJot |
|---|---|---|---|---|---|---|---|
| Boards, votes, comments | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Public roadmap | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Changelog | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Anonymous feedback + moderation queue | ✓ | ~ | ? | ? | ✗ | ? | ✓ |
| Private boards | ✗ (#414) | ✗ | ✓ | ? | ✓ | ✓ | ~ |
| Tags | ✗ (#171) | ✓ | ✓ | ✓ | ✓ | ✓ | ? |
| File/image upload | ✗ (#253) | ✓ | ✗ (#193) | ✓ | ✓ | ✓ | ? |
| Duplicate detection / merge | ✗ (#455) | ✗ | ✓ | ? | ✓ | ✓ | ✓ |
| Embeddable widget | ✗ | ✗ | ✓ | ? | ✓ | ✓ | ✓ |
| OAuth2 / SSO | ✓ (any OAuth2) | ✓ | ✓ (OIDC) | ✓ | ~ | ~ | ~ |
| Webhooks | ✓ (Liquid) | ✓ | ✓ (signed) | ✓ | ✓ | ✓ | ? |
| REST API | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Native tracker integration (Linear, Jira, GitHub) | ✗ | ✗ | ✓ | ✗ | ✓ | ✓ | ~ |
| Slack/Discord/Teams | ~ (via webhook) | ~ | ✓ | ? | ✓ | ~ | ✓ |
| AI (summary, agent) | ✗ | ✗ | ✓ | ✗ | ✓ | ✓ | ✓ |
| MCP server | ✗ | ✗ | ✓ | ✗ | ? | ? | ✓ |
| Import (Canny/CSV) | ✗ (#368) | ? | ? | ? | – | ✓ | ✓ |
| Self-hosting | ✓ easy | ✓ very easy | ✓ medium | ~ laborious | ✗ | ✗ | ✗ |

## Shared problems of the niche (opportunities for the fork)

1. **Pricing punishes success** (Canny per user, Featurebase per seat plus AI
   fee). Self-hosting without limits is a clear argument.
2. **Forced sign-in lowers participation.** Astuto already does anonymous
   feedback with moderation, which hardly anyone has solved properly.
3. **Self-hosting open-source tools is often painful** (ClearFlask, LogChimp)
   or features end up behind a paywall (Fider Cloud, LogChimp EE).
4. **The same operational problems everywhere:** OAuth behind a proxy, LDAP,
   auto-login, subpath hosting (Fider #1093, #1018, #1123, #1453 correspond to
   Astuto #472, #8, #263, #478).
5. **Suite drift:** Featurebase, UserJot and Quackback are becoming support
   platforms. Whoever wants a lean board finds fewer and fewer options.

## Positioning and consequence for the roadmap

**Possible niche for the fork:** "A lean, privacy-friendly self-hosted feedback
portal without user limits, with anonymous feedback and moderation, that works
behind every proxy right away." For the DACH region GDPR compliance could be an
argument: data stays in-house, no telemetry.

**Decision (24.10.2026):** the project continues as **Astuto Evolution** for
exactly this niche, with a UI rebuild and AI/MCP (see [roadmap.md](roadmap.md)).
The following assessment answered the personal-use question:

**Assessment for personal use:**
- If you **need a feedback portal for yourself** and plan no custom changes,
  **Quackback** (broad, active) or **Fider** (simple, stable) take less effort
  today than modernizing Astuto.
- If you want **your own adjustments**, full control over code and data, or a
  Rails project to develop further, the Astuto fork is worth continuing. The
  base is solid, and the most important gaps are manageable.
- **Rewriting from scratch is worth it even less than before:** Quackback is
  essentially already the modern rebuild of a Canny clone, as open source and
  with a big head start.

**Gaps with the best value-to-effort ratio** (adopted into `roadmap.md`
phases 4 and 5 and into `todo.md`):
1. Changelog (linked to done posts, RSS and email to followers)
2. Duplicate search while creating (#455), cheap to build with Postgres
   full-text search
3. Tags (#171) and private boards (#414)
4. File/image upload (#253, upstream PR #454 as a base)
5. Slack/Discord/Teams templates for the existing webhooks (#419)
6. MCP server on top of the existing REST API (small effort, a unique selling
   point among self-hosted tools other than Quackback)
7. Import from Canny and CSV (#368) to welcome switchers
8. Embeddable widget (bigger, but standard at all SaaS tools)

## Sources

- GitHub API: getfider/fider, QuackbackIO/quackback, logchimp/logchimp,
  clearflask/clearflask (license, stars, releases, issues; queried 24.10.2026)
- [Quackback README](https://github.com/QuackbackIO/quackback) ·
  [ClearFlask README](https://github.com/clearflask/clearflask) ·
  [Fider Pricing](https://fider.io/pricing)
- [Quackback: Best Open Source Feedback Tools 2026](https://quackback.io/blog/open-source-feedback-tools)
  (vendor blog; some Astuto claims are wrong: roadmap and OAuth exist, the
  license is AGPL)
- [Pickafeature: Open Source Canny Alternatives](https://pickafeature.com/blog/open-source-canny-alternative)
  · [Formbricks: Canny Alternatives](https://formbricks.com/blog/canny-alternatives)
  · [Featurebase: Canny Alternatives](https://www.featurebase.app/blog/canny-alternatives)
- [UserJot: Canny comparison](https://userjot.com/compare/canny-alternative)
  · [ProductLift: Feature Voting Tools 2026](https://www.productlift.dev/best-feature-voting-tool/)
  · [ProductLift: Canny Pricing](https://www.productlift.dev/blog/canny-pricing/)
  · [FeatureOS: Canny Pricing 2026](https://featureos.com/blog/canny-pricing-2026)
- [G2: Canny Reviews](https://www.g2.com/products/canny/reviews) ·
  [WishKit: Featurebase Review](https://www.wishkit.io/blog/featurebase-review)
  · [Product Hunt: Featurebase Reviews](https://www.producthunt.com/products/featurebase/reviews)
  · [featurevote.app: Feature Voting Tools 2026](https://featurevote.app/blog/feature-voting-tools-2026)