# Voortgang GarantieBewaker

## Fase 1: Projectbasis ✅ afgerond (2026-10-19)

### Opgeleverd

- **Backend** (Spring Boot 4.1.1, Java 21, Maven):
  - `GET /api/v1/health`: 200 met `UP` als de database bereikbaar is, anders 503
  - Flyway-migratie V1
  - profielen `local` (leest `../.env`) en `prod` (alles uit omgevingsvariabelen)
  - Spring Security: alles geweigerd behalve health en documentatie
  - OpenAPI/Swagger UI, alleen lokaal
- **Docker Compose** met PostgreSQL 17, alleen bereikbaar via `127.0.0.1`.
- **Flutter-app**:
  - Riverpod en GoRouter
  - Material 3-design system: donkerblauw en blauwgroen, contrast gecontroleerd
  - onderste navigatie met Overzicht, Producten en Instellingen
  - lege toestanden en scherm "Aankoop toevoegen" met drie opties
  - privacy-informatie
  - alle teksten in het Nederlands
- **Docs**: README met startcommando's, architectuur, beslissingen en API-overzicht.

### Getest

| Controle | Resultaat | Waar |
|---|---|---|
| `mvn verify` | 11 tests geslaagd, 0 overgeslagen (4 tegen echte PostgreSQL via Testcontainers) | macOS |
| `mvn spring-boot:run` + `curl /api/v1/health` | `{"status":"UP","database":"UP",...}` | macOS |
| `flutter analyze` | No issues found | Flutter 3.47.7 / Dart 3.13.5 |
| `flutter test` | 10 tests geslaagd | Flutter 3.47.7 |
| App starten | Draait | iOS-simulator (iOS 27) en fysieke Samsung-telefoon (Android) |

### Bekende beperkingen

- Knoppen voor scannen, importeren en handmatig invoeren tonen nog "Deze functie is nog in ontwikkeling."
- Herinneringen, export en verwijderen in Instellingen zijn uitgeschakeld (fase 5).
- Er is nog geen Maven Wrapper (`mvn -N wrapper:wrapper` kan nu lokaal worden uitgevoerd).
- De bundel-ID `nl.garantiebewaker.garantiebewaker` is tijdelijk. Wijzig hem vóór publicatie naar een domein dat je zelf bezit.
- Docker Desktop moet draaien voordat je de backend start.
- Er is nog niet handmatig gecontroleerd hoe de app eruitziet met grote systeemletters (fase 6).

### Volgende stap

Fase 2: lokale SQLite-database (drift), het datamodel voor Product, Document en Reminder,
productbeheer (toevoegen, bewerken, zoeken, filteren, sorteren, verwijderen) en een dashboard met echte gegevens.
