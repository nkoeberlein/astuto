# TODO – Astuto Evolution

Prioritäten: **P0** = blockierend bzw. Sicherheit · **P1** = wichtige Bugs und Betrieb · **P2** = Verbesserungen und Quick Wins · **P3** = später / nice to have
Issue-Nummern beziehen sich auf `astuto/astuto`. Phasen siehe [roadmap.md](roadmap.md).

## P0 – Fork übernehmen und Plattform absichern

### Setup
- [x] Lokales Setup prüfen: Original-Image baute nicht mehr (Debian 11 EOL). Nach Ruby-3.3-Upgrade: 374 Tests, 2 Fehler (UserMailer, Keyword-Argumente unter Rails 6.1 + Ruby ≥ 3.2, wird mit Rails 7.0 behoben)
- [x] `spec/system/user_o_auth_sign_up_and_log_in.rb` in `…_spec.rb` umbenennen (läuft bisher nie); ebenso `spec/requests/posts_controller_test.rb` und `post_statuses_controller_test.rb`, an aktuelles Verhalten angepasst. Der OAuth-System-Spec ist lokal nicht geprüft (kein Chromium im Dev-Container) und läuft erst in der CI
- [ ] Lokaler Port 3000 ist hier durch einen SSH-Tunnel belegt: `ASTUTO_PORT=3456 docker compose up`
- [x] `.github/workflows/push-to-registry.yml` auf GHCR umstellen (`ghcr.io/nkoeberlein/astuto`), `riggraz/astuto` entfernen
- [x] `run-tests.yml`: Runner `ubuntu-24.04`
- [x] README und CONTRIBUTING als Astuto Evolution neu, Links auf `nkoeberlein/astuto`
- [ ] Remote `upstream` nur noch als Archiv betrachten; Upstream-Branch `add-image-upload` sichern
- [x] Offene Upstream-Issues abgeglichen (25.10.2026): alle stehen in Todo oder Roadmap, außer #165 (authenticityToken-Props, hinfällig mit dem alten Frontend) sowie #451 und #465 (ohne Inhalt). Lücken zur Konkurrenz und bewusste Ausschlüsse: roadmap.md §1 und Phase 4/5

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
- [x] `load_defaults` 6.1 → 7.0 → 7.1 → 7.2 → 8.0 → 8.1, jeder Schritt mit voller Suite grün. Cookie-Rotation (SHA1 → SHA256) hält Sessions und Remember-me-Cookies gültig (geprüft mit echten alten Cookies), `allow_other_host` für Tenant-, OAuth- und Billing-Redirects, Active Storage abgeschaltet. Nebenbei: Testumgebung lud Code neu, sobald der Dev-Server Dateien schrieb (sporadisch `AssociationTypeMismatch`), jetzt `enable_reloading = false`
- [x] Sidekiq 8.1.7 und `connection_pool` 3 ohne Pin: `react-rails` 3.3 hängt nicht mehr an connection_pool (npm `react_ujs` bleibt 2.6, weil 3.x React 18 mitbringt). `config/sidekiq.yml` mit allen Queues, vorher liefen Webhook-Jobs ohne `-q webhooks` nie. Mit Redis 8 geprüft
- [x] Stripe-Gem 11 → 20 mit fixierter API-Version `2024-04-10` (der Webhook liest `price` an Rechnungspositionen, das ab 2025-03-31 fehlt). Höhere Version nur mit Test gegen ein Stripe-Testkonto
- [ ] `i18n-js` 3 bleibt bis zur Ablösung des alten Frontends (4.x ist ein Umbau ohne Nutzen für v2)
- [x] `bundler-audit`, `brakeman` und `bin/ci` (Gem-Audit, Yarn-Audit, Brakeman, RSpec, Seeds), dieselben Checks im Test-Workflow. 6 indirekte Gems mit Sicherheitslücken aktualisiert (nokogiri, rails-html-sanitizer, loofah, crass, addressable, concurrent-ruby)
- [x] Upgrade-Hinweis: Sidekiq 8 braucht Redis ≥ 7 (in `UPGRADING.md`)
- [x] Node 20 → 24 LTS im Dockerfile (Builder)
- [x] Node 26 (Builder, Compose-Service, Frontend-CI); Laufzeit-Image ganz ohne Node (Debians Node 20 war EOL und wurde nicht gebraucht)
- [x] `yarn audit` ohne kritische Treffer (altes UI: 15 hoch, 17 mittel, 4 niedrig; entfallen mit dessen Entfernung), geprüft durch `bin/yarn-audit-critical`
- [ ] **Dringend (PG 14 EOL 12.11.2026):** PostgreSQL 14.5 → 18 (#247): Dev-Compose läuft auf `postgres:18-trixie` (frisches Volume; das 19rc1-Dev-Volume wurde verworfen, Dev-Daten waren Scratch), Anleitung in `UPGRADING.md` (Dump/Restore getestet). Offen: GA von PG 19 ist für den **19.11.2026** angekündigt, eine Woche nach dem EOL von PG 14. Dann auf `postgres:19-trixie` umstellen (gleiche Schritte, siehe `UPGRADING.md`)
- [x] Docker-Multi-Arch-Build amd64 + arm64 mit `docker/build-push-action` + QEMU (#399, #254, #475), in der CI noch nicht gelaufen
- [x] Dependabot: Bundler, npm (Frontend; altes UI nur Sicherheitsupdates), Docker, Compose, Actions; Minor/Patch gruppiert. In den Repo-Einstellungen „Dependabot security updates“ aktivieren

### Sicherheit
- [x] **v3-Voraussetzung:** Webhook-URL/-Header mit JSON statt Marshal verschlüsselt (`Webhook.encryptor`, liest beide Formate), Migration `ReencryptWebhooksAsJson` schreibt bestehende Werte neu
- [x] **Datenschutz:** Die alten JSON-Endpunkte (Kommentare, Likes, Statusverlauf, Post-Seite) lieferten `user_email` aller Autoren öffentlich aus. Jetzt nur noch für Moderatoren und die Person selbst, sonst Gravatar-Hash (`Legacy::AuthorFields`); neue App-API über `AuthorSerializer`
- [x] Standard-Admin: `ADMIN_EMAIL` / `ADMIN_PASSWORD`, ohne Passwort außerhalb von Development ein zufälliges, einmal im Log ausgegeben (`DefaultAdminCredentials`)
- [x] SMTP-Standard `openssl_verify_mode: "none"` → `"peer"` (`config/environments/production.rb`)
- [x] Header-Links und Logo-Link: nur `http(s)`, `mailto` und Pfade erlaubt (`SafeUrl`, Validierung in `TenantSetting`); vorher ließ sich ein `javascript:`-Link speichern, den der alte Header ausgab
- [x] `rack-attack`-Anti-Spam für `/posts` stürzte bei fehlenden Feldern mit `TypeError` ab (500); fehlender Zeitstempel zählt jetzt als Spam
- [x] Spamschutz der App-API (`POST /api/app/v1/boards/:id/posts`) an das alte UI angeglichen: ein ausgefüllter Honeypot sperrt die IP für eine Stunde für beide Endpunkte (`/posts` und App-API); zu schnelles Absenden (`formFillMs` < 2 s, im Browser gemessen) lehnt nur der Controller mit 422 ab (`config/initializers/rack_attack.rb`, `PostSpamCheck`, `spec/requests/rack_attack_spec.rb`)
- [x] Content Security Policy aktiv: Skripte nur von der Instanz, von Stripe oder mit Nonce; `CSP_REPORT_ONLY` als Notbremse; System-Spec prüft die Browser-Konsole. Nebenbei behoben: `/next` lief als statische Datei an `SpaController` vorbei (keine Meta-Tags), Gravatar-Bilder luden per `http`
- [x] Rate-Limiting konkretisiert: `/api/v1` (`api/ip`, `api/key`), `/mcp` (`mcp/ip` 60/min, `mcp/key` 120/min) sowie App-API-Auth (`/api/app/v1/session`, `/api/app/v1/registration`, `/api/app/v1/password`) gegen Brute-Force abgesichert; `logins/email` liest jetzt auch `user[email]` bei Devise-Formularen und JSON-Bodies (`config/initializers/rack_attack.rb`)
- [x] Kurzer Security-Check (`rack-attack`-Regeln, API-Key-Handling): API-Tokens in Cache-Keys per SHA-256 gehasht; `Api::BaseController` prüft `user.active? && user.moderator?`; `Api::V1::UsersController#block` und `DestroyApiKeyIfNeededWorkflow` löschen API-Keys zuverlässig auch beim Blockieren über die API, bei direkter Herabstufung `admin → user` sowie bei gleichzeitigem Rollen- und Statuswechsel (`spec/models/api_key_spec.rb`, `spec/api/v1/users_spec.rb`)
- [x] Account-Lockout: Devise `:lockable` ergänzt (bricht Brute-Force-Versuche pro Konto ab, unabhängig von rack-attack), Schwellwerte per ENV konfigurierbar (`LOCKABLE_LOCK_STRATEGY`/`LOCKABLE_UNLOCK_STRATEGY`/`LOCKABLE_MAXIMUM_ATTEMPTS`/`LOCKABLE_UNLOCK_IN_HOURS`, Standard: 10 Versuche, 2 h, „both" = Unlock-Mail + Zeitablauf); App-API-Login zählt Fehlversuche jetzt mit (`valid_for_authentication?`), `UnlocksController` lädt Tenant-Daten, Doku in [docs/account-lockout.md](docs/account-lockout.md)

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
- [ ] Webhooks mit HMAC signieren (Signature-Header), damit Empfänger den Absender verifizieren können (Quackback signiert; Voraussetzung für die Vorlagen-Integrationen)
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
- [ ] 2FA/MFA für Admins und Moderatoren (v2: Devise-TOTP, v3: Better Auth); bei kommerziellem Einsatz bzw. Audits erwartet
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
- [x] Posts und Kommentare bearbeiten/löschen, Status ändern (Moderation) im neuen Frontend (`PATCH/DELETE /api/app/v1/posts/:id`, `PATCH/DELETE /api/app/v1/posts/:post_id/comments/:id`, `PostPage.tsx`, `CommentList.tsx`)
- [x] Roadmap-Seite (`/next/roadmap`, `GET /api/app/v1/roadmap`): Spalten je Status, Board- und Status-Filter in der URL, Startseite ohne Root-Board zeigt die Roadmap wie im alten UI
- [x] Einbettbare Roadmap (`/next/embedded_roadmap`) im neuen Frontend: ohne Header/Footer, Posts im neuen Tab, alte Parameter `show_boards`, `show_statuses`, `show_board_filter`, `show_status_filter`; nur diese Seite ist für fremde iframes freigegeben (`SpaController`), und nur bei aktiver Roadmap
- [x] Login/Registrierung/Passwort als SPA-Seiten (Devise-JSON: `POST/DELETE /api/app/v1/session`, `POST /api/app/v1/registration`, `POST/PATCH /api/app/v1/password`), OAuth-Buttons (`/next/login`, `/next/register`, `/next/password/forgot`, `/next/password/reset`)
- [x] CI: OpenAPI neu erzeugen und gegen `frontend/src/api/schema.d.ts` vergleichen (Drift-Check in `run-tests.yml`, nutzt die beim Image-Build erzeugte OpenAPI-Datei; in der CI noch nicht gelaufen)
- [x] Meta-Tags (Titel, Beschreibung, Open Graph) für öffentliche Seiten serverseitig in `SpaController` (`spec/requests/spa_meta_tags_spec.rb`)
- [x] `hide_unused_statuses_in_filter_by_status` und `custom_css` im neuen Frontend berücksichtigen (`GET /api/app/v1/post_statuses?board_id=`, `__root.tsx`)
- [ ] Umstieg: `/next` → `/`, sobald alle Seiten ersetzt sind
- [x] Designsystem: Branding über CSS-Variablen (bestehende Site-Settings-Farben), Dark Mode, WCAG 2.2 AA, mobile first, volle Bildschirmfläche (2-Spalten-Layout auf Desktop)
- [x] i18n: YAML-Übersetzungen über `GET /api/app/v1/translations/:locale`
- [ ] RTL-fähig: im neuen Frontend nur CSS-Logical-Properties (`ms-`/`me-`, `ps-`/`pe-`, `start`/`end` statt `left`/`right`), `dir` am `<html>` aus der Locale; jetzt beachten, nachträglich wird es teuer
- [x] Öffentliche Seiten: Board, Post-Detail und Kommentare, Roadmap
- [x] Auth-Seiten: Login, Registrierung, Passwort, OAuth-Buttons (Devise mit JSON-Endpunkten)
- [x] Moderation › Feedback-Queue (`/next/moderation/feedback`, `GET /api/app/v1/moderation/posts`): ausstehende und abgelehnte Posts freigeben/ablehnen, Moderations-Link mit Zähler im Header (`pendingPostsCount` in der Session)
- [x] Moderation › Nutzer (`/next/moderation/users`, `GET/PATCH /api/app/v1/moderation/users`): Suche nach Name/E-Mail, Filter nach Rolle und Status, Sperren (Moderatoren), Rollen (Admins); Regeln aus `UserPolicy`, serverseitig gefiltert und seitenweise (`ModerationUsersQuery`)
- [x] Site Settings › General (`/next/site_settings/general`, `GET/PATCH /api/app/v1/site_settings/general`): alle Felder des alten Tabs, nur geänderte Felder werden gesendet, Warnung bei ungespeicherten Änderungen (`useBlocker`); Zahnrad im Header für Admins, übrige Bereiche verlinken ins alte UI
- [x] Site Settings › Boards und Status (`/next/site_settings/boards`, `/next/site_settings/post_statuses`): anlegen, bearbeiten, löschen, sortieren per Hoch/Runter-Knopf (tastaturbedienbar); App-API `POST/PATCH/DELETE` und `PUT …/reorder` mit vollständiger ID-Liste; gemeinsamer `ListEditor`
- [ ] Site Settings › Roadmap, Authentication (OAuth), Appearance, Webhooks, Invitations, API-Keys
- [ ] E2E-Tests (Playwright oder Capybara) für jede neue Seite
- [ ] Altes Frontend entfernen: `react-rails`, `react_ujs`, Redux, Bootstrap, jQuery, Turbolinks, `jsbundling`/Webpack, `i18n-js` 3; danach Sidekiq 8.1 und `connection_pool`-Pin entfernen
- [ ] `app/controllers` (22 Dateien) nach Bereichen gliedern (z. B. `api/app/v1/site_settings/`)
- [ ] RuboCop einführen und in der CI ausführen
- [ ] CI für `develop`: `run-tests.yml` (RSpec inkl. System-Specs, Brakeman, Drift-Check) läuft nur bei Pull Requests; Push-Trigger für `develop` ergänzen oder mit PRs gegen `main` arbeiten
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

- [x] MCP-Server unter `/mcp` (Streamable HTTP), Auth per API-Key (`McpController`, `Mcp::Server`, `spec/requests/mcp_spec.rb`); seit 25.10.2026 auf dem offiziellen `mcp`-Gem (Protokoll bis 2025-11-25), ein Tool pro Klasse in `app/services/mcp/tools`
- [x] MCP-Tools: `search_posts`, `get_post`, `create_post`, `update_post_status`, `add_comment`, `list_boards`, `get_roadmap`, `top_requests` (Votes/Trend)
- [x] MCP-Doku mit Beispielkonfiguration für Claude Desktop/Code und Cursor in [docs/mcp-and-ai.md](docs/mcp-and-ai.md)
- [x] Duplikaterkennung beim Erstellen mit Postgres-Volltextsuche (#455) (`Post.search_by_name_or_description`, `Post.similar_to`, Live-Vorschläge in `NewPostForm.tsx`)
- [x] KI-Anbieter-Abstraktion: OpenAI-kompatibel (inkl. Ollama), Anthropic; alles opt-in per ENV (`AI_PROVIDER` und `AI_MODEL`, kein fest eingebautes Modell), ohne KI voll funktionsfähig (`Ai::Client`)
- [ ] Optional semantische Duplikate mit pgvector und Embeddings
- [ ] Feedback aus anderen Quellen über MCP: Feld „Quelle/Link“ am Post (API, MCP, Anzeige) und `create_post` im Namen eines Nutzers (wie `impersonated_user_id` in API v1, nur Admins); Doku-Rezept „Slack-Thread → Post“ mit Claude
- [ ] Duplikate zusammenführen (Merge): `merged_into_post_id` mit Umleitung, Votes und Kommentare konsolidieren (steht bisher nur im v3-Schema, roadmap §6; alle Wettbewerber mit Duplikaterkennung haben Merge)
- [x] Zusammenfassung langer Diskussionen: Button im Moderationsbereich der Post-Seite (`/next`), `POST /api/app/v1/posts/:id/summary`, einen Tag gecacht
- [ ] Vorschläge für Board und Tags (Methode in `Ai::Client` vorhanden; braucht Tags #171)
- [ ] Changelog-Entwürfe aus erledigten Posts (Methode vorhanden; braucht die Changelog-Funktion)
- [ ] Übersetzung von Feedback (Methode vorhanden, nicht angebunden)
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
- [x] Roadmap zeigt Votes und Kommentare, Sortierung nach „zuletzt aktualisiert“ (#484), im neuen Frontend; nur freigegebene Posts (das alte UI zeigt auch ausstehende)
- [ ] Übersicht „Mein Feedback“ (#429)
- [ ] Vertrauensstufen: neue Freigaberegel „die ersten N Posts eines Kontos prüfen, danach automatisch freigeben“ (#362-Familie)
- [ ] RSS-Feed pro Board (neueste Posts), gemeinsam mit dem Changelog-RSS bauen
- [ ] Digest für Nutzer: `SendRecapEmailsJob` verschickt bisher nur an Moderatoren; Opt-in für alle Nutzer (Top-Requests, Statuswechsel gefolgter Posts)
- [ ] Sitemap.xml für öffentliche Boards, Posts und Roadmap (SEO: Feedback-Portale leben von der Indexierung, Fider verkauft sie hinter Paywall; `robots.txt` ist statisch)
- [x] Eigene Links bzw. URL im Header (#479, #351): `custom_links` (jsonb: `{label, url}`), Textarea im General-Tab, gerendert in Legacy-Header und neuem Frontend
- [x] Datenbank-Transaktionen in Workflows (#169): Post-Update/-Create jeweils atomar mit Follow bzw. Statuswechsel-Eintrag; Mails werden nach dem Commit versendet; gleiche Sicherung im öffentlichen API v1. Anlegen läuft für altes UI, App-API und MCP über `CreatePostWorkflow` (`create!` in der Transaktion, vorher rollten fehlgeschlagene Follows nicht zurück)

### Lücken zur Konkurrenz (siehe konkurrenz.md)
- [ ] Changelog: Einträge mit erledigten Posts verknüpfen, RSS-Feed, E-Mail an Follower
- [ ] Webhook-Vorlagen für Slack, Discord und Teams (#419)
- [ ] Einbettbares Widget (Feedback, Roadmap, Changelog) **mit Besucher-Identifikation**: die eigene App signiert ein JWT mit einem Geheimnis pro Tenant, Astuto ordnet Votes und Posts dem echten Nutzer zu (anlegen oder per E-Mail/externer ID verknüpfen). Ohne das bleiben Widget-Votes anonym. Von P3 hochgezogen

## P2 – Projekt und Community
- [x] `SECURITY.md` mit Meldeweg (GitHub Private Vulnerability Reporting), Fristen und Scope
- [ ] `CHANGELOG.md` und Release-Prozess (SemVer, Release Notes, Image-Tags): CHANGELOG und erstes Tag `v2.0.0-alpha.1` vorhanden; Version steht in `AstutoProject::VERSION` und `frontend/package.json`. Offen: Release-Checkliste, signierte Images
- [ ] Doku aus `astuto/astuto-docs` übernehmen (Lizenz prüfen), Links in `config/initializers/project.rb` und `app/javascript/constants/project.ts` umstellen
- [ ] Übersetzungsplattform festlegen (z. B. Weblate)
- [ ] Demo-Instanz, Einträge bei awesome-selfhosted und AlternativeTo
- [ ] Entscheidung: GitHub-Repo in `astuto-evolution` umbenennen

## P3 – Größere Features (nach Bedarf)

- [ ] Native Integrationen Linear, GitHub, Jira mit Status-Sync
- [ ] Import aus Canny (neben CSV, #368)

- [ ] Bild-Upload und Anhänge, auf Upstream-PR #454 aufbauen (#253, #482); **vorher entscheiden:** Speicher ohne Active Storage (Regel für v2/v3), z. B. S3-kompatibel oder Postgres-`bytea` – unnötig wäre eine Baustelle, die die v3-Migration wieder verkompliziert
- [ ] Tags für Posts (#171)
- [ ] Private Boards (#414)
- [ ] Admin-Freigabe neuer Nutzer (#362), eigene Signup-Anforderungen (#30)
- [ ] Import/Export (#368)
- [ ] Roadmap per Drag-and-drop sortieren (#473)
- [ ] Votes auf Kommentare (#408), Downvotes (#421), Vote-Limit pro Monat (#422); Downvotes vor einer Umsetzung hinterfragen, Reaktionen und Budget-Voting sind bewusst ausgeschlossen (roadmap.md §1)
- [ ] Soft-Delete für Kommentare (#162), private Kommentare (#418)
- [ ] API: Invitations und Follows (#434), Nutzerinfos anzeigen (#322)
- [ ] Avatar-Upload statt nur Gravatar (#469)
- [ ] Custom Fields für Nutzer (#420), Standardkonfigurationen für OAuth und Webhooks (#419)
- [ ] Nutzersegmente: Votes nach Kundengruppe filtern oder gewichten (setzt Besucher-Identifikation und Custom Fields voraus; Gewichtung im v3-Schema)
- [ ] Verfallsregeln: Moderationsfilter „seit X Monaten ohne Aktivität“, automatisches Archivieren nur als Opt-in
- [ ] LDAP/AD-Login (#8)
- [ ] GitHub-Integration (#365)
- [ ] Custom JavaScript (#376), nur mit CSP und Admin-Warnung
- [ ] Mehrere Marken pro Instanz (#76)
- [ ] Automatischer Login nach Tenant-Signup (#263)
- [ ] Übersetzungen: Crowdin-PR #417 übernehmen, Polnisch (#450), Übersetzungsprozess festlegen (#121)
- [ ] Bounties (#438), vorerst nicht vorgesehen
