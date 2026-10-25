# Account lockout (schützt Konten gegen Brute-Force)

Das Anmelden mit E-Mail und Passwort nutzt Devise `:lockable`: Nach zu vielen
fehlgeschlagenen Anmeldeversuchen wird **das einzelne Konto** gesperrt –
unabhängig von der IP-Adresse und damit auch bei verteilten Angriffen wirksam.
Das ergänzt das IP-basierte rack-attack-Limiting (`/posts`-Anti-Spam, geplante
Regeln für `/api/v1` und `/mcp`), ersetzt es aber nicht.

Betroffene Logins: das alte Formular (`/users/sign_in`) und die App-API
(`POST /api/app/v1/session`).

## Verhalten

- Fehlversuche werden pro Konto gezählt; nach `LOCKABLE_MAXIMUM_ATTEMPTS`
  Versuchen wird das Konto gesperrt.
- Beim Sperren erhält die Person eine E-Mail mit einem Unlock-Link
  (Unlock-Strategie `email` bzw. `both`).
- Bei den Strategien `time` bzw. `both` erlaubt Devise die Anmeldung automatisch
  wieder, sobald die Sperre älter als `LOCKABLE_UNLOCK_IN_HOURS` ist.
- Ein erfolgreicher Login setzt den Fehlversuchs-Zähler zurück.

## Konfiguration

Alle Schwellwerte sind per Umgebungsvariable konfigurierbar:

| Variable                    | Standard            | Werte                             |
|-----------------------------|---------------------|-----------------------------------|
| `LOCKABLE_LOCK_STRATEGY`    | `failed_attempts`   | `failed_attempts`, `none`         |
| `LOCKABLE_UNLOCK_STRATEGY`  | `both`              | `both`, `email`, `time`, `none`   |
| `LOCKABLE_MAXIMUM_ATTEMPTS` | `10`                | Ganzzahl                          |
| `LOCKABLE_UNLOCK_IN_HOURS`  | `2`                 | Ganzzahl (Stunden)                |

Beschreibung:

- **`LOCKABLE_LOCK_STRATEGY`** – wie Konten gesperrt werden. `failed_attempts`
  sperrt nach zu vielen Fehlversuchen, `none` deaktiviert den Schutz
  vollständig (nur für Spezialfälle empfohlen).
- **`LOCKABLE_UNLOCK_STRATEGY`** – wie gesperrte Konten wieder freikommen:
  `both` = E-Mail mit Unlock-Link **und** automatische Freigabe nach der
  konfigurierten Zeit, `email` = nur E-Mail, `time` = nur Zeitablauf, `none` =
  weder noch (Freigabe nur manuell über die Datenbank, z. B. Administrator).
- **`LOCKABLE_MAXIMUM_ATTEMPTS`** – Anzahl der fehlgeschlagenen Anmeldeversuche,
  bevor das Konto gesperrt wird.
- **`LOCKABLE_UNLOCK_IN_HOURS`** – Stunden bis zur automatischen Freigabe (nur
  bei den Strategien `time` und `both` relevant).

Die Werte werden beim Anwendungsstart eingelesen (`config/initializers/devise.rb`);
Änderungen erfordern einen Neustart des Containers.