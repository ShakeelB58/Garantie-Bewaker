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

## Fase 3a: Documentbeheer ✅ afgerond (2026-10-19)

### Opgeleverd

- **Kassabon scannen**: camera, daarna controleren met "Gebruiken" of "Opnieuw".
- **Importeren**: PDF of afbeelding uit Bestanden/Downloads of uit de fotobibliotheek.
- **Veilige opslag** in de app-private map (Application Support).
  - In de database staat alleen het relatieve pad.
  - Het type wordt herkend aan de inhoud; maximaal 25 MB.
  - Paden worden streng gecontroleerd (geen path traversal).
- **Tijdelijke bestanden** van camera en kiezer worden direct verwijderd. Losse bestanden worden bij het opstarten opgeruimd.
- **Documenten per product**:
  - toevoegen bij een nieuw product (in het formulier) of bij een bestaand product (op het detailscherm)
  - bekijken: PDF via pdfrx, afbeeldingen met zoom
  - soort wijzigen
  - verwijderen na bevestiging
- **Product verwijderen** verwijdert ook alle documentbestanden.
- **iOS**: Nederlandse toestemmingsteksten voor camera en fotobibliotheek; ontwikkeltaal `nl`. De appnaam is "GarantieBewaker".

### Getest

| Controle | Resultaat |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 145 tests geslaagd (o.a. bestandsopslag op echt bestandssysteem, repository tegen echte SQLite, volledige scan- en importstroom) |
| Kassabon scannen (Samsung) | Werkt, inclusief "Opnieuw" |
| PDF importeren | Werkt |
| Document openen (PDF en foto) | Werkt |
| Product met document verwijderen | Werkt |

### Opmerkingen

- **Cameratoestemming op Android**: de app vraagt geen cameratoestemming. `image_picker` gebruikt de camera-app van het systeem, dus er is niets in te stellen. Dat is zo bedoeld en goed voor de privacy.
- **Nog te testen op een echte iPhone**: de melding als cameratoegang is geweigerd. De simulator heeft geen camera.

### Bekende beperkingen

- Foto's kunnen nog niet worden bijgesneden of rechtgezet. Dat wordt in fase 4 beoordeeld, samen met OCR.
- Android kan de app afsluiten terwijl de camera open is (bij weinig geheugen). In dat geval gaat de foto verloren en moet de gebruiker opnieuw scannen.
- Delen vanuit andere apps: zie fase 3b.

## Fase 3b: Bestanden ontvangen uit andere apps ✅ afgerond (2026-10-19)

### Opgeleverd

- **iOS**: GarantieBewaker staat in het deelmenu bij "Openen met" voor PDF, JPEG, PNG en HEIC.
  - geen Share Extension nodig (beslissing B9)
  - nooit de standaard-app voor deze bestanden
- **Android**: GarantieBewaker verschijnt bij "Delen" en "Openen met", bijvoorbeeld vanuit Mijn bestanden, Galerij en Gmail.
- **Verwerking**: een binnenkomend bestand wordt gecontroleerd en veilig opgeslagen. Daarna opent "Product toevoegen" met het document erbij.
- **Opruimen**: tijdelijke kopieën worden verwijderd (cache en iOS `Documents/Inbox`).
- **Testbestanden**: fictieve factuur (PDF) en kassabon (JPG) in `docs/testbestanden/`.

### Getest

| Controle | Resultaat |
|---|---|
| `flutter analyze` / `flutter test` | Geslaagd volgens de gebruiker (uitvoer niet in het verslag opgenomen) |
| Samsung: delen vanuit Mijn bestanden, Galerij en Gmail | Werkt (bevestigd door de gebruiker) |
| Samsung: app open en app gesloten | Werkt (bevestigd door de gebruiker) |
| iPhone-simulator: delen vanuit Bestanden | Werkt (bevestigd door de gebruiker) |

### Bekende beperkingen

- Er wordt één bestand tegelijk ontvangen. Bij delen van meerdere bestanden wordt alleen het eerste gebruikt.
- iOS Mail is alleen op een echte iPhone te testen.

## Volgende stap

Fase 4: OCR en PDF-tekstextractie.
- lokale tekstherkenning: ML Kit op Android, en ML Kit of Apple Vision op iOS
- tekst rechtstreeks uit digitale PDF's lezen (pdfrx)
- gescande PDF's pagina voor pagina renderen en daarop OCR uitvoeren
- een parser voor winkel, datum, totaalbedrag en productregels, met een herkenningsstatus per veld
- het controleformulier markeert herkende en onzekere velden
