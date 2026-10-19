# GarantieBewaker

Mobiele app (iOS en Android) om aankopen, aankoopbewijzen en garantiedatums lokaal te bewaren.

- `mobile/`: Flutter-app, local-first, geen account nodig
- `backend/`: Spring Boot REST API (fase 1: alleen een healthcheck)
- `docs/`: [architectuur](docs/architectuur.md), [beslissingen](docs/beslissingen.md), [API-overzicht](docs/api-overzicht.md)

> **Status: fase 3 afgerond.** Producten beheren, kassabonnen fotograferen, PDF's en afbeeldingen
> importeren, bekijken en vanuit andere apps delen werkt lokaal op iOS en Android.
> Tekstherkenning (fase 4) en meldingen (fase 5) volgen.
> Zie [docs/voortgang.md](docs/voortgang.md).

---

## 1. Benodigdheden controleren (macOS)

Voer dit uit in Terminal:

```bash
java -version
mvn -v
flutter --version
flutter doctor
docker --version
```

Verwacht: Java 21 of hoger, Maven 3.9+, Flutter 3.44+ (aanbevolen). Docker is nodig voor de
lokale database en de integratietests.

> Let op: plak in zsh (de standaard-shell op macOS) geen regels met `# opmerking` erachter.
> zsh ziet dat niet als commentaar.

Ontbreekt er iets? Installeer het met [Homebrew](https://brew.sh):

```bash
brew install --cask temurin@21
brew install maven
brew install --cask docker
flutter upgrade
```

Na het installeren van Docker Desktop open je de app één keer. `flutter upgrade` is alleen nodig
als je Flutter ouder is dan 3.44.

## 2. Repository ophalen

```bash
cd ~/Projects
git clone https://github.com/ShakeelB58/Garantie-Bewaker.git garantiebewaker
cd garantiebewaker
```

## 3. Eenmalig: Flutter-platformbestanden aanmaken

De Dart-code staat al klaar. De Android- en iOS-projectbestanden maak je één keer aan.
`flutter create` overschrijft bestaande bestanden niet.

```bash
cd ~/Projects/garantiebewaker/mobile
flutter create --org nl.garantiebewaker --project-name garantiebewaker --platforms android,ios .
flutter pub get
```

De nieuwe bestanden in `mobile/android` en `mobile/ios` commit je daarna:

```bash
cd ~/Projects/garantiebewaker
git status
```

Controleer dat `.env` **niet** in de lijst staat. Daarna:

```bash
git add mobile
git commit -m "Flutter-platformbestanden voor Android en iOS"
git push
```

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

### Tests uitvoeren

```bash
cd ~/Projects/garantiebewaker/backend
mvn verify
```

Verwacht resultaat: `BUILD SUCCESS`, met 3 tests in `HealthServiceTest`, 4 in `HealthControllerTest`
en 4 in `PostgresIntegrationTest`.
Draait Docker niet, dan staan de 4 integratietests als **Skipped**. Ze zijn dan niet uitgevoerd.

### Backend starten

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

### Optioneel: Maven Wrapper toevoegen

```bash
cd ~/Projects/garantiebewaker/backend
mvn -N wrapper:wrapper
./mvnw verify
```

### Productie

```bash
SPRING_PROFILES_ACTIVE=prod \
DB_URL=jdbc:postgresql://<host>:5432/<db> DB_USERNAME=<user> DB_PASSWORD=<geheim> \
java -jar target/garantiebewaker-backend-0.1.0-SNAPSHOT.jar
```

In `prod` zijn Swagger UI en `/v3/api-docs` uitgeschakeld. TLS moet worden afgehandeld door een
reverse proxy of het hostingplatform.

## 5. Mobiele app

```bash
cd ~/Projects/garantiebewaker/mobile
flutter analyze
flutter test
```

Verwacht: `No issues found!` en `All tests passed!` (145 tests na fase 3a).

### Starten op de iOS-simulator

```bash
open -a Simulator
flutter run
```

### Starten op een Android-emulator

```bash
flutter emulators
```

Kies een emulator-id uit de lijst en start die:

```bash
flutter emulators --launch <emulator-id>
flutter run
```

Zie je meerdere apparaten? Kies er een met `flutter run -d <apparaat-id>` (`flutter devices` toont de lijst).

## Problemen oplossen

| Melding | Oplossing |
|---------|-----------|
| `Could not resolve placeholder 'POSTGRES_PASSWORD'` | `.env` ontbreekt in de hoofdmap, of je startte de backend niet vanuit `backend/`. |
| `Connection refused` naar localhost:5432 | De database draait niet: `docker compose up -d`. |
| `version solving failed` bij `flutter pub get` | Flutter is te oud: `flutter upgrade`. |
| `CocoaPods not installed` | `brew install cocoapods`, daarna opnieuw `flutter run`. |
