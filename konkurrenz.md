# Konkurrenzanalyse – Feedback-Boards (Open Source und proprietär)

Stand: 24.10.2026. GitHub-Zahlen direkt abgefragt. Preise und Features stammen überwiegend aus Hersteller- und Vergleichsseiten (oft von Konkurrenten verfasst). Vor einer Entscheidung auf der jeweiligen Herstellerseite prüfen.

## Kurzfazit

- **Der Markt ist voll.** Der Upstream-Autor nennt genau das als Grund für das Aus: 3 zahlende Kunden in einem Jahr (#487).
- **Quackback ist der stärkste Open-Source-Konkurrent.** Sehr aktiv (seit 12/2025, v0.14), AGPL wie Astuto, aber viel breiter: Changelog, Support-Inbox, Help Center, Statusseite, KI, MCP-Server, 25+ Integrationen.
- **Fider ist der reife Klassiker** (seit 2017, ca. 4.600 Sterne, Go, sehr ressourcenschonend). Funktional schmaler als Astuto, aber stabil gepflegt.
- **Proprietäre Tools** unterscheiden sich vor allem über **Preismodelle** (Canny: pro getrackten Nutzer, teuer bei Erfolg) und über den **Umfang**: Featurebase und UserJot wachsen zu Support-Suiten mit KI-Agenten.
- **Astutos Lücken** gegenüber praktisch allen: Changelog, Duplikaterkennung, einbettbares Widget, native Integrationen (Linear, Jira, GitHub, Slack), private Boards, Datei-Upload, KI.
- **Astutos Stärken:** anonymes Feedback mit Moderationsqueue, frei gestaltbare Liquid-Webhooks, beliebige OAuth2-Anbieter, REST-API, ein einziges Docker-Image, geringer Ressourcenbedarf.

## Marktüberblick

### Open Source

| Tool | Lizenz | Stack | Aktivität | Hosting |
|---|---|---|---|---|
| **Astuto** (dieser Fork) | AGPL-3.0 | Rails 6.1, React 16, Postgres | Upstream archiviert 01/2026 | Docker (1 Image + Postgres) |
| **Fider** | AGPL-3.0 | Go, React, Postgres | aktiv, v0.38.2 (10/2026), ★4.586 | Docker, ca. 256 MB RAM; Cloud Free/Pro |
| **Quackback** | AGPL-3.0 + CLA | TypeScript (TanStack Start, Bun), Postgres, S3 | sehr aktiv, v0.14.1 (10/2026), ★327 | Docker Compose, Railway; Cloud mit Free-Plan |
| **LogChimp** | Open Core (MIT + `ee/`-Lizenz) | Node.js, Vue, Postgres | aktiv, v0.9.2 (09/2026), ★1.132, 181 offene Issues/PRs | eigener Build; laut Vergleichsseite kein offizielles Docker-Image |
| **ClearFlask** | Apache-2.0 (laut GitHub) | Java/Tomcat, React, Node | aktiv, v2.7.0 (10/2026), ★450 | Docker/Helm; braucht DynamoDB-kompatibel, S3, MySQL oder Elasticsearch; JVM ≥ 2 GB |

### Proprietär (SaaS)

| Tool | Preismodell (ca., laut Vergleichsseiten) | Positionierung |
|---|---|---|
| **Canny** | Free bis 25 getrackte Nutzer; Pro ab $79/Monat für 100 Nutzer, ca. $529 bei 1.000 | Marktführer, KI „Autopilot“, viele Integrationen |
| **Featurebase** | pro Admin-Seat ab $29/Monat + Gebühr je KI-Auflösung; Free mit 1 Seat | Feedback + Roadmap + Changelog + Help Center + Inbox + Umfragen (NPS/CSAT) |
| **UserJot** | Free (unbegrenzte Nutzer, 2 Boards), $29, $59 pauschal | Pauschalpreis, Widget, Live-Chat, KI-Agent, MCP-Server, Canny-Import |
| **Frill** | ab $25/Monat (Einstieg: 50 aktive Ideen) | schlichte Boards + Roadmap + Changelog |
| **Nolt** | $29 (1 Board) / $69, kein Free-Plan | schöne Oberfläche, wenig Features |
| **Upvoty** | ab $15/Monat, kein Free-Plan | günstig, strikte Limits |
| **Sleekplan** | Free (1 Admin), ab $13/Monat | günstiges Widget + Board + Changelog |
| **ProductLift** | ab $19/Monat, Admins + KI-Credits | Priorisierung (RICE/ICE), anonymes Voting |
| **Productboard** | Enterprise | Produktmanagement-Suite; Feedback-Portal ist nur ein Teil |
| **UserVoice** | Enterprise (ca. $899–1.333/Monat) | großes Enterprise-Feedbackprogramm |

## Einzelanalyse

### Quackback (Open Source)
**Zusätzlich zu Astuto:** Duplikaterkennung beim Tippen samt Zusammenführen mit Votes, private Boards, Segmente, Changelog mit E-Mail und RSS, Roadmap mit Auto-Sync aus Linear und GitHub, Support-Inbox (Chat, E-Mail, Tickets, SLAs), Help Center, Statusseite, ein gemeinsames Widget für Web, iOS und Android, KI (Agent, Zusammenfassungen, Übersetzung), MCP-Server, signierte Webhooks, OpenAPI, 25+ Integrationen (Linear, Jira, GitHub, GitLab, Slack, Teams, Discord, Zendesk, Intercom, HubSpot, Zapier, n8n …).
**Probleme:** Sehr jung (erster Commit 12/2025, noch v0.x), kleine Community, sehr schneller Umbau. Telemetrie ist standardmäßig an. Beiträge brauchen eine CLA, damit ist ein Lizenzwechsel durch den Hersteller möglich. Offene Wünsche: Datei-Upload (#193), E-Mail-Benachrichtigungen (#258), Helm-Chart (#322), Teams-Integration (#255). Der Fokus verschiebt sich Richtung Support-Suite.

### Fider (Open Source)
**Zusätzlich zu Astuto:** Tags, Datei-Anhänge, RTL-Sprachen, sehr geringer Ressourcenbedarf (Go-Binary), lange Stabilität, gepflegte Cloud.
**Probleme:** Funktional schmal: kein Changelog, laut Vergleichsseiten keine eigene Roadmap-Ansicht, keine Duplikaterkennung, keine nativen Tracker-Integrationen, keine KI. Open Core in der Cloud (Moderation und SEO-Indexierung nur im Pro-Plan für $25). Meistgewünschte offene Issues: LDAP (#1018), Tags durch Besucher (#1211), Auto-Login (#1123), Betrieb unter einem Unterpfad (#1453), OAuth-Logout-Bug (#1093). Das sind dieselben Themen wie bei Astuto.

### LogChimp (Open Source)
**Zusätzlich zu Astuto:** kaum etwas; Boards, Roadmap, Status, API und E-Mail-Benachrichtigungen sind auf ähnlichem Niveau.
**Probleme:** Open Core (Teile unter `packages/server/ee` mit eigener Lizenz), seit Jahren v0.x, 181 offene Issues/PRs, die meistgewünschten Issues sind „Next Release?“ (#902) und „Demo“ (#816). Die Doku ist dünn, es gibt kein fertiges Docker-Image. Offene Sicherheitsthemen: CORS (#1432), bcrypt (#1502).

### ClearFlask (Open Source)
**Zusätzlich zu Astuto:** mehrere Abstimmungsarten (inkl. Credit-Voting und Reaktionen), Roadmap mit Timeline- und Spaltenansicht, Changelog mit Abonnenten, Nutzersegmente, einfache Analytics, unscharfe Suche (Elasticsearch), White-Label und eigene Domains, Helm-Charts.
**Probleme:** Für Self-Hosting sehr schwer: Java + Node + DynamoDB-kompatibler Speicher + S3 + MySQL oder Elasticsearch + KillBill-Billing. Mindestens 2 GB RAM. Kleine Community, Issues auf GitHub praktisch nicht genutzt.

### Canny (proprietär)
**Zusätzlich:** KI „Autopilot“ (extrahiert Feedback aus Support-Tickets und Calls, erkennt Duplikate), Changelog, Umsatzverknüpfung (Business-Plan), sehr viele Integrationen (Intercom, Zendesk, Jira, Linear, HubSpot, Salesforce), Nutzer-Identifikation per SDK.
**Probleme:** Preis pro getrackten Nutzer, der Sprung von Free zu Paid wird oft als „predatory“ kritisiert, und die Kosten steigen mit der Beteiligung. „Powered by Canny“ in kleinen Plänen. Kein anonymes Posten bzw. nur identifizierte Nutzer. Kein Knowledge Base, keine Priorisierungs-Frameworks.

### Featurebase (proprietär)
**Zusätzlich:** Komplettpaket aus Feedback, Roadmap, Changelog, Help Center, Inbox, Tickets, KI-Agent „Fibi“ sowie NPS-, CSAT-, CES- und PMF-Umfragen; In-App-Widgets; Linear-Integration.
**Probleme:** Pro-Seat-Preis plus Gebühr je KI-Auflösung, also teuer für Teams, die nur ein Board brauchen. Slack-Integration gilt als flach. Eigene Domain erst in bezahlten Plänen. Junge Firma.

### UserJot (proprietär)
**Zusätzlich:** Pauschalpreis mit unbegrenzten Nutzern, Widget (Feedback, Roadmap, Updates, Chat), Gast-Posting mit Freigabe, Duplikaterkennung, Canny-Importer, CSV-Export, KI-Agent (beantwortet Chats, legt Requests an, entwirft Changelogs), MCP-Server, Dark Mode.
**Probleme:** SSO und unbegrenzte Integrationen erst ab $59. Junges Produkt. Die Vergleichsseiten stammen vom Hersteller selbst.

### Frill, Nolt, Upvoty, Sleekplan, ProductLift
**Zusätzlich:** Changelog bzw. Widget (Frill, Sleekplan), Priorisierungs-Frameworks (ProductLift), anonymes Voting (ProductLift, Upvoty).
**Probleme:** enge Limits in den Einstiegsplänen (Frill: 50 aktive Ideen; Nolt: 1 Board; Upvoty: strikte Limits, kein Free-Plan). Laut Vergleichsseiten fehlen Sleekplan private Boards und Priorisierung. Nolt hat eine schöne Oberfläche, aber wenig Funktionen.

### Productboard, UserVoice
Enterprise-Produktmanagement mit Feedback-Portal als einem Baustein: Insights-Verknüpfung, Priorisierung, Roadmapping für Stakeholder. **Probleme:** sehr teuer, für ein reines Feedback-Board überdimensioniert. UserVoice hat schwache öffentliche Bewertungen (Trustpilot ca. 2,8/5).

## Feature-Matrix (Kernfunktionen)

✓ = vorhanden · ~ = teilweise / nur bezahlt · ✗ = fehlt · ? = unklar

| Funktion | Astuto | Fider | Quackback | ClearFlask | Canny | Featurebase | UserJot |
|---|---|---|---|---|---|---|---|
| Boards, Votes, Kommentare | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Öffentliche Roadmap | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Changelog | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Anonymes Feedback + Moderationsqueue | ✓ | ~ | ? | ? | ✗ | ? | ✓ |
| Private Boards | ✗ (#414) | ✗ | ✓ | ? | ✓ | ✓ | ~ |
| Tags | ✗ (#171) | ✓ | ✓ | ✓ | ✓ | ✓ | ? |
| Datei-/Bild-Upload | ✗ (#253) | ✓ | ✗ (#193) | ✓ | ✓ | ✓ | ? |
| Duplikaterkennung / Merge | ✗ (#455) | ✗ | ✓ | ? | ✓ | ✓ | ✓ |
| Einbettbares Widget | ✗ | ✗ | ✓ | ? | ✓ | ✓ | ✓ |
| OAuth2 / SSO | ✓ (beliebige OAuth2) | ✓ | ✓ (OIDC) | ✓ | ~ | ~ | ~ |
| Webhooks | ✓ (Liquid) | ✓ | ✓ (signiert) | ✓ | ✓ | ✓ | ? |
| REST-API | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Native Tracker-Integration (Linear, Jira, GitHub) | ✗ | ✗ | ✓ | ✗ | ✓ | ✓ | ~ |
| Slack/Discord/Teams | ~ (per Webhook) | ~ | ✓ | ? | ✓ | ~ | ✓ |
| KI (Zusammenfassung, Agent) | ✗ | ✗ | ✓ | ✗ | ✓ | ✓ | ✓ |
| MCP-Server | ✗ | ✗ | ✓ | ✗ | ? | ? | ✓ |
| Import (Canny/CSV) | ✗ (#368) | ? | ? | ? | – | ✓ | ✓ |
| Self-Hosting | ✓ einfach | ✓ sehr einfach | ✓ mittel | ~ aufwendig | ✗ | ✗ | ✗ |

## Gemeinsame Probleme der Branche (Chancen für den Fork)

1. **Preismodelle bestrafen Erfolg** (Canny pro Nutzer, Featurebase pro Seat plus KI-Gebühr). Self-Hosting ohne Limits ist ein klares Argument.
2. **Sign-in-Zwang** senkt die Beteiligung. Astuto kann schon anonymes Feedback mit Moderation, das hat kaum jemand sauber gelöst.
3. **Self-Hosting ist bei Open-Source-Tools oft mühsam** (ClearFlask, LogChimp) oder Funktionen landen hinter einer Paywall (Fider Cloud, LogChimp EE).
4. **Dieselben Betriebsprobleme überall:** OAuth hinter Proxy, LDAP, Auto-Login, Unterpfad-Hosting (Fider #1093, #1018, #1123, #1453 entsprechen Astuto #472, #8, #263, #478).
5. **Suite-Drift:** Featurebase, UserJot und Quackback werden zu Support-Plattformen. Wer nur ein schlankes Board will, findet immer weniger.

## Positionierung und Konsequenz für die Roadmap

**Mögliche Nische für den Fork:** „Schlankes, datensparsames Self-Hosted-Feedback-Portal ohne Nutzerlimits, mit anonymem Feedback und Moderation, das hinter jedem Proxy sofort läuft.“ Für den DACH-Raum könnte DSGVO-Konformität ein Argument sein: Datenhaltung im eigenen Haus, keine Telemetrie.

**Ehrliche Einordnung:**
- Wenn du **für dich selbst ein Feedback-Portal brauchst** und keine eigenen Anpassungen planst, ist **Quackback** (breit, aktiv) oder **Fider** (schlicht, stabil) heute weniger Aufwand als die Modernisierung von Astuto.
- Wenn du **eigene Anpassungen**, volle Kontrolle über Code und Daten oder ein Rails-Projekt zum Weiterentwickeln willst, lohnt sich der Astuto-Fork weiter. Die Basis ist solide, und die wichtigsten Lücken sind überschaubar.
- **Neu schreiben lohnt sich noch weniger als vorher:** Quackback ist im Grunde schon der moderne Neubau eines Canny-Klons, als Open Source und mit großem Vorsprung.

**Lücken mit dem besten Verhältnis von Nutzen zu Aufwand** (in `roadmap.md` Phase 4 und `todo.md` übernommen):
1. Changelog (verknüpft mit erledigten Posts, RSS und E-Mail an Follower)
2. Duplikatsuche beim Erstellen (#455), mit Postgres-Volltextsuche günstig umsetzbar
3. Tags (#171) und private Boards (#414)
4. Datei-/Bild-Upload (#253, Upstream-PR #454 als Basis)
5. Slack/Discord/Teams-Vorlagen für die bestehenden Webhooks (#419)
6. MCP-Server auf Basis der vorhandenen REST-API (kleiner Aufwand, Alleinstellungsmerkmal unter den Self-Hosted-Tools außer Quackback)
7. Import aus Canny und CSV (#368), um Wechsler aufzunehmen
8. Einbettbares Widget (größer, aber Standard bei allen SaaS-Tools)

## Quellen

- GitHub-API: getfider/fider, QuackbackIO/quackback, logchimp/logchimp, clearflask/clearflask (Lizenz, Sterne, Releases, Issues; abgefragt 24.10.2026)
- [Quackback README](https://github.com/QuackbackIO/quackback) · [ClearFlask README](https://github.com/clearflask/clearflask) · [Fider Pricing](https://fider.io/pricing)
- [Quackback: Best Open Source Feedback Tools 2026](https://quackback.io/blog/open-source-feedback-tools) (Herstellerblog; Angaben zu Astuto teils falsch: Roadmap und OAuth sind vorhanden, Lizenz ist AGPL)
- [Pickafeature: Open Source Canny Alternatives](https://pickafeature.com/blog/open-source-canny-alternative) · [Formbricks: Canny Alternatives](https://formbricks.com/blog/canny-alternatives) · [Featurebase: Canny Alternatives](https://www.featurebase.app/blog/canny-alternatives)
- [UserJot: Canny-Vergleich](https://userjot.com/compare/canny-alternative) · [ProductLift: Feature Voting Tools 2026](https://www.productlift.dev/best-feature-voting-tool/) · [ProductLift: Canny Pricing](https://www.productlift.dev/blog/canny-pricing/) · [FeatureOS: Canny Pricing 2026](https://featureos.com/blog/canny-pricing-2026)
- [G2: Canny Reviews](https://www.g2.com/products/canny/reviews) · [WishKit: Featurebase Review](https://www.wishkit.io/blog/featurebase-review) · [Product Hunt: Featurebase Reviews](https://www.producthunt.com/products/featurebase/reviews) · [featurevote.app: Feature Voting Tools 2026](https://featurevote.app/blog/feature-voting-tools-2026)
