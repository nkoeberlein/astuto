# TODO – Astuto Evolution

Prioritäten: **P0** = blockierend bzw. Sicherheit · **P1** = wichtige Bugs und Betrieb · **P2** = Verbesserungen und Quick Wins · **P3** = später / nice to have
Issue-Nummern beziehen sich auf `astuto/astuto`. Phasen siehe [roadmap.md](roadmap.md).

## P0 – Fork übernehmen und Plattform absichern

### Setup
- [x] Lokales Setup prüfen: Original-Image baute nicht mehr (Debian 11 EOL). Nach Ruby-3.3-Upgrade: 374 Tests, 2 Fehler (UserMailer, Keyword-Argumente unter Rails 6.1 + Ruby ≥ 3.2, wird mit Rails 7.0 behoben)
- [ ] `spec/system/user_o_auth_sign_up_and_log_in.rb` in `…_spec.rb` umbenennen (läuft bisher nie)
- [ ] Lokaler Port 3000 ist hier durch einen SSH-Tunnel belegt: `ASTUTO_PORT=3456 docker compose up`
- [x] `.github/workflows/push-to-registry.yml` auf GHCR umstellen (`ghcr.io/nkoeberlein/astuto`), `riggraz/astuto` entfernen
- [x] `run-tests.yml`: Runner `ubuntu-24.04`
- [x] README und CONTRIBUTING als Astuto Evolution neu, Links auf `nkoeberlein/astuto`
- [ ] Remote `upstream` nur noch als Archiv betrachten; Upstream-Branch `add-image-upload` sichern

### Upstream-PRs übernehmen
- [x] #477 Gravatar-Avatar-Fix (1 Zeile)
- [x] #470 `config/initializers/hosts.rb` mit `RAILS_HOSTS` (prüfen, mit Phase-2-Proxy-Konfig zusammenlegen)
- [x] #460 Nutzersuche in Site Settings › Users (schließt #159). Nachgebessert: Liste wurde nicht gefiltert, Backend-Filter war defekt
- [x] #463 Türkische Übersetzung (Datei übernommen, Sprache aber noch nicht auswählbar, siehe P2)
- [x] #459 `serialize-javascript` 6.0.2

### Plattform-Upgrade
- [x] Ruby 3.0.6 → 3.3.13, Debian 11 → 13 trixie (`.ruby-version`, `Gemfile`, `Dockerfile` ×2) (#456)
- [x] Rails 6.1 → 7.0 → 7.1 → 7.2 → 8.0 → 8.1.4, jeder Schritt mit 374/0 Tests und ohne Deprecations
- [x] Devise 5.0.4 (Rails-8-Lazy-Routes, CVE-Fixes), Spring entfernt, Puma 8, factory_bot 6, debug statt byebug
- [x] `Rails.application.secrets` ersetzt; `SECRET_KEY_BASE` bleibt in allen Umgebungen die Quelle (Webhook-Verschlüsselung, API-Keys, Devise-Tokens unverändert)
- [x] Ruby 3.3 → 4.0.9 (Bundler 4.0.20), 374/0 Tests
- [ ] `load_defaults` von 6.1 schrittweise auf 8.1 heben (jeweils `new_framework_defaults_*.rb` durchgehen)
- [ ] Sidekiq 8.0 → 8.1 und `connection_pool`-Pin entfernen, sobald `react-rails` weg ist
- [ ] Stripe-Gem 11 → 20 (falls Billing bleibt), `react-rails`/`i18n-js` 3 (entfallen mit UI-Neubau)
- [ ] `bundler-audit` und `brakeman` einführen; lokales `bin/ci` (Rails 8.1) für RSpec statt Minitest einrichten
- [x] Upgrade-Hinweis: Sidekiq 8 braucht Redis ≥ 7 (in `UPGRADING.md`)
- [x] Node 20 → 24 LTS im Dockerfile (Builder)
- [ ] Node 24 → 26 LTS ab 28.10.2026
- [ ] `yarn audit` ohne kritische Treffer
- [ ] **Dringend (PG 14 EOL 12.11.2026):** PostgreSQL 14.5 → 19 (#247): Dev-Compose läuft auf 19rc1, Anleitung in `UPGRADING.md` (Dump/Restore getestet). Offen: bei GA auf `postgres:19-trixie` umstellen, README-Compose anpassen
- [x] Docker-Multi-Arch-Build amd64 + arm64 mit `docker/build-push-action` + QEMU (#399, #254, #475), in der CI noch nicht gelaufen
- [ ] Dependabot oder Renovate für Bundler, npm, Docker und Actions einrichten

### Sicherheit
- [ ] **v3-Voraussetzung:** Webhook-URL/-Header mit `MessageEncryptor` und JSON-Serializer statt Marshal verschlüsseln; Daten-Migration, die alte Werte liest und neu schreibt (Lesen beider Formate während der Umstellung)
- [ ] **Datenschutz:** Die alten JSON-Endpunkte (`posts#index/show`, `comments#index` u. a.) liefern `user_email` aller Autoren öffentlich aus. Behoben in der neuen App-API (`AuthorSerializer`); im alten Frontend bis zur Ablösung entfernen oder nur für Moderatoren ausgeben
- [ ] Standard-Admin `admin@example.com` / `password` (`db/seeds.rb`): Zugangsdaten per ENV setzen oder Passwortwechsel beim ersten Login erzwingen
- [x] SMTP-Standard `openssl_verify_mode: "none"` → `"peer"` (`config/environments/production.rb`)
- [ ] Kurzer Security-Check: `rack-attack`-Regeln, CSP-Header, API-Key-Handling

## P1 – Betrieb und Bugs

### Reverse Proxy / HTTPS
- [x] `config.assume_ssl` und `config.force_ssl` per ENV schaltbar machen (ab Rails 7.1) (`ASSUME_SSL`, `FORCE_SSL`)
- [x] OAuth-`callback_url` muss hinter dem Proxy `https` liefern (#478)
- [x] „The change you wanted was rejected“ hinter dem Proxy (CSRF/Origin) reproduzieren und beheben (#201) (`ASSUME_SSL=true` + Proxy-Header)
- [x] Doku: Beispielkonfigurationen für nginx, Caddy und Traefik (inkl. `X-Forwarded-Proto`) in [docs/reverse-proxy-and-smtp.md](docs/reverse-proxy-and-smtp.md)

### OAuth
- [x] `token_state`-Cookie (#472) in `app/controllers/o_auths_controller.rb`: `domain: ".#{request.domain}"` nur bei Subdomain-Tenancy setzen, sonst weglassen; `secure: request.ssl?` und `same_site: :lax` ergänzen; Spec dazu (`spec/requests/o_auths_cookie_spec.rb`)
- [x] Eigene CA-Zertifikate / Self-Signed per Volume + `update-ca-certificates` im Entrypoint (#203)
- [ ] Konfigurierbare Header für den Profil-API-Aufruf (#485)

### E-Mail
- [ ] „Testmail senden“ in den Site Settings
- [x] Zustellfehler immer loggen, auch wenn `EMAIL_RAISE_DELIVERY_ERRORS=false` (`config/initializers/mailer_logging.rb`)
- [x] SMTP-Doku mit funktionierenden Beispielen (SES, Brevo, SMTP2GO, Exchange; Hinweis auf `EMAIL_SMTP_AUTH=login`) (#330, #446, #294, #385) in [docs/reverse-proxy-and-smtp.md](docs/reverse-proxy-and-smtp.md)
- [x] E-Mail-Änderung bei fehlerhaftem SMTP darf den Nutzer nicht aussperren (#476) (`skip_reconfirmation!` ohne konfiguriertes SMTP in Production)
- [x] Devise-Mails über ActiveJob/Sidekiq verschicken (#444) (`User#send_devise_notification`)

### Webhooks
- [ ] Liquid- und JSON-Fehler beim Ausführen speichern und im UI anzeigen (Delivery-Log pro Webhook) (#458)
- [x] Template beim Speichern bzw. Testen validieren, Hinweis auf `escape_json` (`WebhooksController#preview/test`, `RunWebhook`)
- [x] Kommentar-Benachrichtigungen reparieren (#431) (`config/initializers/global_id.rb`, `SendNotificationForCommentWorkflow`)

### Konfiguration
- [x] `POSTGRES_DB` getrennt von `POSTGRES_USER` (`config/database.yml`) (#326)
- [x] `DATABASE_URL` bzw. externe Postgres-Instanz dokumentieren und testen (#207)

### Kleinere Bugs
- [x] Zähler für ausstehende Posts aktualisiert sich nicht beim Freigeben oder Ablehnen (#445) (`FeedbackModerationP.tsx`)
- [x] Kommentarzähler falsch nach dem Löschen eines Kommentars mit Antworten (#220) (`commentsReducer.ts`)
- [x] Custom CSS: Sonderzeichen werden HTML-escaped (#468) (`app/views/layouts/application.html.erb`)
- [ ] Fehlende Übersetzungstexte (#466)
- [ ] System-Spec „Post bearbeiten/löschen“ reparieren (#210)

### Multi-Tenancy und SaaS-Teile (entschieden: Multi-Tenancy bleibt)
- [ ] Multi-Tenancy-Modus (`MULTI_TENANCY=true`) mit Subdomains und Custom Domains testen, Doku schreiben; App-API und neues Frontend im Multi-Tenancy-Modus prüfen
- [ ] Entscheidung Geschäftsmodell (roadmap.md, Abschnitt 7): Stripe-Billing modernisieren (gehostete Variante) oder entfernen
- [ ] astuto.io-spezifische Teile entfernen bzw. konfigurierbar machen: Promo-Banner, `ASTUTO_CNAME_API_*`, Mails mit astuto.io-Links
- [ ] Mailer-Standardabsender `noreply@astuto.io` / `notifications@astuto.io` durch Adresse aus `BASE_URL` bzw. Pflicht-ENV ersetzen
- [ ] Instanz-Admin-Oberfläche für Tenants (anlegen, sperren, Domains) (#76)

### Mittelstand (roadmap.md, Abschnitt 7)
- [ ] SAML-Login und LDAP/AD (#8), Login nur per SSO (#471)
- [ ] Audit-Log für Moderation und Einstellungen
- [ ] DSGVO: Datenexport und Löschung pro Person, Aufbewahrungsfristen
- [ ] Health-Check-Endpunkt, Prometheus-Metriken, Backup/Restore-Anleitung, Helm-Chart
- [ ] FAQ „AGPL im Unternehmen“

## P1 – Altes Frontend ersetzen (Kern von v2)

Empfehlung (roadmap.md, Abschnitt 3): getrenntes Frontend mit React 19 + TS 7 + TanStack Router/Query + Tailwind 4 + shadcn/ui gegen eine Rails-JSON-API, damit es in v3 (TanStack Start + Drizzle) weiterlebt. Altes Frontend nur noch lauffähig halten.

- [x] Entscheidung v3-Stack: **TanStack Start + Drizzle + Tailwind** → getrenntes React-Frontend in v2
- [x] App-API `/api/app/v1` lesend: `session`, `translations/:locale`, `boards`, `boards/:id/posts`, `post_statuses`, `posts/:id`, `posts/:id/comments` (rswag-Specs, OpenAPI `app/v1/openapi.yaml`, TS-Typen generiert)
- [x] `frontend/`: Vite 8, React 19, TS 7, TanStack Router + Query, Tailwind 4, shadcn/ui, Biome, Vitest; CI-Workflow `frontend.yml`
- [x] Auslieferung im selben Image unter `/next` (`SpaController`), Compose-Dienst `frontend` für Vite
- [x] Schreibende Endpunkte + UI: Post anlegen (anonym, Freigabe-Policy, Honeypot + Mindestzeit), Vote (idempotent, optimistisch), Kommentar/Antwort (Antworten nur im selben Post), Moderator-Update, Follow; CSRF-Fluss mit aktiviertem Schutz getestet
- [ ] Posts und Kommentare bearbeiten/löschen, Status ändern (Moderation) im neuen Frontend
- [ ] Roadmap-Seite, Login/Registrierung/Passwort als SPA-Seiten (Devise-JSON), OAuth-Buttons
- [ ] CI: OpenAPI neu erzeugen und gegen `frontend/src/api/schema.d.ts` vergleichen (Drift-Check)
- [ ] Meta-Tags (Titel, Beschreibung, Open Graph) für öffentliche Seiten serverseitig in `SpaController`
- [ ] `hide_unused_statuses_in_filter_by_status` und `custom_css` im neuen Frontend berücksichtigen
- [ ] Umstieg: `/next` → `/`, sobald alle Seiten ersetzt sind
- [ ] Designsystem: Branding über CSS-Variablen (bestehende Site-Settings-Farben), Dark Mode, WCAG 2.2 AA, mobile first
- [x] i18n: YAML-Übersetzungen über `GET /api/app/v1/translations/:locale`
- [x] Öffentliche Seiten: Board, Post-Detail und Kommentare · [ ] Roadmap
- [ ] Auth-Seiten: Login, Registrierung, Passwort, OAuth-Buttons (Devise mit JSON-Endpunkten)
- [ ] Moderation (Feedback-Queue, Nutzer) und Site Settings (General, Boards, Status, Roadmap, Auth, Appearance, Webhooks, API)
- [ ] E2E-Tests (Playwright oder Capybara) für jede neue Seite
- [ ] Altes Frontend entfernen: `react-rails`, `react_ujs`, Redux, Bootstrap, jQuery, Turbolinks, `jsbundling`/Webpack, `i18n-js` 3; danach Sidekiq 8.1 und `connection_pool`-Pin entfernen
- [ ] `app/controllers` (22 Dateien) nach Bereichen gliedern (z. B. `api/app/v1/site_settings/`)
- [ ] RuboCop einführen und in der CI ausführen
- [ ] TypeScript 7 auch für `openapi-typescript`, sobald unterstützt (läuft bis dahin per `npx` mit TS 5.9)

## P3 – v3: komplett TypeScript (nach 2.0)
- [x] Stack: TanStack Start + Drizzle + Tailwind (Auth z. B. Better Auth)
- [x] Entscheidung Lizenz v3: **AGPL-3.0 (bleibt)**, bei Bedarf dual lizenziert; ab dem ersten v3-Commit CLA nötig, wenn eine kommerzielle Lizenz dazukommt, siehe roadmap.md Abschnitt 6
- [ ] GitHub-Struktur (Fork lösen, Orphan-Branch oder Organisation), siehe roadmap.md Abschnitt 6
- [ ] Neues Drizzle-Schema (UUIDv7, Auth-Tabellen, Fractional Indexing, Timeline, Merge, Votes mit Gewicht, `tsvector`) und automatischer Migrator v2 → v3 beim Start (Transaktion, alte Tabellen nach `v2_archive`)
- [ ] Backend Endpunkt für Endpunkt ersetzen (gleiche API-Verträge wie `/api/app/v1` und `/api/v1`)
- [ ] Webhooks (Liquid → z. B. LiquidJS), Mails, Hintergrundjobs (z. B. pg-boss), MCP-Server in TypeScript
- [ ] SSR für öffentliche Seiten

## P1 – KI und MCP

- [x] MCP-Server unter `/mcp` (Streamable HTTP), Auth per API-Key (`McpController`, `Mcp::Server`, `spec/requests/mcp_spec.rb`)
- [x] MCP-Tools: `search_posts`, `get_post`, `create_post`, `update_post_status`, `add_comment`, `list_boards`, `get_roadmap`, `top_requests` (Votes/Trend)
- [x] MCP-Doku mit Beispielkonfiguration für Claude Desktop/Code und Cursor in [docs/mcp-and-ai.md](docs/mcp-and-ai.md)
- [x] Duplikaterkennung beim Erstellen mit Postgres-Volltextsuche (#455) (`Post.search_by_name_or_description`, `Post.similar_to`, Live-Vorschläge in `NewPostForm.tsx`)
- [x] KI-Anbieter-Abstraktion: OpenAI-kompatibel (inkl. Ollama), Anthropic; alles opt-in per ENV, ohne KI voll funktionsfähig (`Ai::Client`)
- [ ] Optional semantische Duplikate mit pgvector und Embeddings
- [x] Zusammenfassung langer Diskussionen, Vorschläge für Tags und Board, Changelog-Entwürfe, Übersetzung von Feedback (`Ai::Client`)
- [x] Datenschutzhinweis: welche Daten an den KI-Anbieter gehen (`Ai::Client.privacy_disclosure`, [docs/mcp-and-ai.md](docs/mcp-and-ai.md))

## P2 – Quick Wins
### Quick-Win-Features
- [x] Vorhandene Übersetzungen freischalten: `tr`, `cs`, `el`, `hi`, `nl`, `pl`, `sr`, `sv` freigeschaltet (gleiches Vollständigkeitsniveau wie `es`/`fr`: ca. 45 fehlende Keys fallen auf Englisch zurück). `ja` und `ko` bleiben aus (52 fehlende Keys), Freischaltung sobald ergänzt. Fehlende Keys (v. a. Webhooks-UI) sind Ticket für Übersetzungsauflauf.
- [x] Roadmap abschaltbar (#361): `roadmap_enabled`-Tenant-Setting; `/roadmap` und `/embedded_roadmap` leiten zur Startseite um, Header-Link entfällt, Checkbox in Site Settings › General
- [x] Standard-Sortierung instanz-weit (#193, #363): `default_post_sorting`-Tenant-Setting; `BoardPostsQuery` nutzt es, wenn kein `?sort=` übergeben wird; neues Frontend übernimmt es als Default und in die URL. Pro Board bleibt für später.
- [x] Login nur per OAuth (#471): `login_only_with_oauth`-Setting verbindet E-Mail/Passwort-Formular und Registrierung, wenn OAuth-Anbieter existieren; Passwort-Reset bleibt als Notfall-Einstieg, Devise-Endpunkte sind nicht blockiert
- [x] Favicon einstellbar (#452): `site_favicon` am Tenant (URL), Fallback auf das Standard-Favicon in beiden Layouts
- [x] Logo-Größe im Mail-Template (#474): `mail_logo_size`-Setting (Pixel, Default 64); Mails nutzen künftig das eigene Tenant-Logo statt des hartkodierten astuto-assets-Links (per `EMAIL_LOGO_URL` überschreibbar)
- [x] Rückfrage beim Verwerfen ungespeicherter Site-Settings (#106): `useUnsavedChangesWarning` (beforeunload) in General, Authentication, Appearance und Webhook-/OAuth-Formularen
- [x] Combobox für den Status im Post-Formular (#119): Moderatoren wählen beim Erstellen einen Status; App-API nimmt `postStatusId` (nur Moderatoren), Timeline-Eintrag wird mitgedeckt
- [ ] Roadmap zeigt Votes und Kommentare, Sortierung nach „zuletzt aktualisiert“ (#484) – gehört in den Roadmap-Seiten-Neubau des neuen Frontends
- [ ] Übersicht „Mein Feedback“ (#429)
- [x] Eigene Links bzw. URL im Header (#479, #351): `custom_links` (jsonb: `{label, url}`), Textarea im General-Tab, gerendert in Legacy-Header und neuem Frontend
- [x] Datenbank-Transaktionen in Workflows (#169): Post-Update/-Create jeweils atomar mit Follow bzw. Statuswechsel-Eintrag; Mails werden nach dem Commit versendet; gleiche Sicherung im öffentlichen API v1

### Lücken zur Konkurrenz (siehe konkurrenz.md)
- [ ] Changelog: Einträge mit erledigten Posts verknüpfen, RSS-Feed, E-Mail an Follower
- [ ] Webhook-Vorlagen für Slack, Discord und Teams (#419)

## P2 – Projekt und Community
- [ ] `SECURITY.md` mit Meldeweg für Sicherheitslücken
- [ ] `CHANGELOG.md` und Release-Prozess (SemVer, Release Notes, Image-Tags)
- [ ] Doku aus `astuto/astuto-docs` übernehmen (Lizenz prüfen), Links in `config/initializers/project.rb` und `app/javascript/constants/project.ts` umstellen
- [ ] Übersetzungsplattform festlegen (z. B. Weblate)
- [ ] Demo-Instanz, Einträge bei awesome-selfhosted und AlternativeTo
- [ ] Entscheidung: GitHub-Repo in `astuto-evolution` umbenennen

## P3 – Größere Features (nach Bedarf)

- [ ] Einbettbares Widget (Feedback, Roadmap, Changelog)
- [ ] Native Integrationen Linear, GitHub, Jira mit Status-Sync
- [ ] Import aus Canny (neben CSV, #368)

- [ ] Bild-Upload und Anhänge, auf Upstream-PR #454 aufbauen (#253, #482)
- [ ] Tags für Posts (#171)
- [ ] Private Boards (#414)
- [ ] Admin-Freigabe neuer Nutzer (#362), eigene Signup-Anforderungen (#30)
- [ ] Import/Export (#368)
- [ ] Roadmap per Drag-and-drop sortieren (#473)
- [ ] Votes auf Kommentare (#408), Downvotes (#421), Vote-Limit pro Monat (#422)
- [ ] Soft-Delete für Kommentare (#162), private Kommentare (#418)
- [ ] API: Invitations und Follows (#434), Nutzerinfos anzeigen (#322)
- [ ] Avatar-Upload statt nur Gravatar (#469)
- [ ] Custom Fields für Nutzer (#420), Standardkonfigurationen für OAuth und Webhooks (#419)
- [ ] LDAP/AD-Login (#8)
- [ ] GitHub-Integration (#365)
- [ ] Custom JavaScript (#376), nur mit CSP und Admin-Warnung
- [ ] Mehrere Marken pro Instanz (#76)
- [ ] Automatischer Login nach Tenant-Signup (#263)
- [ ] Übersetzungen: Crowdin-PR #417 übernehmen, Polnisch (#450), Übersetzungsprozess festlegen (#121)
- [ ] Bounties (#438), vorerst nicht vorgesehen
