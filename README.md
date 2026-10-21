# GarantieBewaker

Mobiele app (iOS en Android) om aankopen, aankoopbewijzen en garantiedatums lokaal te bewaren.
Alles blijft op de telefoon: geen account, geen server, geen clouddiensten.

- `mobile/`: Flutter-app (local-first)
- `backend/`: Spring Boot REST API, voorbereid op latere uitbreidingen (nu alleen een healthcheck)
- `docs/`: [architectuur](docs/architectuur.md), [beslissingen](docs/beslissingen.md),
  [API-overzicht](docs/api-overzicht.md), [voortgang](docs/voortgang.md),
  [acceptatietests](docs/acceptatietests.md), [testbestanden](docs/testbestanden/README.md),
  [uitbreidingen](docs/uitbreidingen.md), [publicatiechecklist](docs/publicatie-checklist.md)

> **Status: MVP-functionaliteit compleet (fase 1 t/m 5), fase 6 (kwaliteitscontrole) bezig.**
> Zie [docs/voortgang.md](docs/voortgang.md) voor wat er per fase is getest en de bekende beperkingen.

## Wat de app kan

- Producten handmatig toevoegen, bewerken, zoeken, filteren, sorteren en verwijderen.
- Kassabonnen fotograferen en PDF's of afbeeldingen importeren, ook via "Delen" / "Openen met"
  vanuit andere apps (bijv. een mailbijlage).
- Tekstherkenning op het toestel (Apple Vision / ML Kit) en tekst uit digitale PDF's.
  Winkel, datum, product en prijs worden voorgesteld; de gebruiker controleert altijd zelf.
- Zelf ingevulde garantie-einddatums en herinneringen, met lokale meldingen rond 9:00 uur.
- Gegevens exporteren (ZIP met CSV en alle aankoopbewijzen) en alle gegevens in één keer verwijderen.

De app berekent nooit zelf een garantietermijn en geeft geen juridisch advies.

> **Let op:** deze repository is openbaar. Commit nooit `.env`, echte aankoopbewijzen, exports of
> andere persoonsgegevens. Gebruik de fictieve bestanden in `docs/testbestanden/`.

---

## 1. Benodigdheden (macOS)

```bash
java -version
mvn -v
flutter --version
flutter doctor
docker --version
```

| Onderdeel | Versie |
|-----------|--------|
| Flutter | 3.47 (getest); minimaal 3.44 |
| Java | 21 |
| Maven | 3.9+ |
| Xcode | met iOS-simulator; de app vereist iOS 16+ |
| Android | Android Studio met een toestel of emulator; de app vereist Android 7.0 (API 24)+ |
| Docker Desktop | voor de lokale database en de backend-integratietests |

> Plak in zsh (de standaard-shell op macOS) geen regels met `# opmerking` erachter.
> zsh ziet dat niet als commentaar.

Ontbreekt er iets? Installeer het met [Homebrew](https://brew.sh):

```bash
brew install --cask temurin@21
brew install maven
brew install --cask docker
flutter upgrade
```

Na het installeren van Docker Desktop open je de app één keer.

## 2. Repository ophalen

```bash
cd ~/Projects
git clone https://github.com/ShakeelB58/Garantie-Bewaker.git garantiebewaker
cd garantiebewaker
```

## 3. Mobiele app

### Controleren

```bash
cd ~/Projects/garantiebewaker/mobile
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Verwacht: `No issues found!` en `All tests passed!`.
Twee meldingen in de testuitvoer zijn normaal: `Herkennen mislukt (StateError)` en
`Meldingen inplannen mislukt (StateError)`. Die komen uit tests die expres een fout nabootsen.

### Starten

```bash
flutter devices
flutter run
```

Kies het toestel uit de lijst, of start direct op één toestel met `flutter run -d <apparaat-id>`.

- **iOS-simulator:** `open -a Simulator`. Testbestanden zet je erop met
  `xcrun simctl addmedia booted <foto.jpg>` (naar Foto's) of door ze op het simulatorvenster te slepen.
- **Android-toestel:** zet USB-foutopsporing aan in de ontwikkelaarsopties en sluit het toestel aan.
- **Echte iPhone:** vereist ondertekening in Xcode (`open ios/Runner.xcworkspace`,
  *Signing & Capabilities*, Team kiezen). Met een gratis Apple-account werkt de app 7 dagen.

De eerste keer tekst herkennen op Android downloadt het herkenningsmodel (eenmalig internet nodig).

## 4. Backend

### Database starten (Docker)

```bash
cd ~/Projects/garantiebewaker
cp .env.example .env
open -e .env
```

Kies in het geopende bestand een eigen waarde voor `POSTGRES_PASSWORD` en sla op. Start daarna:

```bash
docker compose up -d
docker compose ps
```

De status moet `healthy` zijn.

> Wachtwoord later wijzigen? PostgreSQL gebruikt het wachtwoord van de eerste start. Na een
> wijziging in `.env` moet je de lokale database leegmaken met `docker compose down -v` en
> opnieuw `docker compose up -d` uitvoeren. Daarbij gaan alle lokale testgegevens verloren.

### Tests

```bash
cd ~/Projects/garantiebewaker/backend
mvn verify
```

Verwacht: `BUILD SUCCESS` (unit-, controller- en PostgreSQL-integratietests).
Draait Docker niet, dan staan de integratietests als **Skipped**. Ze zijn dan niet uitgevoerd.

### Starten

```bash
cd ~/Projects/garantiebewaker/backend
mvn spring-boot:run
```

In een tweede Terminal-venster:

```bash
curl -i http://localhost:8080/api/v1/health
```

Verwacht: `HTTP/1.1 200` en `"status":"UP"`.
API-documentatie: <http://localhost:8080/swagger-ui.html>

### Productie

```bash
SPRING_PROFILES_ACTIVE=prod \
DB_URL=jdbc:postgresql://<host>:5432/<db> DB_USERNAME=<user> DB_PASSWORD=<geheim> \
java -jar target/garantiebewaker-backend-0.1.0-SNAPSHOT.jar
```

In `prod` zijn Swagger UI en `/v3/api-docs` uitgeschakeld. TLS moet worden afgehandeld door een
reverse proxy of het hostingplatform.

## 5. Automatische controle (GitHub Actions)

Bij elke push draait [`.github/workflows/ci.yml`](.github/workflows/ci.yml):

- Flutter: opmaakcontrole (`dart format`), `flutter analyze` en `flutter test`
- Backend: `mvn verify`, inclusief de PostgreSQL-integratietests via Testcontainers

De resultaten staan op GitHub bij de commit (groen vinkje of rood kruisje) en onder het tabblad
*Actions*. De workflow gebruikt geen geheimen.

## Problemen oplossen

| Melding | Oplossing |
|---------|-----------|
| `Could not resolve placeholder 'POSTGRES_PASSWORD'` | `.env` ontbreekt in de hoofdmap, of je startte de backend niet vanuit `backend/`. |
| `Connection refused` naar localhost:5432 | De database draait niet: `docker compose up -d`. |
| `version solving failed` bij `flutter pub get` | Flutter is te oud: `flutter upgrade`. |
| `requires minimum platform version 16.0` (iOS) | Haal de laatste versie op; de app staat op iOS 16. Daarna `flutter clean`. |
| `git pull` weigert door `pubspec.lock` | `git checkout -- mobile/pubspec.lock` en opnieuw `git pull`. |
| Geen meldingen | Instellingen in de app → Meldingen. Staat het op "Uit", zet meldingen aan in de instellingen van je telefoon. Probeer daarna "Testmelding versturen". |
| Tekstherkenning werkt niet op Android | Eenmalig internet nodig om het herkenningsmodel te downloaden. |
