# Voortgang Bonvrij

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
- **iOS**: Nederlandse toestemmingsteksten voor camera en fotobibliotheek; ontwikkeltaal `nl`. De appnaam is "Bonvrij".

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

- **iOS**: Bonvrij staat in het deelmenu bij "Openen met" voor PDF, JPEG, PNG en HEIC.
  - geen Share Extension nodig (beslissing B9)
  - nooit de standaard-app voor deze bestanden
- **Android**: Bonvrij verschijnt bij "Delen" en "Openen met", bijvoorbeeld vanuit Mijn bestanden, Galerij en Gmail.
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

## Fase 4: Herkenning van bonnen en facturen ✅ afgerond (2026-10-21)

### Opgeleverd

- **Tekst lezen op het toestel**, zonder internet of clouddienst:
  - foto's via OCR: Apple Vision op iOS, ML Kit op Android (pakket `text_sight`, beslissing B10)
  - digitale PDF's: de tekstlaag wordt direct gelezen (`pdfrx`)
  - gescande PDF-pagina's worden als afbeelding door OCR gehaald (maximaal 10 pagina's)
- **Parser** (`ReceiptParser`, pure Dart) zoekt winkel, aankoopdatum, totaalbedrag, productregels en btw, met een zekerheid per veld.
- **Controleformulier**:
  - een kaart "Gegevens overgenomen uit het document" met het totaalbedrag van het document
  - onder elk overgenomen veld een hint; onzekere velden in oranje met een waarschuwingsicoon
  - de hint verdwijnt zodra de gebruiker het veld aanpast
  - bij meerdere producten kiest de gebruiker zelf welk product hij bewaart; het totaalbedrag wordt niet aan één product gekoppeld
  - lukt herkennen niet of is het geen aankoopbewijs, dan een duidelijke melding en gewoon zelf invullen
- **Privacy**: de herkende tekst wordt niet opgeslagen (beslissing B11). Alleen wat de gebruiker met "Opslaan" bevestigt, komt in de database.
- **Platform**: iOS-minimumversie 16.0, Android minSdk 24; de cameratoestemming die ML Kit toevoegt is verwijderd.

### Verbeteringen na testen met een echte bon (Kruidvat)

- Productregels stoppen bij "Subtotaal" of "Aantal artikelen"; voordeel-, spaar- en pinterminalregels zijn geen product of totaal.
- "Kruidvat" werd als btw-regel gezien (het woord bevat "vat"); opgelost.
- Een logo dat als losse letter wordt gelezen ("OKRUIDVAT") wordt genegeerd.
- Naam op de ene regel en "2 x 8,49 per stuk" op de volgende regel worden samengevoegd; de stuksprijs wordt de productprijs.
- Een foto zonder bedrag of datum geeft "Geen gegevens herkend" in plaats van een gegokte winkelnaam.

### Getest

| Controle | Resultaat |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | Alle tests geslaagd (parser met nagemaakte voorbeeldbonnen, tekstopbouw, PDF-/OCR-service, volledige stroom van scannen tot opslaan) |
| Testfactuur (PDF) en testbon (foto) op de Samsung | Juist herkend (bevestigd door de gebruiker) |
| Testbon (foto) op de iPhone-simulator | Juist herkend met Apple Vision (bevestigd door de gebruiker) |
| Echte Kruidvat-bon op de Samsung | Winkel, producten en stuksprijs juist na de verbeteringen (bevestigd door de gebruiker) |
| Foto zonder bon | Melding "geen gegevens herkend" |
| Herkend veld aanpassen | Hint verdwijnt (bevestigd door de gebruiker) |

### Bekende beperkingen

- Herkenning werkt met vaste regels. Bonnen met een ongewone opmaak kunnen deels verkeerd herkend worden; de gebruiker controleert altijd alles voor het opslaan.
- Op Android wordt het herkenningsmodel bij het eerste gebruik gedownload (eenmalig internet nodig).
- Foto's worden niet bijgesneden of rechtgezet. Een scheve of gekreukte bon wordt minder goed gelezen.
- De PDF-import met herkenning is niet op iOS getest: het lukte niet de testfactuur in de simulator te zetten. Het lezen van PDF's gebeurt op beide platformen met dezelfde code (pdfrx/PDFium) en werkt op Android.
- Testen op een echte iPhone lukte nog niet (ondertekening met een gratis Apple-account). Dit volgt bij de publicatievoorbereiding.

## Fase 5: Herinneringen en privacy ✅ afgerond (2026-10-21)

### Opgeleverd

- **5a – Herinneringen** (beslissing B12):
  - lokale meldingen rond 9:00 op de herinneringsdatum; tikken opent het product
  - alles opnieuw inplannen na opslaan of verwijderen en bij elke start; maximaal 50 ingepland
  - toestemming pas bij het aanzetten van een herinnering; zonder toestemming blijft de herinnering bewaard
  - Instellingen: standaardherinnering (1 week tot 3 maanden), status van meldingen, testmelding
  - productnaam verborgen op het Android-vergrendelscherm
  - nieuwe tabel `settings` (databaseversie 2), met migratietest vanaf versie 1
- **5b – Privacy** (beslissing B13):
  - export als ZIP: `producten.csv` (beveiligd tegen CSV-injectie), alle aankoopbewijzen en een uitleg
  - alle lokale gegevens verwijderen, pas na een bevestigingsvinkje
  - cache van de bestandskiezer wordt bij elke start opgeruimd
  - test die afdwingt dat logregels alleen het fouttype bevatten
  - app-versie bij "Over Bonvrij"

### Getest

| Controle | Resultaat |
|---|---|
| `flutter analyze` / `flutter test` | Geslaagd (op de Mac van de gebruiker en in GitHub Actions) |
| Meldingen toestaan, testmelding, standaardherinnering, voorstel in formulier | Werkt op Samsung en iPhone-simulator (bevestigd door de gebruiker) |
| Export maken en ZIP openen | Werkt op beide toestellen (bevestigd door de gebruiker) |
| Versienummer | Werkt op beide toestellen (bevestigd door de gebruiker) |
| Melding op de herinneringsdatum zelf, product openen via de melding | Werkt (bevestigd door de gebruiker) |
| Alle lokale gegevens verwijderen | Werkt op beide toestellen (bevestigd door de gebruiker) |

### Bekende beperkingen

- Android mag een melding iets later tonen (niet-exact inplannen, om geen extra toestemming nodig te hebben).
- Bij meer dan 50 toekomstige herinneringen worden de latere pas ingepland bij een volgende start van de app.
- De export wordt in het geheugen opgebouwd. Bij honderden grote foto's kan dat traag zijn of te veel geheugen vragen.
- De app heeft geen eigen back-up. Een export moet de gebruiker zelf bewaren.

## Fase 6: Kwaliteitscontrole ✅ afgerond (2026-10-21)

### Opgeleverd

- **Automatische controle (GitHub Actions)** bij elke push: `dart format`-controle, `flutter analyze`, `flutter test` en `mvn verify` (met PostgreSQL via Testcontainers). Fouten verschijnen als annotaties bij de commit. Een commit met `[format]` in de boodschap laat de code automatisch opmaken.
- **Opmaak:** alle Dart-code opgemaakt met `dart format`.
- **Toegankelijkheid:**
  - automatische tests op tikgrootte (48×48 / 44×44), labels voor schermlezers en tekstcontrast voor alle hoofdschermen
  - productkaarten, de overzichtskaart en datumvelden worden als één knop voorgelezen
  - beschrijvingen bij foto's en PDF's
- **Schermformaten:** alle hoofdschermen getest op een klein (320×568) en groot (412×915) scherm, met normale tekst en tekst op 200%. Gevonden en opgelost:
  - productkaart: een lange prijs duwde de rest uit beeld
  - formulier: "Aankoopprijs" en "Valuta" passen niet naast elkaar bij grote tekst; nu onder elkaar
  - keuzelijsten (categorie, valuta) kapten tekst niet netjes af
  - vensters konden bij grote tekst niet helemaal getoond worden; ze scrollen nu
  - de knop "Aankoop toevoegen" viel bij de grootste iOS-tekst (310%) deels buiten beeld (gevonden door de gebruiker op de iPhone-simulator). Het label groeit nu tot maximaal 150%; past het dan nog niet, dan wordt het een ronde plusknop met tooltip
- **Documentatie:** README herschreven, [handmatige acceptatietests](acceptatietests.md) toegevoegd.

### Getest

| Controle | Resultaat |
|---|---|
| GitHub Actions: Flutter (analyse en tests) | Geslaagd |
| GitHub Actions: Spring Boot (`mvn verify`) | Geslaagd |
| Handmatige acceptatietests op de toestellen | Zie [acceptatietests.md](acceptatietests.md) |

### Bekende beperkingen

- Een echte iPhone is nog niet getest (camera, meldingen, "Openen met" vanuit Mail). Dit staat op de publicatiechecklist.
- De PDF-import is op iOS alleen via dezelfde code als op Android gedekt, niet handmatig op de simulator.
- Offline gebruik is alleen op de Samsung handmatig getest; de app bevat geen netwerkcode.
- Gescande en meerpagina-PDF's zijn alleen automatisch getest, niet met een echt bestand op een toestel.

## Fase 7: Voorbereiding op uitbreiding ✅ afgerond (2026-10-21)

### Opgeleverd

- [uitbreidingen.md](uitbreidingen.md): hoe accounts, cloudback-up en synchronisatie, serveropslag van documenten, Plus via in-app-aankopen en AI-herkenning later veilig kunnen worden toegevoegd. Niets daarvan is gebouwd.
- [publicatie-checklist.md](publicatie-checklist.md): accounts en kosten, technische stappen (app-ID, icoon, ondertekening, target-SDK, privacymanifest), privacyverklaring en store-labels, winkelpagina, TestFlight en de verplichte gesloten test van Google Play (12 testers, 14 dagen).

### Open beslissingen (vóór publicatie)

1. Eigen app-ID (bundel-ID), na publicatie niet meer te wijzigen.
2. Alleen iPhone of ook iPad.
3. Back-ups van iCloud en Google aan laten (advies) en vermelden in de privacyverklaring.
4. Beschikbaarheid van de naam "Bonvrij" in beide stores.

## Na de MVP: naam en nieuw ontwerp ✅ afgerond (2026-10-21)

### Opgeleverd

- **Naam Bonvrij** (B14): alle teksten, appnaam, meldingen en export. Interne namen
  (pakket, database, tijdelijk app-ID) bewust ongewijzigd.
- **Nieuw ontwerp** (B15), volgens de mockup van de product-eigenaar:
  - onderbalk met Home, Producten, ronde plusknop, Documenten en Instellingen
  - welkomstscherm (één keer) en Home met begroeting, tegels en "Recent toegevoegd"
  - productkaarten met categorie-icoon en "Over N dagen"
  - productdetails met labels, uitklapbare gegevens en knoppen onderaan
  - herkenningsscherm met voortgangsbalk en stappen; controlescherm met "Herkenning: goed/controleren"
  - nieuw: tabblad **Documenten** en scherm **Herinneringen** met hoofdschakelaar
  - **camera in de app**, met kader, flitser en "Kiezen uit foto's"; zonder microfoon
  - app-icoon, opstartscherm, meldingsicoon (Android) en lettertype Poppins (SIL OFL)
- **CI uitgebreid:** foutdetails en gemiste tikken als annotaties, automatisch opmaken met `[format]`.

### Getest

| Controle | Resultaat |
|---|---|
| GitHub Actions: analyse, alle tests, backend | Geslaagd |
| Nieuwe tests: welkom, Home, Documenten, Herinneringen, hoofdschakelaar, scanner zonder camera, 310% tekst | Geslaagd |
| Ontwerp, icoon en camera op Samsung en iPhone-simulator | Werkt (bevestigd door de gebruiker) |

### Bekende beperkingen

- De camera is niet automatisch te testen; handmatig getest op de Samsung. Op een echte iPhone nog niet.
- Geweigerde cameratoestemming is nog niet handmatig getest op de Samsung.
- iOS-camera: Apple kan bij de beoordeling een microfoontekst (`NSMicrophoneUsageDescription`) vragen, ook al gebruikt de app de microfoon niet. Zie de publicatiechecklist.

## MVP: definitie van klaar

| Eis uit het projectplan | Status |
|---|---|
| Flutter-app werkt op iOS en Android | ✅ Samsung (Android 16) en iPhone-simulator (iOS 27) |
| Producten lokaal beheren | ✅ |
| Kassabonnen fotograferen en met OCR verwerken | ✅ |
| PDF-facturen importeren en verwerken | ✅ |
| Herkende gegevens corrigeren | ✅ |
| Originele documenten veilig lokaal bewaren | ✅ |
| Lokale herinneringen instellen | ✅ |
| Verwijderen en foutafhandeling betrouwbaar | ✅ |
| Zonder internet bruikbaar | ✅ (eerste ML Kit-download op Android uitgezonderd) |
| Spring Boot-backend start, healthcheck werkt | ✅ |
| Databaseconfiguratie en migraties gedocumenteerd en getest | ✅ Flyway + Testcontainers |
| Geautomatiseerde tests slagen | ✅ lokaal en in GitHub Actions |
| Bekende beperkingen vermeld | ✅ per fase hierboven |
| Instructies om te starten en te testen | ✅ README |

## Volgende stap

De MVP is af. Volgende stappen, wanneer je wilt:

1. De vier open beslissingen hierboven nemen.
2. De technische punten uit de [publicatiechecklist](publicatie-checklist.md) laten uitvoeren (app-ID, icoon, meldingsicoon, privacymanifest, ondertekening).
3. Testen met een paar mensen via TestFlight en de gesloten test van Google Play.
