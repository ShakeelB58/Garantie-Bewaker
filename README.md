# GarantieBewaker

Mobiele app (iOS en Android) om aankopen, aankoopbewijzen en garantiedatums lokaal te bewaren.

- `mobile/`: Flutter-app, local-first, geen account nodig
- `backend/`: Spring Boot REST API (fase 1: alleen een healthcheck)
- `docs/`: [architectuur](docs/architectuur.md), [beslissingen](docs/beslissingen.md), [API-overzicht](docs/api-overzicht.md)

> **Status: fase 1 (projectbasis).** De app heeft navigatie, een design system en lege schermen.
> Producten opslaan, scannen, PDF-import en herinneringen volgen in fase 2–5.

---

## 1. Benodigdheden controleren (macOS)

Voer dit uit in Terminal:

```bash
java -version        # moet 21 of hoger zijn
mvn -v               # Apache Maven 3.9+
flutter --version    # Flutter 3.44+ aanbevolen
flutter doctor       # controleert Xcode, Android Studio en de simulators
docker --version     # optioneel, nodig voor de lokale database en integratietests
```

Ontbreekt er iets? Installeer het met [Homebrew](https://brew.sh):

```bash
brew install --cask temurin@21   # Java 21
brew install maven               # Maven
brew install --cask docker       # Docker Desktop (daarna één keer openen)
flutter upgrade                  # als je Flutter ouder is dan 3.44
```

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
git status            # controleer: géén .env in de lijst
git add mobile
git commit -m "Flutter-platformbestanden voor Android en iOS"
git push
```

## 4. Backend

### Database starten (Docker)

```bash
cd ~/Projects/garantiebewaker
cp .env.example .env
open -e .env          # kies een eigen waarde voor POSTGRES_PASSWORD en sla op
docker compose up -d
docker compose ps     # status moet "healthy" zijn
```

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
flutter analyze       # verwacht: "No issues found!"
flutter test          # verwacht: "All tests passed!"
```

### Starten op de iOS-simulator

```bash
open -a Simulator
flutter run
```

### Starten op een Android-emulator

```bash
flutter emulators                       # toont beschikbare emulators
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
