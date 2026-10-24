# Roadmap – Astuto Evolution

Stand: 24.10.2026 · Repository: [nkoeberlein/astuto](https://github.com/nkoeberlein/astuto) · Branch `develop`

Astuto Evolution führt das archivierte [astuto/astuto](https://github.com/astuto/astuto) als Community-Projekt weiter. Name und Herkunft bleiben erkennbar, der Neuanfang ebenfalls: aktueller Stack, neue Oberfläche, KI-Funktionen. Ziel ist **kein Eigenbedarf**, sondern ein eigenständiges Open-Source-Projekt für die Nische aus der [Konkurrenzanalyse](konkurrenz.md). Konkrete Aufgaben: [todo.md](todo.md).

## 1. Vision und Nische

**Positionierung:** *Das schlanke, selbst gehostete Feedback-Portal ohne Nutzerlimits, mit anonymem Feedback, DSGVO-freundlich und KI-nativ über MCP.*

| Zielgruppe | Warum Astuto Evolution |
|---|---|
| Kleine und mittlere SaaS-Teams | Kein Preis pro Nutzer oder Seat wie bei Canny oder Featurebase; ein Docker-Image |
| EU-/DACH-Firmen, Behörden, Bildung | Daten bleiben im eigenen Haus, keine Telemetrie, KI optional mit lokalem Modell |
| Open-Source-Projekte | Kostenlos, AGPL, öffentliche Roadmap, Feedback ohne Account |
| Interne IT / Unternehmensportale | Self-Hosting, OAuth/SSO, später LDAP |

**Abgrenzung:**
- **Quackback** wird zur Support-Suite (Inbox, Help Center, Statusseite). Astuto Evolution bleibt bewusst ein Feedback-Portal: weniger Betrieb, weniger Angriffsfläche.
- **Fider** ist schlicht, hat aber keine Roadmap und kein Changelog, und Moderation steckt in der Cloud hinter einer Paywall. Astuto Evolution hat beides bereits und bleibt komplett frei.
- **Proprietäre Tools** konkurrieren über den Preis pro Nutzer. Astuto Evolution kennt keine Limits.

**Prinzipien:**
1. Läuft mit einem Image plus PostgreSQL, ohne weitere Pflichtdienste.
2. KI ist optional („Bring your own model“: OpenAI-kompatible API, Anthropic, lokal per Ollama). Ohne KI funktioniert alles.
3. Keine Telemetrie, keine Paywall-Features.
4. Kompatibel zu Astuto 1.x: bestehende Installationen lassen sich mit Anleitung migrieren.

## 2. Ausgangslage

| Punkt | Befund |
|---|---|
| Upstream | `astuto/astuto` archiviert, End of Life seit 09.01.2026 (#487). 2.343 Sterne, 186 Forks, kein aktiver Nachfolger. |
| Offene Upstream-Issues | 72 (ca. 15 Bugs bzw. Betriebsprobleme, ca. 45 Feature-Wünsche). Sie bilden den Startbestand für die Planung. |
| Codebasis | ca. 4.900 Zeilen Ruby, ca. 16.000 Zeilen TS/TSX, 374 Tests. Sauber strukturiert (Controller → Policies → Workflows → Models). |
| SaaS-Ballast | Multi-Tenancy, Stripe-Billing, Custom-Domain-API und Tenant-Signup des eingestellten astuto.io-Angebots (ca. 20 Dateien) |
| Lizenz | AGPL-3.0 (bleibt) |

### Plattform – Stand und Ziel

| Komponente | Upstream | Jetzt (`develop`) | Ziel 2.0 |
|---|---|---|---|
| Ruby | 3.0.6 (EOL) | 3.3.13 | 4.0 |
| Rails | 6.1 (EOL) | **7.0.10** | 8.1 |
| Devise | 4.7.3 | 4.9.4 | 5.x |
| PostgreSQL | 14.5 (EOL 12.11.2026) | 19rc1 (Dev) | 19 |
| Node (Build) | 20 (EOL) | 24 LTS | 26 LTS |
| Debian-Basis | 11 (EOL, Image baute nicht mehr) | 13 trixie | 13 trixie |
| Docker-Image | `riggraz/astuto`, amd64 | CI: `ghcr.io/nkoeberlein/astuto`, amd64 + arm64 | ✓ |
| Frontend | React 16, Redux, Bootstrap 4 | unverändert | Neubau (siehe 3.) |

## 3. Grundsatzentscheidungen

**Backend behalten und modernisieren.** Es ist klein, getestet und funktional breit (Boards, Roadmap, Moderation, OAuth2, Webhooks, REST-API). Ein Neubau würde Monate kosten, ohne neuen Nutzen.

**Frontend neu bauen.** Das alte Frontend (React 16, Redux, Bootstrap 4, Klassenkomponenten) auf React 19 zu migrieren kostet fast so viel wie ein Neubau. Am Ende stünde trotzdem die alte Oberfläche. Deshalb bleibt es nur in Betrieb, bis es ersetzt ist.

**Empfohlene UI-Architektur** (Entscheidung offen):

| Option | Bewertung |
|---|---|
| **A: Inertia.js (inertia-rails) + React 19 + TypeScript 7 + Tailwind 4 + shadcn/ui, Build mit Vite** ✅ | Rails-Controller und Pundit bleiben, kein separates API-Backend und kein Redux nötig; SSR für öffentliche Seiten (SEO); Seite für Seite migrierbar neben dem alten Frontend; moderne Komponentenbibliothek |
| B: Hotwire (Turbo + Stimulus) + ViewComponent | Sehr Rails-nah, wenig JS; aber reichhaltige Interaktionen (Drag-and-drop-Roadmap, Widget) sind mühsamer, React-Know-how geht verloren |
| C: Separates SPA (z. B. Next.js) gegen die REST-API | Zwei Deployments, widerspricht „ein Image“ |

Anforderungen an die neue UI: Mobile first, Dark Mode, WCAG 2.2 AA, ein Komponentensatz auch für das einbettbare Widget, Theme über CSS-Variablen (Branding), i18n weiter über die YAML-Dateien.

**SaaS-Code:** Stripe-Billing, Tenant-Signup und Custom-Domain-API entfernen, weil die Nische Self-Hosting ist. Multi-Tenancy vorerst behalten: Agenturen könnten mehrere Portale in einer Instanz betreiben (#76). Nach dem UI-Neubau neu bewerten.

## 4. Phasen

### Phase 0 – Fork übernehmen ✅
- Upstream-PRs #477, #470, #459, #463, #460 übernommen; #463 (kaputtes YAML) und #460 (Filter wirkungslos, Backend-Filter defekt) nachgebessert
- CI baut Multi-Arch-Images für GHCR
- Umbenennung in **Astuto Evolution**, Links auf `nkoeberlein/astuto`, README und CONTRIBUTING neu
- Ausgangszustand: 374 Tests

### Phase 1 – Plattform (in Arbeit) · P0
- [x] Ruby 3.3, Debian trixie, Node 24 · [x] Rails 7.0 · [x] `load_defaults` 6.1
- [ ] Rails 7.1 → 7.2 → 8.0 → 8.1, danach Ruby 4.0, Devise 5, Puma 7
- [ ] PostgreSQL 19 bei GA (Anleitung in [UPGRADING.md](UPGRADING.md) ist fertig und getestet)
- [ ] Node 26 LTS (ab 28.10.2026), Dependabot, `bundler-audit`, Security-Policy (`SECURITY.md`)
- [ ] SaaS-Billing entfernen (siehe 3.)

### Phase 2 – Betrieb und Bugfixes · P1
Die häufigsten Probleme aus den Upstream-Issues: HTTPS hinter Reverse Proxy (#478, #201), OAuth-Cookie (#472), SMTP (#330 u. a.), Webhook-Fehler sichtbar machen (#458), konfigurierbare DB (#326, #207), Standard-Admin-Passwort, unsicherer SMTP-Standard. Details in todo.md.

### Phase 3 – UI-Neubau · P1 (Kern von 2.0)
1. Grundgerüst: Vite, Inertia, React 19, TS 7, Tailwind 4, shadcn/ui, ESLint/Prettier, Typprüfung in CI; Designsystem mit Branding-Variablen
2. Öffentliche Seiten zuerst: Board-Liste, Board, Post-Detail mit Kommentaren, Roadmap, Login und Registrierung (SSR)
3. Moderation und Site Settings
4. Altes Frontend entfernen (`react-rails`, Redux, Bootstrap, jQuery, Turbolinks)
5. Einbettbares Widget aus denselben Komponenten (Phase 5)

### Phase 4 – KI und MCP · P1 (MCP in 2.0, Rest 2.x)
- **MCP-Server** (Streamable HTTP unter `/mcp`, Auth per API-Key, später OAuth). Tools: Posts suchen, lesen, anlegen, Status ändern, kommentieren, Votes und Trends abfragen, Roadmap lesen. Damit triagieren Claude, Cursor und andere Assistenten Feedback direkt. Unter den Self-Hosted-Tools hat das sonst nur Quackback.
- **Duplikaterkennung** beim Erstellen (#455): zuerst Postgres-Volltextsuche, optional semantisch mit pgvector und Embeddings
- **KI-Funktionen (opt-in, eigenes Modell):** Zusammenfassung langer Diskussionen, Vorschläge für Tags und Board, Changelog-Entwürfe aus erledigten Posts, Übersetzung von Feedback
- Datenschutz: Was an den KI-Anbieter geht, ist dokumentiert und abschaltbar; lokales Modell per Ollama wird unterstützt

### Phase 5 – Nischen-Features · P2
- **Changelog** mit RSS und E-Mail an Follower
- **Private Boards** (#414), **Tags** (#171), **Anhänge** (#253, #482)
- **Import** aus Canny, Fider und CSV (#368), um Wechsler aufzunehmen
- **Einbettbares Widget**, **Webhook-Vorlagen** für Slack, Discord und Teams (#419)
- **LDAP/SAML** (#8) für Unternehmen und Behörden
- Quick Wins aus den Issues: Roadmap abschaltbar (#361), Standard-Sortierung (#193, #363, #483), OAuth-only-Login (#471), Favicon (#452)

### Querschnitt – Projekt und Community
- Dokumentation aus `astuto/astuto-docs` übernehmen (vorher Lizenz prüfen) und auf die neue Version aktualisieren
- Übersetzungen: eigene Plattform (z. B. Weblate, für Open Source kostenlos), 10 vorhandene, aber nicht freigeschaltete Sprachen aktivieren
- Release-Prozess: SemVer, `CHANGELOG.md`, signierte Images, Release Notes
- Sichtbarkeit: Einträge bei awesome-selfhosted und AlternativeTo, Demo-Instanz, Ankündigung für frühere Astuto-Nutzer
- Optional: GitHub-Repository in `astuto-evolution` umbenennen (GitHub leitet alte Links weiter)

## 5. Meilensteine

| Version | Inhalt | Kriterium |
|---|---|---|
| `2.0.0-alpha` | Phase 1 + 2 | Rails 8.1, Ruby 4.0, PG 19, Tests grün, Image auf GHCR, Migration aus 1.x dokumentiert |
| `2.0.0-beta` | + Phase 3 (öffentliche Seiten), MCP-Server | Neue UI für alle Besucherseiten, MCP mit Grundwerkzeugen |
| `2.0.0` | + Phase 3 komplett | Altes Frontend entfernt, Doku übernommen |
| `2.1` | Phase 4 | Duplikaterkennung, KI-Funktionen, Changelog |
| `2.2+` | Phase 5 | Widget, Import, private Boards, LDAP |
