# Roadmap – Astuto-Fork (nkoeberlein/astuto)

Stand: 24.10.2026 · Basis: Commit `ac6ad92` (identisch mit `astuto/astuto@main`)

## 1. Ausgangslage

| Punkt | Befund |
|---|---|
| Upstream | `astuto/astuto` ist **archiviert** und seit 09.01.2026 offiziell End of Life (Issue #487). Keine Fixes oder Sicherheitsupdates mehr. |
| Fork | 0 Commits vor, 0 hinter Upstream, also eine reine Kopie. Keine eigenen Issues. |
| Community | 2.343 Sterne, 186 Forks, aber kein aktiver Nachfolge-Fork (nur Forks ohne Sterne). Wer weitermacht, muss es selbst tun. |
| Offene Upstream-Issues | 72 (davon ca. 15 Bugs bzw. Betriebsprobleme, ca. 45 Feature-Wünsche) |
| Offene Upstream-PRs | 8, davon 5 übernehmbar (#477, #470, #460, #463, #459) und 1 großes Feature mit Konflikten (#454 Bild-Upload) |
| Lizenz | AGPL-3.0: Wer eine geänderte Version öffentlich betreibt, muss den Quellcode bereitstellen. |

### Codebasis

- **Backend:** Rails 6.1 · Ruby 3.0.6 · PostgreSQL 14.5 · Devise 4.7.3 · Pundit · Sidekiq (optional) · Liquid (Webhooks) · rswag (REST-API-Doku)
- **Frontend:** React 16 + Redux 4 + TypeScript 4.3, gebaut mit Webpack 5 über jsbundling; Bootstrap 4; Turbolinks
- **Umfang:** ca. 4.900 Zeilen Ruby in `app/`, ca. 16.000 Zeilen TS/TSX in `app/javascript/` (225 Dateien), 55 Spec-Dateien (Modelle, Policies, API, System-Tests mit Capybara)
- **Struktur:** sauber und konventionell (Controller → Policies → Workflows → Models, Frontend nach actions/reducers/components/containers). Gut lesbar.
- **Deployment:** Docker (Multi-Stage), Entrypoint migriert die DB automatisch. CI pusht nach `riggraz/astuto` auf Docker Hub, das passt für den Fork nicht.
- **SaaS-Ballast:** Multi-Tenancy, Stripe-Billing, Custom-Domain-API (`ASTUTO_CNAME_API_*`) und Tenant-Signup stecken in ca. 20 Dateien. Für Self-Hosting mit einer Instanz wird das nicht gebraucht.

### Technische Schulden (alle EOL bzw. ohne Sicherheitsupdates)

| Komponente | Ist | Ziel |
|---|---|---|
| Ruby | 3.0.6 (EOL seit 04/2024) | 4.0 (Zwischenschritt 3.3 für Rails 6.1–8.1) |
| Rails | 6.1.7.9 (EOL seit 10/2024) | 8.1 (nur 8.1 bekommt noch Updates) |
| Devise | 4.7.3 | 5.x (braucht Rails ≥ 7.0) |
| Node (Build) | 20 (EOL 04/2026) | 26 LTS (ab 28.10.2026), bis dahin 24 LTS |
| PostgreSQL | 14.5 (**EOL 12.11.2026**) | 18 |
| React | 16.14 | 19.x |
| Bootstrap | 4.6 (EOL) | 5.3 |
| TypeScript | 4.3 | 7.x |
| Docker-Basis | Debian 11 bullseye (EOL 08/2026, Image baut nicht mehr) | Debian 13 trixie |
| Docker-Image | nur amd64 | amd64 + arm64 |

## 2. Entscheidung: weiterpflegen oder neu schreiben?

**Empfehlung: weiterpflegen und schrittweise modernisieren. Nicht neu schreiben.**

Gründe dafür:
- Die Codebasis ist klein (ca. 21k Zeilen), sauber strukturiert und hat Tests. Nichts daran ist grundsätzlich kaputt, sie ist nur veraltet.
- Der Upgrade-Pfad Rails 6.1 → 7.0 → 7.1 → 7.2 → 8 ist gut dokumentiert und oft gegangen. Geschätzt **1–3 Wochen** bis zu einem aktuellen, sicheren Stand.
- Der Funktionsumfang ist beachtlich: Boards, Roadmap, Votes, Kommentare, Moderation, OAuth2 mit beliebigem Anbieter, Webhooks mit Liquid-Templates, REST-API mit API-Keys, Recap-E-Mails, 10+ Sprachen, Branding. Ein Neubau bis zu diesem Stand kostet realistisch **2–4 Monate**, ohne dass ein Nutzer etwas Neues bekommt.
- Die meisten offenen Bugs sind Konfigurations- oder Proxy-Probleme mit kleinen, lokalen Fixes.

Ein Neubau lohnt sich nur, wenn mindestens eins davon zutrifft:
- Du willst einen anderen Stack, den du selbst besser beherrschst (z. B. Next.js/TypeScript durchgehend), und Rails-Know-how fehlt dauerhaft.
- Du brauchst ein grundlegend anderes Produkt (z. B. Feedback eingebettet in deine eigene App statt eines separaten Portals).
- Du willst nur einen Bruchteil der Features. Dann ist ein schlanker Neubau schneller als der Umbau.

Mittelweg, falls das Frontend stört: Backend behalten und das React-16/Redux-Frontend später modulweise ersetzen (Phase 3). Die REST-API existiert schon.

Alternative ohne Code: ein gepflegtes Open-Source-Tool nutzen. **Quackback** (sehr aktiv, viel breiter) oder **Fider** (schlicht, stabil) sind heute weniger Aufwand, wenn keine eigenen Anpassungen geplant sind. Ein kompletter Neubau lohnt sich nicht: Quackback ist schon der moderne Open-Source-Neubau eines Canny-Klons. Details in [konkurrenz.md](konkurrenz.md).

## 3. Phasen

### Phase 0 – Fork übernehmen (≈ 1–2 Tage) · Priorität P0
Ziel: Der Fork ist eigenständig baubar, deploybar und nimmt alle sinnvollen Upstream-Reste auf.
- CI auf eigene Registry umstellen (GHCR statt `riggraz/astuto`)
- Lokales Setup und Testsuite auf dem aktuellen Stand verifizieren
- Kleine Upstream-PRs übernehmen: #477 (Gravatar), #470 (`RAILS_HOSTS`), #460 (Nutzersuche), #463 (Türkisch), #459 (Dependabot)
- README und Branding anpassen (EOL-Hinweis, Image-Name, Doku-Links)
- Entscheiden: Multi-Tenancy/Billing behalten oder entfernen (siehe Phase 2)

### Phase 1 – Plattform-Upgrade (≈ 1–3 Wochen) · Priorität P0
Ziel: Kein EOL-Laufzeitbestandteil mehr, Sicherheitsupdates wieder möglich.
- Ruby 3.0 → 3.3, Rails 6.1 → 7.0 → 7.1 → 7.2 (jeweils mit grüner Testsuite), danach optional Rails 8
- Devise, Puma, Sidekiq, Stripe-Gem und weitere Gems aktualisieren; `bundle audit` und `yarn audit` sauber
- Node 22 LTS im Dockerfile, PostgreSQL 16 mit Upgrade-Anleitung (#247)
- Multi-Arch-Docker-Image amd64 + arm64 (#399, #254, #475)
- Dependabot oder Renovate einrichten

### Phase 2 – Betrieb und Bugfixes (≈ 1–2 Wochen) · Priorität P1
Ziel: Die häufigsten Betriebsprobleme aus den Issues verschwinden.
- **Reverse Proxy / HTTPS:** `assume_ssl`/`force_ssl` per ENV (geht ab Rails 7.1), korrekte `https`-Redirect-URI (#478), CSRF-Fehler hinter Proxy (#201), Doku für nginx, Traefik und Caddy
- **OAuth-Cookie** `token_state` (#472): wahrscheinliche Ursache ist `domain: ".#{request.domain}"`, das bei mehrteiligen TLDs (`.co.uk`), IP-Adressen und `localhost` ungültig ist; dazu fehlt `secure`. Der Fix ist lokal in `o_auths_controller.rb`.
- **SMTP** (#330, #446, #294, #385, #476): unsicheren Standard `openssl_verify_mode: none` ändern, Testmail-Button in den Site Settings, Fehler loggen, Doku mit Beispielen (SES, Brevo, SMTP2GO, Exchange)
- **Webhooks** (#458): JSON-Fehler beim Rendern im UI anzeigen (Delivery-Log), Template beim Speichern validieren
- DB-Name und externe Postgres-Instanz konfigurierbar (#326, #207), eigene CA-Zertifikate (#203)
- Kleinere Bugs: #445, #220, #431, #468, #466, #210
- **Standard-Admin** (`admin@example.com` / `password`): beim ersten Start Passwortwechsel erzwingen oder Zugangsdaten per ENV setzen
- Optional: SaaS-Code entfernen (Stripe, Billing, Custom-Domain-API, Tenant-Signup), wenn nur eine Instanz selbst betrieben wird. Das spart Wartung und Angriffsfläche.

### Phase 3 – Frontend-Modernisierung (≈ 2–4 Wochen) · Priorität P2
Ziel: Wartbares Frontend, damit Features schneller gehen.
- React 16 → 18, `react-beautiful-dnd` (nicht mehr gepflegt) → `@hello-pangea/dnd`
- Bootstrap 4 → 5 (#407), jQuery-Abhängigkeit entfernen
- TypeScript 5, 59 `any` durch echte Typen ersetzen
- Große Dateien aufteilen (`GeneralSiteSettingsP.tsx` 461 Zeilen, `WebhookForm.tsx` 414, `PostP.tsx` 320)
- `authenticityToken`-Prop-Drilling beseitigen (#165), Turbolinks → Turbo
- ESLint und RuboCop einführen und in der CI ausführen

### Phase 4 – Features (laufend) · Prioritäten P2–P3
Sortiert nach Aufwand und Nutzen:
- **Quick Wins:** Roadmap abschaltbar (#361), Standard-Sortierung einstellbar (#193, #363, #483), reiner OAuth-Login (#471), Favicon (#452), Rückfrage beim Verwerfen von Änderungen (#106), Status-Combobox (#119), Roadmap mit Votes und Kommentaren (#484), Übersicht eigener Posts (#429)
- **Lücken zur Konkurrenz** (siehe [konkurrenz.md](konkurrenz.md)): Changelog mit RSS und E-Mail, Duplikatsuche (#455), Slack/Discord/Teams-Vorlagen für Webhooks (#419), MCP-Server auf Basis der REST-API, Canny- und CSV-Import (#368), einbettbares Widget
- **Mittel:** Bild-Upload und Anhänge (#253, #482, auf PR #454 aufbauen), Tags (#171), private Boards (#414), Admin-Freigabe neuer Nutzer (#362), Import/Export (#368), Roadmap per Drag-and-drop sortieren (#473), Duplikatsuche beim Erstellen (#455), Kommentar-Votes (#408), Soft-Delete für Kommentare (#162), API um Invitations und Follows erweitern (#434)
- **Groß / später:** LDAP/AD (#8), GitHub-Integration (#365), Custom JavaScript (#376, Sicherheitsrisiko, nur mit CSP), mehrere Marken pro Instanz (#76), Downvotes und Vote-Limits (#421, #422), Custom Fields (#420), private Kommentare (#418)
- **Übersetzungen:** Crowdin-Stand übernehmen (PR #417), Polnisch (#450); eigenen Crowdin-Zugang oder Übersetzungen per PR festlegen (#121)

## 4. Meilensteine

| Version | Inhalt | Kriterium |
|---|---|---|
| `v2.0.0` | Phase 0 + 1 | Rails ≥ 7.2, Ruby ≥ 3.3, Tests grün, Multi-Arch-Image auf GHCR |
| `v2.1.0` | Phase 2 | OAuth, SMTP und Webhooks hinter HTTPS-Proxy funktionieren, Doku vorhanden |
| `v2.2.0` | Phase 3 | React 18, Bootstrap 5, Linter in CI |
| `v2.3+` | Phase 4 | Feature-Releases nach Bedarf |

Die konkreten Aufgaben stehen in [todo.md](todo.md).
