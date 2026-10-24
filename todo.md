# TODO – Astuto-Fork

Prioritäten: **P0** = blockierend bzw. Sicherheit · **P1** = wichtige Bugs und Betrieb · **P2** = Verbesserungen und Quick Wins · **P3** = später / nice to have
Issue-Nummern beziehen sich auf `astuto/astuto`. Phasen siehe [roadmap.md](roadmap.md).

## P0 – Fork übernehmen und Plattform absichern

### Setup
- [x] Lokales Setup prüfen: Original-Image baute nicht mehr (Debian 11 EOL). Nach Ruby-3.3-Upgrade: 374 Tests, 2 Fehler (UserMailer, Keyword-Argumente unter Rails 6.1 + Ruby ≥ 3.2, wird mit Rails 7.0 behoben)
- [ ] `spec/system/user_o_auth_sign_up_and_log_in.rb` in `…_spec.rb` umbenennen (läuft bisher nie)
- [ ] Lokaler Port 3000 ist hier durch einen SSH-Tunnel belegt: `ASTUTO_PORT=3456 docker compose up`
- [x] `.github/workflows/push-to-registry.yml` auf GHCR umstellen (`ghcr.io/nkoeberlein/astuto`), `riggraz/astuto` entfernen
- [x] `run-tests.yml`: Runner `ubuntu-24.04`
- [ ] README: EOL-Hinweis durch Fork-Hinweis ersetzen, Image-Name und Doku-Link anpassen
- [ ] Remote `upstream` nur noch als Archiv betrachten; Upstream-Branch `add-image-upload` sichern

### Upstream-PRs übernehmen
- [x] #477 Gravatar-Avatar-Fix (1 Zeile)
- [x] #470 `config/initializers/hosts.rb` mit `RAILS_HOSTS` (prüfen, mit Phase-2-Proxy-Konfig zusammenlegen)
- [x] #460 Nutzersuche in Site Settings › Users (schließt #159). Nachgebessert: Liste wurde nicht gefiltert, Backend-Filter war defekt
- [x] #463 Türkische Übersetzung (Datei übernommen, Sprache aber noch nicht auswählbar, siehe P2)
- [x] #459 `serialize-javascript` 6.0.2

### Plattform-Upgrade
- [x] Ruby 3.0.6 → 3.3.13, Debian 11 → 13 trixie (`.ruby-version`, `Gemfile`, `Dockerfile` ×2) (#456)
- [ ] Rails 6.1 → 7.0 (`rails app:update`, Zeitwerk und Deprecations prüfen, Tests grün)
- [ ] Rails 7.0 → 7.1 → 7.2 → 8.0 → 8.1 (jeweils eigener Commit, Tests grün; nur 8.1 bekommt noch Updates)
- [ ] Danach Ruby 3.3 → 4.0
- [ ] Devise 4.7.3 → 5.x (ab Rails 7.0), Puma 5 → 7, `spring` entfernen
- [ ] Übrige Gems aktualisieren (`bundle outdated`), `bundler-audit` ohne Treffer
- [x] Node 20 → 24 LTS im Dockerfile (Builder)
- [ ] Node 24 → 26 LTS ab 28.10.2026
- [ ] `yarn audit` ohne kritische Treffer
- [ ] **Dringend (PG 14 EOL 12.11.2026):** PostgreSQL 14.5 → 19 (#247): Dev-Compose läuft auf 19rc1, Anleitung in `UPGRADING.md` (Dump/Restore getestet). Offen: bei GA auf `postgres:19-trixie` umstellen, README-Compose anpassen
- [x] Docker-Multi-Arch-Build amd64 + arm64 mit `docker/build-push-action` + QEMU (#399, #254, #475), in der CI noch nicht gelaufen
- [ ] Dependabot oder Renovate für Bundler, npm, Docker und Actions einrichten

### Sicherheit
- [ ] Standard-Admin `admin@example.com` / `password` (`db/seeds.rb`): Zugangsdaten per ENV setzen oder Passwortwechsel beim ersten Login erzwingen
- [ ] SMTP-Standard `openssl_verify_mode: "none"` → `"peer"` (`config/environments/production.rb`)
- [ ] Kurzer Security-Check: `rack-attack`-Regeln, CSP-Header, API-Key-Handling

## P1 – Betrieb und Bugs

### Reverse Proxy / HTTPS
- [ ] `config.assume_ssl` und `config.force_ssl` per ENV schaltbar machen (ab Rails 7.1)
- [ ] OAuth-`callback_url` muss hinter dem Proxy `https` liefern (#478)
- [ ] „The change you wanted was rejected“ hinter dem Proxy (CSRF/Origin) reproduzieren und beheben (#201)
- [ ] Doku: Beispielkonfigurationen für nginx, Caddy und Traefik (inkl. `X-Forwarded-Proto`)

### OAuth
- [ ] `token_state`-Cookie (#472) in `app/controllers/o_auths_controller.rb`: `domain: ".#{request.domain}"` nur bei Subdomain-Tenancy setzen, sonst weglassen; `secure: request.ssl?` und `same_site: :lax` ergänzen; Spec dazu
- [ ] Eigene CA-Zertifikate / Self-Signed per Volume + `update-ca-certificates` im Entrypoint (#203)
- [ ] Konfigurierbare Header für den Profil-API-Aufruf (#485)

### E-Mail
- [ ] „Testmail senden“ in den Site Settings
- [ ] Zustellfehler immer loggen, auch wenn `EMAIL_RAISE_DELIVERY_ERRORS=false`
- [ ] SMTP-Doku mit funktionierenden Beispielen (SES, Brevo, SMTP2GO, Exchange; Hinweis auf `EMAIL_SMTP_AUTH=login`) (#330, #446, #294, #385)
- [ ] E-Mail-Änderung bei fehlerhaftem SMTP darf den Nutzer nicht aussperren (#476)
- [ ] Devise-Mails über ActiveJob/Sidekiq verschicken (#444)

### Webhooks
- [ ] Liquid- und JSON-Fehler beim Ausführen speichern und im UI anzeigen (Delivery-Log pro Webhook) (#458)
- [ ] Template beim Speichern bzw. Testen validieren, Hinweis auf `escape_json`
- [ ] Kommentar-Benachrichtigungen reparieren (#431)

### Konfiguration
- [ ] `POSTGRES_DB` getrennt von `POSTGRES_USER` (`config/database.yml`) (#326)
- [ ] `DATABASE_URL` bzw. externe Postgres-Instanz dokumentieren und testen (#207)

### Kleinere Bugs
- [ ] Zähler für ausstehende Posts aktualisiert sich nicht beim Freigeben oder Ablehnen (#445)
- [ ] Kommentarzähler falsch nach dem Löschen eines Kommentars mit Antworten (#220)
- [ ] Custom CSS: Sonderzeichen werden HTML-escaped (#468)
- [ ] Fehlende Übersetzungstexte (#466)
- [ ] System-Spec „Post bearbeiten/löschen“ reparieren (#210)

### Grundsatzentscheidung
- [ ] Multi-Tenancy, Stripe-Billing, Custom-Domain-API und Tenant-Signup behalten oder entfernen? Bei reinem Self-Hosting entfernen (ca. 20 Dateien, weniger Wartung und Angriffsfläche)

## P2 – Frontend und Quick Wins

### Frontend-Modernisierung
- [ ] React 16 → 19 (`ReactDOM.render` entfällt: `react_ujs`/`react-rails` ersetzen oder eigenen Mount mit `createRoot`; `react-redux` 9, `defaultProps`/String-Refs prüfen)
- [ ] `react-beautiful-dnd` → `@hello-pangea/dnd`
- [ ] Bootstrap 4 → 5.3, jQuery und popper.js 1 entfernen (#407 ersetzen)
- [ ] TypeScript 4.3 → 7.x, `tsconfig` anpassen, Typprüfung (`tsc --noEmit`) in der CI
- [ ] 59 `any` in `app/javascript` durch echte Typen ersetzen
- [ ] Aufteilen: `GeneralSiteSettingsP.tsx` (461), `WebhookForm.tsx` (414), `PostP.tsx` (320), `common/_index.scss` (352)
- [ ] `authenticityToken`-Prop-Drilling durch zentralen Helper ersetzen (#165)
- [ ] Turbolinks → Turbo
- [ ] ESLint + Prettier und RuboCop einführen, beide in der CI
- [ ] `app/controllers` (22 Dateien) nach Bereichen gliedern (z. B. `site_settings/`)

### Quick-Win-Features
- [ ] Vorhandene Übersetzungen freischalten: `tr`, `cs`, `el`, `hi`, `ja`, `ko`, `nl`, `pl`, `sr`, `sv` fehlen in `I18n.available_locales` (`config/initializers/locale.rb`) und im Sprachmenü (`GeneralSiteSettingsP.tsx`); vorher Vollständigkeit prüfen
- [ ] Roadmap abschaltbar (#361)
- [ ] Standard-Sortierung pro Board/Instanz (#193, #363, #483)
- [ ] Login nur per OAuth, E-Mail/Passwort-Formular ausblendbar (#471)
- [ ] Favicon einstellbar (#452)
- [ ] Logo-Größe im Mail-Template (#474)
- [ ] Rückfrage beim Verwerfen ungespeicherter Site-Settings (#106)
- [ ] Combobox für den Status im Post-Formular (#119)
- [ ] Roadmap zeigt Votes und Kommentare, Sortierung nach „zuletzt aktualisiert“ (#484)
- [ ] Übersicht „Mein Feedback“ (#429)
- [ ] Eigene Links bzw. URL im Header (#479, #351)
- [ ] Datenbank-Transaktionen in Workflows (#169)

### Lücken zur Konkurrenz (siehe konkurrenz.md)
- [ ] Changelog: Einträge mit erledigten Posts verknüpfen, RSS-Feed, E-Mail an Follower
- [ ] Duplikatsuche beim Erstellen mit Postgres-Volltextsuche (#455) (aus „Mittel“ vorgezogen)
- [ ] Webhook-Vorlagen für Slack, Discord und Teams (#419)
- [ ] MCP-Server auf Basis der bestehenden REST-API

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
- [ ] Automatischer Login nach Tenant-Signup (#263), nur falls Multi-Tenancy bleibt
- [ ] Übersetzungen: Crowdin-PR #417 übernehmen, Polnisch (#450), Übersetzungsprozess festlegen (#121)
- [ ] Bounties (#438), vorerst nicht vorgesehen
