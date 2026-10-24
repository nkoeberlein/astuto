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
| Ruby | 3.0.6 (EOL) | **4.0.9** | 4.0 ✓ |
| Rails | 6.1 (EOL) | **8.1.4** | 8.1 ✓ |
| Devise | 4.7.3 | **5.0.4** | 5.x ✓ |
| PostgreSQL | 14.5 (EOL 12.11.2026) | 19rc1 (Dev) | 19 |
| Node (Build) | 20 (EOL) | 24 LTS | 26 LTS |
| Debian-Basis | 11 (EOL, Image baute nicht mehr) | 13 trixie | 13 trixie |
| Docker-Image | `riggraz/astuto`, amd64 | CI: `ghcr.io/nkoeberlein/astuto`, amd64 + arm64 | ✓ |
| Frontend | React 16, Redux, Bootstrap 4 | unverändert | ersetzt (siehe 3.); v3: komplett TypeScript |

## 3. Versionsstrategie

| Version | Ziel |
|---|---|
| **v2** | Pakete modernisieren (✅ Backend fertig), den kompletten React-16/Redux/Bootstrap-4-Teil entsorgen und ersetzen: entweder durch sauberes **Rails 8 (Hotwire)** oder durch ein **strikt getrenntes, modernes Frontend** gegen eine Rails-JSON-API. Dazu MCP und Betriebsfixes. |
| **v3** | Umstellung auf **komplett TypeScript**: TanStack Start *oder* SvelteKit, mit Drizzle (PostgreSQL) und Tailwind. Rails entfällt. |

### Die Wahl für v3 bestimmt das v2-Frontend (Entscheidung offen)

| v3-Stack | Passendes v2-Frontend | Warum |
|---|---|---|
| **TanStack Start (React)** ✅ empfohlen | **Getrenntes Frontend:** React 19 + TypeScript 7 + TanStack Router/Query + Tailwind 4 + shadcn/ui, gebaut mit Vite, als SPA gegen eine versionierte Rails-JSON-API (OpenAPI aus rswag → generierter TS-Client) | Die v2-Oberfläche lebt in v3 weiter. In v3 wird nur das Backend ersetzt (Rails → TanStack-Start-Serverfunktionen + Drizzle). Der Übergang erfolgt schrittweise, Endpunkt für Endpunkt („Strangler“). |
| **SvelteKit** | **Rails 8 mit Hotwire** (Turbo + Stimulus, ViewComponent, Tailwind) | Ein React-Frontend wäre bei SvelteKit Wegwerfarbeit. Hotwire ist für v2 der günstigste saubere Weg. Mitnehmen lassen sich nur Design und Tailwind-Klassen. |

**Empfehlung: TanStack.** Das Team bleibt bei React, die Arbeit am v2-Frontend ist nicht verloren, und v3 wird zu einem Backend-Tausch statt zu einem zweiten Komplett-Neubau. Das Ökosystem (shadcn/ui, TanStack Table/Query/Form) deckt Admin-Tabellen, Formulare und das Widget ab.

**Folgen der Empfehlung für v2:**
- Rails wird zur reinen API- und Auth-Schicht. Die heutigen JSON-Endpunkte des alten Frontends werden zu einer dokumentierten `/api/app/v1`-Schnittstelle (Session-Cookie + CSRF); die öffentliche `/api/v1` für Integrationen (API-Key) bleibt.
- Auslieferung weiter als **ein Image**: Rails liefert das gebaute SPA als statische Dateien aus. SSR für SEO der öffentlichen Boards kommt mit v3 (TanStack Start). Bis dahin werden Meta-Tags serverseitig gesetzt.
- Devise bleibt für Login, OAuth und Mails; die Login-Seiten werden SPA-Seiten gegen JSON-Endpunkte.
- Das alte Frontend wird Seite für Seite ersetzt und am Ende vollständig entfernt (`react-rails`, `react_ujs`, Redux, Bootstrap, jQuery, Turbolinks, Webpack, `i18n-js` 3, `connection_pool`-Pin).

**Anforderungen an die neue UI:** Mobile first, Dark Mode, WCAG 2.2 AA, Branding über CSS-Variablen, ein Komponentensatz auch für das einbettbare Widget, Übersetzungen aus den bestehenden YAML-Dateien (als JSON exportiert).

**SaaS-Code:** Stripe-Billing, Tenant-Signup und Custom-Domain-API entfernen, weil die Nische Self-Hosting ist. Multi-Tenancy vorerst behalten (#76).

## 4. Phasen

### Phase 0 – Fork übernehmen ✅
- Upstream-PRs #477, #470, #459, #463, #460 übernommen; #463 (kaputtes YAML) und #460 (Filter wirkungslos, Backend-Filter defekt) nachgebessert
- CI baut Multi-Arch-Images für GHCR
- Umbenennung in **Astuto Evolution**, Links auf `nkoeberlein/astuto`, README und CONTRIBUTING neu
- Ausgangszustand: 374 Tests

### Phase 1 – Plattform (Backend fertig) · P0
- [x] Ruby 4.0.9, Rails 8.1.4, Devise 5, Puma 8, Sidekiq 8.0, Debian trixie, Node 24 – 374/0 Tests, keine Deprecations, Produktions-Image läuft
- [ ] `load_defaults` 6.1 → 8.1 schrittweise
- [ ] PostgreSQL 19 bei GA (Anleitung in [UPGRADING.md](UPGRADING.md) ist fertig und getestet)
- [ ] Node 26 LTS (ab 28.10.2026), Dependabot, `bundler-audit`, Security-Policy (`SECURITY.md`)
- [ ] SaaS-Billing entfernen (siehe 3.)

### Phase 2 – Betrieb und Bugfixes · P1
Die häufigsten Probleme aus den Upstream-Issues: HTTPS hinter Reverse Proxy (#478, #201), OAuth-Cookie (#472), SMTP (#330 u. a.), Webhook-Fehler sichtbar machen (#458), konfigurierbare DB (#326, #207), Standard-Admin-Passwort, unsicherer SMTP-Standard. Details in todo.md.

### Phase 3 – Altes Frontend ersetzen · P1 (Kern von v2, begonnen)
1. ✅ Entscheidung: v3 wird **TanStack Start + Drizzle + Tailwind** → v2 bekommt ein getrenntes React-Frontend
2. ✅ `frontend/` mit Vite 8, React 19, **TypeScript 7**, TanStack Router/Query, Tailwind 4, shadcn/ui, **Biome** (statt ESLint/Prettier), Vitest; eigener CI-Workflow; Build ins Image, ausgeliefert unter `/next`
3. ✅ App-API `/api/app/v1` (lesend: Session, Übersetzungen, Boards, Status, Posts, Kommentare), OpenAPI per rswag, generierte TS-Typen
4. ✅ Board-Seite (Suche, Sortierung, Statusfilter, Mehr laden) und Post-Detail mit Kommentaren · offen: Roadmap, Auth-Seiten, schreibende Aktionen (Post anlegen, Vote, Kommentar, Follow)
5. Moderation und Site Settings
6. Altes Frontend und dessen Gems/Pakete entfernen; Sidekiq 8.1
(Bei SvelteKit stattdessen: Hotwire-Views mit ViewComponent und Tailwind, Seite für Seite.)

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
| `2.0.0-beta` | + Phase 3 (öffentliche Seiten), MCP-Server | Neues Frontend für alle Besucherseiten, MCP mit Grundwerkzeugen |
| `2.0.0` | + Phase 3 komplett | React 16/Redux/Bootstrap 4 vollständig entfernt, Doku übernommen |
| `2.1` | Phase 4 | Duplikaterkennung, KI-Funktionen, Changelog |
| `2.2+` | Phase 5 | Widget, Import, private Boards, LDAP |
| `3.0.0` | Komplett TypeScript | TanStack Start (oder SvelteKit) + Drizzle + Tailwind, Rails entfernt, Daten-Migration aus v2 automatisch |

## 6. v3 vorbereiten – Datenmodell, Migration, Lizenz

**Neues Datenmodell in v3, nahtloses Upgrade aus v2.** v3 bekommt ein eigenes, sauberes Schema (Drizzle). Bestehende v2-Installationen werden beim ersten Start von v3 automatisch migriert. Für Admins bleibt das Upgrade ein Tausch des Image-Tags.

| Bereich | v2 (Rails) | v3 (Drizzle) |
|---|---|---|
| IDs | sequenzielles `bigint` | UUIDv7 (oder internes `bigint` + öffentliche ID/Slug), keine Aufzählbarkeit |
| Mandanten | `tenant_id` in jeder Tabelle (vorhanden) | als `workspace` übernehmen |
| Auth | Devise-Spalten in `users`, eigene OAuth-Tabellen | getrennt: `user`, `session`, `account` (mehrere OAuth-Anbieter, Passkeys), z. B. Better Auth |
| Reihenfolge (Boards, Status, Roadmap) | Integer `order` | Fractional Indexing: ein `UPDATE` pro Drag-and-drop |
| Aktivität | `comments`, `post_status_changes` getrennt | eine Timeline (Kommentare, Statuswechsel, Merges) |
| Duplikate | – | `merged_into_post_id`, Votes werden zusammengeführt |
| Votes | `likes` (user, post) | `votes` mit Gewicht/„im Namen von“, gecachte Zähler |
| Suche | `ILIKE` | `tsvector`, optional `pgvector` für ähnliche Posts |

**Automatische Migration v2 → v3** beim Containerstart: Erkennen (`schema_migrations` vorhanden), dann eine Transaktion: Daten in das neue Schema überführen, alte Tabellen nach `v2_archive` verschieben. Übertragbarkeit geprüft:
- Passwörter: Devise nutzt bcrypt (Cost 11, kein Pepper). Die Hashes sind in Node/Bun direkt prüfbar, niemand muss sein Passwort neu setzen.
- API-Keys: HMAC mit `SECRET_KEY_BASE`, in TypeScript nachbaubar.
- **Webhook-URL und -Header:** mit `ActiveSupport::MessageEncryptor` (AES-256-GCM) verschlüsselt, Inhalt aber im **Ruby-Marshal-Format**. Vor v3 in v2 auf JSON umverschlüsseln (siehe todo.md).

**Der Vertrag zwischen v2 und v3 ist die App-API** (`/api/app/v1`, OpenAPI). Das v2-Frontend hängt nicht am Datenbankschema. v3 implementiert dieselben Endpunkte auf dem neuen Schema, und das Frontend läuft weiter.

**Regeln für v2, damit die Migration einfach bleibt** (stehen auch in AGENTS.md): keine `serialize`/`store`-Spalten (natives `jsonb`), keine polymorphen Assoziationen, kein Active Storage für Dateien, keine Ruby-spezifischen Formate in der Datenbank. Der aktuelle Stand erfüllt das bis auf die Webhook-Verschlüsselung.

**Lizenz (Entscheidung offen):**
- v2 ist ein abgeleitetes Werk und bleibt **AGPL-3.0** mit den ursprünglichen Copyright-Hinweisen.
- v3 als Neuentwicklung könnte eine andere Lizenz bekommen, aber nur ohne übernommenen Code, ohne Logo und Grafiken und ohne die Übersetzungsdateien der Community. Das v2-Frontend ist neu geschrieben, nutzt aber die Astuto-Übersetzungen.
- **Empfehlung: v3 bleibt AGPL-3.0.** Übersetzungen, Logo, Schema-Wissen und Community-Beiträge dürfen dann weiterverwendet werden, und die AGPL schützt die Nische (Self-Hosting) vor geschlossenen SaaS-Ablegern.

**GitHub (Entscheidung offen):** Den Fork vom archivierten Upstream lösen lassen (GitHub-Support), damit Codesuche und Sichtbarkeit normal funktionieren. v3 im selben Repository entwickeln (Orphan-Branch, beim Release zu `main`, v2 als `v2`-Branch) oder in einer Organisation `astuto-evolution`.
