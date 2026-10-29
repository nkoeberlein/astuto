# Roadmap – Astuto Evolution

Stand: 25.10.2026 · Repository: [nkoeberlein/astuto-evo](https://github.com/nkoeberlein/astuto-evo) · Branch `develop`

Astuto Evolution führt das archivierte [astuto/astuto](https://github.com/astuto/astuto) als Community-Projekt weiter. Name und Herkunft bleiben erkennbar, der Neuanfang ebenfalls: aktueller Stack, neue Oberfläche, KI-Funktionen. Ziel ist **kein Eigenbedarf**, sondern ein eigenständiges Open-Source-Projekt für die Nische aus der [Konkurrenzanalyse](konkurrenz.md). Konkrete Aufgaben: [todo.md](todo.md).

## 1. Vision und Nische

**Positionierung:** *Das schlanke, selbst gehostete Feedback-Portal ohne Nutzerlimits, mit anonymem Feedback, DSGVO-freundlich und KI-nativ über MCP.*

| Zielgruppe | Warum Astuto Evolution |
|---|---|
| Kleine und mittlere SaaS-Teams | Kein Preis pro Nutzer oder Seat wie bei Canny oder Featurebase; ein Docker-Image |
| **Mittelständische Unternehmen (kommerziell)** | Self-Hosting im eigenen Rechenzentrum, mehrere Produkte/Marken pro Instanz (Multi-Tenancy), SSO, Datenschutz, optional Support und SLA |
| EU-/DACH-Firmen, Behörden, Bildung | Daten bleiben im eigenen Haus, keine Telemetrie, KI optional mit lokalem Modell |
| Open-Source-Projekte | Kostenlos, AGPL, öffentliche Roadmap, Feedback ohne Account |
| Interne IT / Unternehmensportale | Self-Hosting, OAuth/SSO, später LDAP |

**Abgrenzung:**
- **Quackback** wird zur Support-Suite (Inbox, Help Center, Statusseite). Astuto Evolution bleibt bewusst ein Feedback-Portal: weniger Betrieb, weniger Angriffsfläche.
- **Fider** ist schlicht, hat aber keine Roadmap und kein Changelog, und Moderation steckt in der Cloud hinter einer Paywall. Astuto Evolution hat beides bereits und bleibt komplett frei.
- **Proprietäre Tools** konkurrieren über den Preis pro Nutzer. Astuto Evolution kennt keine Limits.

**Bewusst nicht geplant** (Abgleich mit der Konkurrenz, 25.10.2026), damit das Portal schlank bleibt:
- Help Center, Support-Inbox, Statusseite (Quackback-Richtung)
- Umfragen (NPS/CSAT): eigenes Produkt
- Priorisierungs-Frameworks (RICE/ICE): gehören in Jira, Linear oder Productboard; Astuto liefert die Daten über API, MCP und Integrationen
- Umsatzverknüpfung (Canny Business): braucht CRM- oder Billing-Daten der Kunden; höchstens später über Nutzersegmente
- Eigene Slack- oder Teams-Apps: beim Self-Hosting müsste jede Installation eine eigene App registrieren; Webhook-Vorlagen und MCP decken den Bedarf
- Reaktionen sowie Budget- oder Credit-Voting: das einfache Vote-Modell ist ein Merkmal (Downvotes #421 vor einer Umsetzung ebenfalls hinterfragen)
- Eigene Connectoren zum automatischen Einsammeln von Feedback (Canny Autopilot): stattdessen über MCP, siehe Phase 4

**Prinzipien:**
1. Läuft mit einem Image plus PostgreSQL, ohne weitere Pflichtdienste.
2. KI ist optional („Bring your own model“: OpenAI-kompatible API, Anthropic, lokal per Ollama). Ohne KI funktioniert alles.
3. Keine Telemetrie. Kostenloses Self-Hosting mit vollem Funktionsumfang, auch kommerziell. Geld verdient das Projekt höchstens mit Dienstleistungen (Hosting, Support, SLA), nicht mit gesperrten Funktionen (siehe 7.).
4. Kompatibel zu Astuto 1.x: bestehende Installationen lassen sich mit Anleitung migrieren.

## 2. Ausgangslage

| Punkt | Befund |
|---|---|
| Upstream | `astuto/astuto` archiviert, End of Life seit 09.01.2026 (#487). 2.343 Sterne, 186 Forks, kein aktiver Nachfolger. |
| Offene Upstream-Issues | 72 (ca. 15 Bugs bzw. Betriebsprobleme, ca. 45 Feature-Wünsche). Sie bilden den Startbestand für die Planung. |
| Codebasis | ca. 4.900 Zeilen Ruby, ca. 16.000 Zeilen TS/TSX, 374 Tests. Sauber strukturiert (Controller → Policies → Workflows → Models). |
| Multi-Tenancy und SaaS-Teile | `tenant_id` in allen Tabellen, Tenant-Signup, Custom Domains, Stripe-Billing des eingestellten astuto.io-Angebots (ca. 20 Dateien) |
| Lizenz | AGPL-3.0 (bleibt) |

### Plattform – Stand und Ziel

| Komponente | Upstream | Jetzt (`develop`) | Ziel 2.0 |
|---|---|---|---|
| Ruby | 3.0.6 (EOL) | **4.0.9** | 4.0 ✓ |
| Rails | 6.1 (EOL) | **8.1.4** | 8.1 ✓ |
| Devise | 4.7.3 | **5.0.4** | 5.x ✓ |
| PostgreSQL | 14.5 (EOL 12.11.2026) | 18 (Dev; 19rc1-Volume verworfen) | 19 (GA 19.11.2026) |
| Node (Build) | 20 (EOL) | **26** (Laufzeit-Image ohne Node) | 26 LTS ✓ |
| Debian-Basis | 11 (EOL, Image baute nicht mehr) | 13 trixie | 13 trixie |
| Docker-Image | `riggraz/astuto`, amd64 | CI: `ghcr.io/nkoeberlein/astuto-evo`, amd64 + arm64 | ✓ |
| Frontend | React 16, Redux, Bootstrap 4 | unverändert | ersetzt (siehe 3.); v3: komplett TypeScript |

## 3. Versionsstrategie

| Version | Ziel |
|---|---|
| **v2** | Pakete modernisieren (✅ Backend fertig), den kompletten React-16/Redux/Bootstrap-4-Teil entsorgen und ersetzen: entweder durch sauberes **Rails 8 (Hotwire)** oder durch ein **strikt getrenntes, modernes Frontend** gegen eine Rails-JSON-API. Dazu MCP und Betriebsfixes. |
| **v3** | Umstellung auf **komplett TypeScript**: TanStack Start mit Drizzle (PostgreSQL) und Tailwind. Rails entfällt. (Entscheidung getroffen, siehe todo.md) |

### Die Wahl für v3 bestimmt das v2-Frontend (entschieden: TanStack)

| v3-Stack | Passendes v2-Frontend | Warum |
|---|---|---|
| **TanStack Start (React)** ✅ entschieden | **Getrenntes Frontend:** React 19 + TypeScript 7 + TanStack Router/Query + Tailwind 4 + shadcn/ui, gebaut mit Vite, als SPA gegen eine versionierte Rails-JSON-API (OpenAPI aus rswag → generierter TS-Client) | Die v2-Oberfläche lebt in v3 weiter. In v3 wird nur das Backend ersetzt (Rails → TanStack-Start-Serverfunktionen + Drizzle). Der Übergang erfolgt schrittweise, Endpunkt für Endpunkt („Strangler“). |
| **SvelteKit** | *(verworfen)* **Rails 8 mit Hotwire** (Turbo + Stimulus, ViewComponent, Tailwind) | Ein React-Frontend wäre bei SvelteKit Wegwerfarbeit. Hotwire wäre für v2 der günstigste saubere Weg gewesen. Mitnehmen ließen sich nur Design und Tailwind-Klassen. |

**Entscheidung: TanStack.** Das Team bleibt bei React, die Arbeit am v2-Frontend ist nicht verloren, und v3 wird zu einem Backend-Tausch statt zu einem zweiten Komplett-Neubau. Das Ökosystem (shadcn/ui, TanStack Table/Query/Form) deckt Admin-Tabellen, Formulare und das Widget ab.

**Folgen der Empfehlung für v2:**
- Rails wird zur reinen API- und Auth-Schicht. Die heutigen JSON-Endpunkte des alten Frontends werden zu einer dokumentierten `/api/app/v1`-Schnittstelle (Session-Cookie + CSRF); die öffentliche `/api/v1` für Integrationen (API-Key) bleibt.
- Auslieferung weiter als **ein Image**: Rails liefert das gebaute SPA als statische Dateien aus. SSR für SEO der öffentlichen Boards kommt mit v3 (TanStack Start). Bis dahin werden Meta-Tags serverseitig gesetzt.
- Devise bleibt für Login, OAuth und Mails; die Login-Seiten werden SPA-Seiten gegen JSON-Endpunkte.
- Das alte Frontend wird Seite für Seite ersetzt und am Ende vollständig entfernt (`react-rails`, `react_ujs`, Redux, Bootstrap, jQuery, Turbolinks, Webpack, `i18n-js` 3, `connection_pool`-Pin).

**Anforderungen an die neue UI:** Mobile first, Dark Mode, WCAG 2.2 AA, Branding über CSS-Variablen, ein Komponentensatz auch für das einbettbare Widget, Übersetzungen aus den bestehenden YAML-Dateien (als JSON exportiert), RTL-fähig (CSS-Logical-Properties, `dir` aus der Locale; RTL-Übersetzungen, sobald jemand sie beisteuert).

**Multi-Tenancy bleibt (entschieden).** Mehrere Feedback-Portale pro Instanz sind für Unternehmen mit mehreren Produkten oder Marken und für Agenturen wichtig (#76) und die Grundlage einer möglichen gehosteten Variante. Tenant-Signup, Custom Domains und Stripe-Billing bleiben vorerst erhalten. Ob Billing modernisiert oder entfernt wird, hängt vom Geschäftsmodell ab (siehe 7.).

## 4. Phasen

### Phase 0 – Fork übernehmen ✅
- Upstream-PRs #477, #470, #459, #463, #460 übernommen; #463 (kaputtes YAML) und #460 (Filter wirkungslos, Backend-Filter defekt) nachgebessert
- CI baut Multi-Arch-Images für GHCR
- Umbenennung in **Astuto Evolution**, Links auf `nkoeberlein/astuto`, README und CONTRIBUTING neu
- Ausgangszustand: 374 Tests

### Phase 1 – Plattform (Backend fertig) · P0
- [x] Ruby 4.0.9, Rails 8.1.4 mit `load_defaults` 8.1, Devise 5, Puma 8, Sidekiq 8.1, Stripe 20, Debian trixie, Node 26 – Tests grün, keine Deprecations, Produktions-Image läuft
- [x] Dependabot, `bundler-audit`, Brakeman, lokales `bin/ci`
- [ ] PostgreSQL 19 bei GA (Anleitung in [UPGRADING.md](UPGRADING.md) ist fertig und getestet)
- [x] Security-Policy (`SECURITY.md`)
- [ ] Multi-Tenancy-Modus testen und dokumentieren (Subdomains, Custom Domains, Tenant-Verwaltung); Billing je nach Geschäftsmodell (siehe 7.)

### Phase 2 – Betrieb und Bugfixes · P1
Die häufigsten Probleme aus den Upstream-Issues: HTTPS hinter Reverse Proxy (#478, #201), OAuth-Cookie (#472), SMTP (#330 u. a.), Webhook-Fehler sichtbar machen (#458), konfigurierbare DB (#326, #207), Standard-Admin-Passwort, unsicherer SMTP-Standard. Details in todo.md.

### Phase 3 – Altes Frontend ersetzen · P1 (Kern von v2, begonnen)
1. ✅ Entscheidung: v3 wird **TanStack Start + Drizzle + Tailwind** → v2 bekommt ein getrenntes React-Frontend
2. ✅ `frontend/` mit Vite 8, React 19, **TypeScript 7**, TanStack Router/Query, Tailwind 4, shadcn/ui, **Biome** (statt ESLint/Prettier), Vitest; eigener CI-Workflow; Build ins Image, ausgeliefert unter `/next`
3. ✅ App-API `/api/app/v1` (lesend: Session, Übersetzungen, Boards, Status, Posts, Kommentare), OpenAPI per rswag, generierte TS-Typen
4. ✅ Board-Seite (Suche, Sortierung, Statusfilter, Mehr laden) und Post-Detail mit Kommentaren
5. ✅ Schreibende Aktionen: Post anlegen (auch anonym, mit Freigabe-Regeln und Spam-Schutz), Vote (optimistisch), Kommentar und Antwort, Moderator-Updates, Follow, Bearbeiten/Löschen, Statuswechsel; CSRF-Fluss getestet
6. ✅ Roadmap-Seite, serverseitige Meta-Tags
7. ✅ Auth-Seiten (Login, Registrierung, Passwort, OAuth) und eingebettete Roadmap
8. ✅ Moderation (Feedback-Queue, Nutzer) und Site Settings (✅ General, Boards, Status; offen: Roadmap, Auth, Appearance, Webhooks, Invitations)
9. Altes Frontend und dessen Gems/Pakete entfernen (`react-rails`, `i18n-js`, Webpack, Bootstrap)

### Phase 4 – KI und MCP · P1 (MCP in 2.0, Rest 2.x)
- ✅ **MCP-Server** (Streamable HTTP unter `/mcp` auf dem offiziellen `mcp`-Gem, Auth per API-Key, später OAuth). Tools: Posts suchen, lesen, anlegen, Status ändern, kommentieren, Votes und Trends abfragen, Roadmap lesen. Damit triagieren Claude, Cursor und andere Assistenten Feedback direkt. Unter den Self-Hosted-Tools hat das sonst nur Quackback.
- **Duplikaterkennung** beim Erstellen (#455): ✅ Postgres-Volltextsuche · offen: optional semantisch mit pgvector und Embeddings, Zusammenführen (Merge) mit konsolidierten Votes – bisher nur im v3-Schema (6.) geplant, wäre aber auch für v2 sinnvoll
- **KI-Funktionen (opt-in, eigenes Modell):** ✅ Zusammenfassung langer Diskussionen (Moderatoren, neues Frontend) · offen: Vorschläge für Tags und Board (braucht Tags), Changelog-Entwürfe (braucht Changelog), Übersetzung von Feedback
- Datenschutz: Was an den KI-Anbieter geht, ist dokumentiert und abschaltbar; lokales Modell per Ollama wird unterstützt
- **Feedback aus anderen Quellen über MCP** statt eigener Connectoren: Ein Assistent in Slack oder Teams liest einen Thread und legt den Post an. Dafür fehlen nur ein Feld „Quelle/Link“ am Post und „im Namen von“ in `create_post`

### Phase 5 – Nischen-Features · P2
- **Changelog** mit RSS und E-Mail an Follower; **RSS pro Board** mit derselben Technik
- **Digest für Nutzer** (Opt-in: Top-Requests, Statuswechsel gefolgter Posts), Erweiterung der bestehenden Recap-Mails für Moderatoren
- **Vertrauensstufen:** die ersten N Posts eines Kontos prüfen, danach automatisch freigeben (#362-Familie)
- **Private Boards** (#414), **Tags** (#171), **Anhänge** (#253, #482; Speicherregel beachten: kein Active Storage, Entscheidung zwischen S3-kompatibel und Postgres, siehe todo.md)
- **Import** aus Canny, Fider und CSV (#368), um Wechsler aufzunehmen
- **Widget mit Besucher-Identifikation** (signiertes JWT pro Tenant aus der eigenen App): Voraussetzung dafür, dass Widget-Votes echten Kunden zugeordnet werden, und zugleich „Login aus der eigenen App“ ohne OAuth
- **Einbettbares Widget**, **Webhook-Vorlagen** für Slack, Discord und Teams (#419), **signierte Webhooks** (HMAC-Header)
- **LDAP/SAML** (#8) für Unternehmen und Behörden
- Später: **Nutzersegmente** (Votes nach Kundengruppe filtern oder gewichten; setzt Besucher-Identifikation und Custom Fields #420 voraus, Gewichtung steht im v3-Schema) und **Verfallsregeln** (Filter „seit X Monaten ohne Aktivität“, automatisches Archivieren nur als Opt-in)
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
| `3.0.0` | Komplett TypeScript | TanStack Start + Drizzle + Tailwind, Rails entfernt, Daten-Migration aus v2 automatisch |

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
- **Webhook-URL und -Header:** mit `ActiveSupport::MessageEncryptor` (AES-256-GCM) verschlüsselt, Inhalt seit 2.0 als **JSON** (Migration `ReencryptWebhooksAsJson` hat die alten Marshal-Werte umgeschrieben). In TypeScript mit `node:crypto` entschlüsselbar: Schlüssel = SHA-256 von `SECRET_KEY_BASE`, Format `base64(daten)--base64(iv)--base64(tag)`.

**Der Vertrag zwischen v2 und v3 ist die App-API** (`/api/app/v1`, OpenAPI). Das v2-Frontend hängt nicht am Datenbankschema. v3 implementiert dieselben Endpunkte auf dem neuen Schema, und das Frontend läuft weiter.

**Regeln für v2, damit die Migration einfach bleibt** (stehen auch in AGENTS.md): keine `serialize`/`store`-Spalten (natives `jsonb`), keine polymorphen Assoziationen, kein Active Storage für Dateien, keine Ruby-spezifischen Formate in der Datenbank. Der aktuelle Stand erfüllt das.

**Lizenz (entschieden: AGPL-3.0):**
- v2 ist ein abgeleitetes Werk und bleibt **AGPL-3.0** mit den ursprünglichen Copyright-Hinweisen.
- **v3 bleibt AGPL-3.0**, bei Bedarf dual lizenziert. Die übersetzten Texte (YAML/JSON), Logo, Schema-Wissen und Community-Beiträge dürfen direkt weiterverwendet werden, und die AGPL schützt die Nische (Self-Hosting) vor geschlossenen SaaS-Ablegern.
- Soll es in v3 zusätzlich eine kommerzielle Lizenz für den Mittelstand geben (Abschnitt 7), ist ab dem ersten v3-Commit eine CLA nötig.

**GitHub (Entscheidung offen):** Den Fork vom archivierten Upstream lösen lassen (GitHub-Support), damit Codesuche und Sichtbarkeit normal funktionieren. v3 im selben Repository entwickeln (Orphan-Branch, beim Release zu `main`, v2 als `v2`-Branch) oder in einer Organisation `astuto-evolution`.

## 7. Kommerzieller Einsatz im Mittelstand

**Ziel:** Kostenloses Self-Hosting bleibt der Kern. Zugleich soll Astuto Evolution für mittelständische Unternehmen (etwa 50–1.000 Mitarbeitende) im kommerziellen Einsatz taugen: intern, für Kundenportale und für mehrere Produkte.

**Was diese Zielgruppe erwartet** (fließt in die Prioritäten der todo.md ein):
- **Identität:** SSO über OIDC (vorhanden: beliebige OAuth2-Anbieter), zusätzlich **SAML** und **LDAP/AD** (#8), Login nur über SSO (#471), automatische Rollen über Gruppen, **2FA/MFA für Admins und Moderatoren**
- **Mandanten:** mehrere Portale pro Instanz mit eigener Domain und eigenem Branding (vorhanden, testen und dokumentieren), Verwaltung über eine Instanz-Admin-Oberfläche
- **Compliance:** Audit-Log (wer hat was geändert), DSGVO-Funktionen (Export und Löschung pro Person, Aufbewahrungsfristen), Datenverarbeitung ohne Drittanbieter, KI nur opt-in mit eigenem Modell
- **Betrieb:** Backup/Restore-Anleitung, mehrere Web-Instanzen hinter Load Balancer, Health-Check-Endpunkt, Prometheus-Metriken, Helm-Chart, signierte Images mit SBOM
- **Vertrauen:** `SECURITY.md` mit Meldeweg, Sicherheitsupdates mit Fristen, dokumentierte Versionen mit Supportzeitraum (LTS)
- **Integration:** Jira, Azure DevOps, Teams, Slack (Webhook-Vorlagen zuerst), REST-API und MCP

**Lizenz und Mittelstand:** Die AGPL-3.0 erlaubt kommerzielle Nutzung ohne Einschränkung. Pflichten entstehen erst, wenn jemand den Code *ändert* und Nutzern über das Netz anbietet: Dann muss er die Änderungen veröffentlichen. Manche Rechtsabteilungen lehnen AGPL trotzdem grundsätzlich ab. Optionen:
- **v2:** Eine zusätzliche kommerzielle Lizenz ist nicht möglich, weil der Upstream-Code von Dritten unter AGPL steht. Abhilfe: eine kurze FAQ „AGPL im Unternehmen“ (unveränderter Betrieb verpflichtet zu nichts).
- **v3 (Neuentwicklung):** Duale Lizenzierung (AGPL + kommerzielle Lizenz) wird möglich, aber nur mit einer **CLA** für alle Beiträge ab Beginn von v3 und ohne übernommene Upstream-Inhalte (Übersetzungen, Logo). Die Lizenz ist entschieden: **v3 bleibt AGPL-3.0** (Abschnitt 6).

**Mögliche Einnahmen ohne Paywall** (Entscheidung offen):

| Modell | Passt zu | Voraussetzung |
|---|---|---|
| Gehostete Variante (Managed, EU-Hosting) | Firmen ohne eigenen Betrieb | Multi-Tenancy (vorhanden), Billing (vorhanden, Stripe-Gem modernisieren) |
| Support und SLA | Mittelstand mit eigener Installation | Versionierung mit LTS, Ansprechpartner |
| Kommerzielle Lizenz | AGPL-scheue Rechtsabteilungen | erst in v3, CLA |
| Einrichtung und Integration (Dienstleistung) | SSO, Migration von Canny/UserVoice | Import-Funktion (#368) |

