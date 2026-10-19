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

## Fase 2: Lokale productfunctionaliteit ✅ afgerond (2026-10-19)

### Opgeleverd

- **Lokale database** (SQLite via `sqflite`, zie beslissing B5):
  - tabellen `products`, `documents` en `reminders`
  - foreign keys met `ON DELETE CASCADE`
  - migratiesysteem
- **Domein**:
  - Product en ProductCategory
  - ProductInput met ProductValidator: Nederlandse foutmeldingen
  - ProductQuery: zoeken (zonder hoofdletter- en accentgevoeligheid), filteren op categorie, drie sorteringen
- **Nederlandse invoer en notatie**:
  - bedragen zoals `1.299,00` en `12,50`, opgeslagen in centen
  - datums zoals `19 oktober 2026`
- **Schermen**:
  - dashboard met aantal, naderende datums (30 dagen) en recent toegevoegd
  - productoverzicht met zoeken, filters en sorteren
  - productdetail met bewerken en met verwijderen na bevestiging
  - formulier voor toevoegen en bewerken met validatie, en een bevestiging bij niet-opgeslagen wijzigingen
- **Centrale foutafhandeling** met begrijpelijke Nederlandse meldingen.

### Getest

| Controle | Resultaat |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 94 tests geslaagd (unit, repository tegen echte SQLite, notifier, widgets) |
| Handmatig op toestel | Toevoegen, zoeken, filteren, bewerken, verwijderen: werkt |
| Terug met niet-opgeslagen wijzigingen | Vraagt bevestiging via AppBar-pijl, Android-terugknop/gebaar en iOS-veeggebaar |
| App herstarten | Producten blijven bewaard |

### Gevonden en opgelost tijdens het testen

- Hero-conflict: twee zwevende knoppen hadden dezelfde tag in de tabbladen.
- De standaard terugknop omzeilde de bevestiging bij niet-opgeslagen wijzigingen. Het formulier heeft nu een eigen terugknop.

### Bekende beperkingen

- De herinneringsdatum wordt bewaard, maar er gaan nog geen meldingen af (fase 5).
- Er kunnen nog geen documenten aan een product worden gekoppeld (fase 3).
- Scannen en importeren tonen nog "nog in ontwikkeling" (fase 3 en 4).

## Volgende stap

Fase 3: documentbeheer.
- cameratoegang en bestanden importeren
- documenten opslaan in de app-private opslag
- documentviewer
- controle op bestandstype en -grootte
- foutafhandeling
- delen vanuit andere apps (iOS Share Extension, Android intent-filters)
