# Technische beslissingen

Elke beslissing met datum, keuze en reden. Nieuwe beslissingen onderaan toevoegen.

## B1: Spring Boot 4.1.1 met Java 21 (2026-10-18)

- **Keuze:** Spring Boot 4.1.1 (laatste stabiele versie op Maven Central), Java 21 LTS.
- **Reden:** de 3.x-lijn krijgt sinds medio 2026 geen gratis ondersteuning meer.
  Spring Boot 4 vereist minimaal Java 17, dus Java 21 past.
- **Gevolgen van Spring Boot 4:**
  - starter heet `spring-boot-starter-webmvc` (was `-web`)
  - Flyway heeft `spring-boot-starter-flyway` nodig
  - tests gebruiken `spring-boot-starter-webmvc-test`
  - `@WebMvcTest` en `@AutoConfigureMockMvc` staan in `org.springframework.boot.webmvc.test.autoconfigure`
  - Jackson 3 (`tools.jackson`)
- **springdoc-openapi 3.1.1:** de 3.1-lijn is gebouwd op Spring Boot 4.1.
- **Testcontainers 2.x** (versie beheerd door Spring Boot): artefacten `testcontainers-postgresql`
  en `testcontainers-junit-jupiter`, klasse `org.testcontainers.postgresql.PostgreSQLContainer`.

## B2: Nog geen Maven Wrapper (2026-10-18)

- **Keuze:** fase 1 gebruikt een lokaal geïnstalleerde Maven (`brew install maven`).
- **Reden:** de werkomgeving waarin de code is geschreven had geen toegang tot Maven Central,
  dus de wrapper kon niet worden gegenereerd. Zodra Maven lokaal werkt, maak je hem met
  `mvn -N wrapper:wrapper` (zie README). Daarna kan iedereen `./mvnw` gebruiken.

## B3: Material uit de Flutter-SDK, nog niet `material_ui` (2026-10-18)

- **Context:** sinds Flutter 3.44 is Material in de SDK bevroren. Vanaf 3.47 bestaat het losse
  pakket `material_ui`. De SDK-versie is nog niet officieel deprecated.
- **Keuze:** voorlopig `package:flutter/material.dart`.
- **Reden:** veel plugins die we nodig hebben (camera, bestandskiezer, OCR, PDF) gebruiken nog de
  SDK-variant. Als je beide mengt, krijg je typeconflicten (bijvoorbeeld `ColorScheme`).
- **Vervolg:** migreren wanneer de SDK-variant deprecated wordt en de gekozen plugins zijn
  overgestapt. Herbeoordelen in fase 6.

## B4: Riverpod 3 en go_router (2026-10-18)

- `flutter_riverpod: ^3.0.0`
- `go_router: ">=17.0.0 <19.0.0"`: versie 18 vereist Flutter 3.44+. Met dit bereik werkt het
  project ook op een iets oudere Flutter, en pub kiest automatisch de hoogste versie die past.
- Freezed en json_serializable zijn in fase 2 bewust niet gebruikt: de modellen zijn klein en met de hand geschreven, zonder codegeneratie (zie B5). Opnieuw bekijken bij JSON-export (fase 5).
- Dio wordt pas toegevoegd als de app met de backend praat; dat gebeurt in de MVP niet.

## B5: Lokale database: sqflite in plaats van drift (2026-10-19)

- **Keuze:** `sqflite` 2.4 met handgeschreven SQL en eigen migraties (`lib/core/storage/migrations.dart`).
  Voor tests op de computer: `sqflite_common_ffi`.
- **Oorspronkelijk voorstel:** `drift`.
- **Reden van de wijziging:**
  - drift vereist codegeneratie (`build_runner`), dus een extra stap na elke schemawijziging
  - de code wordt geschreven in een omgeving zonder Flutter, waar gegenereerde code niet te controleren is
  - met gewone SQL is elke regel leesbaar en direct te testen
- **Gevolgen:**
  - typeveiligheid zit in de repository-laag (`SqfliteProductRepository`), niet in gegenereerde code
  - repository-tests draaien tegen echte SQLite
- **Regels:**
  - een uitgebrachte migratie wordt nooit gewijzigd
  - `ON DELETE CASCADE` met `PRAGMA foreign_keys = ON`
  - nooit `INSERT OR REPLACE` op `products`, want dat verwijdert via de cascade ook gekoppelde documenten

## B6: Opslagformaten lokaal (2026-10-19)

- Datums (aankoop, garantie-einde): `yyyy-MM-dd`.
- Tijdstippen (`created_at`, `updated_at`): ISO 8601 in UTC.
- `reminders.trigger_at`: lokale wandkloktijd zonder tijdzone (`2027-06-01T09:00:00`).
  Een herinnering moet om 09:00 in de tijdzone van de gebruiker afgaan, ook na een verhuizing of zomertijd.
- Bedragen in gehele centen. Valuta als ISO 4217-code.
- Categorieën als vaste sleutels (`household`, `phone_tablet`, …). Een onbekende sleutel wordt "Overig".

## B7: Eén product per document, voorlopig (2026-10-19)

- `documents.product_id` koppelt een document aan precies één product, zoals in het datamodel van de masterprompt.
- Een bon met meerdere producten (masterprompt §5) vraagt mogelijk later een koppeltabel `product_documents`.
  Dat wordt in fase 3/4 beslist en dan met een nieuwe migratie toegevoegd.

## B8: Documentbeheer (2026-10-19)

- **Pakketten:**
  - `image_picker` 1.2: camera en fotobibliotheek. Officieel Flutter-pakket; op Android 13+ gebruikt het de systeem-fotokiezer.
  - `file_picker` 13: PDF's en afbeeldingen uit Bestanden en Downloads. Vanaf v12 met statische API (`FilePicker.pickFile`).
  - `pdfrx` 2.6: PDF-weergave via PDFium. Gekozen omdat het in fase 4 ook tekst kan uitlezen en pagina's kan renderen voor OCR.
    pdfrx gebruikt intern al `material_ui` (zie B3); dat botst niet, zolang we geen Material-typen aan pdfrx doorgeven.
  - `path_provider` 2.1 voor de app-private map.
- **Opslaglocatie:** `getApplicationSupportDirectory()/documents/<uuid>.<ext>`.
  - App-privé en niet zichtbaar in de Bestanden-app. Niet in een publieke map.
  - In de database staat alleen het **relatieve** pad. Op iOS verandert het absolute pad na app-updates.
- **Veiligheid:**
  - Het bestandstype wordt herkend aan de **inhoud** (magic bytes), niet aan de naam.
  - Maximaal 25 MB per document.
  - Paden worden gecontroleerd met een strikt patroon (`documents/<id>.(pdf|jpg|png|heic)`), wat path traversal voorkomt.
  - Bestandsnamen worden opgeschoond voordat ze worden bewaard.
- **Tijdelijke bestanden:**
  - Camera- en kiezerkopieën in de cache worden direct na het importeren verwijderd.
  - Alleen bestanden in de tijdelijke map van de app worden ooit verwijderd, originelen van de gebruiker nooit.
  - Bij het starten van de app worden losse documentbestanden opgeruimd die ouder zijn dan 1 uur en nergens bij horen.
- **Volgorde bij het verwijderen:** eerst het databaserecord, daarna het bestand.
  Mislukt het verwijderen van het bestand, dan ruimt de opstartcontrole het later op.
- **Nog niet:**
  - Bijsnijden of perspectief corrigeren van foto's. Een documentscanner wordt in fase 4 samen met OCR beoordeeld.
  - Delen vanuit andere apps volgt als apart onderdeel (fase 3b).

## B9: Bestanden ontvangen uit andere apps zonder Share Extension (2026-10-19)

- **Keuze:** optie A, "Openen met" / "Delen", via het pakket `open_file_handler` 3.0.
  Gekozen door de product-eigenaar, met het oog op publicatie in App Store en Play Store.
- **iOS:**
  - `CFBundleDocumentTypes` voor PDF, JPEG, PNG en HEIC
  - rol "Viewer", rang "Alternate": GarantieBewaker wordt nooit de standaard-app voor deze bestanden
  - `LSSupportsOpeningDocumentsInPlace = false`: iOS levert een kopie aan, het origineel blijft onaangeroerd
  - de `SceneDelegate` geeft binnenkomende URL's door, bij een koude start en terwijl de app draait
  - geen Share Extension en geen App Groups nodig
- **Android:**
  - intent-filters voor `VIEW` (Openen met) en `SEND` (Delen), met dezelfde vier MIME-types
  - `launchMode="singleTask"`, zodat een nieuw bestand naar de draaiende app gaat
  - `MainActivity` kopieert het bestand naar de cache (`alwaysCopy = true`)
- **Verwerking in Flutter:** hetzelfde pad als bij importeren (`DocumentService.stage`).
  - controle op inhoud en grootte
  - opslaan in de app-private map
  - het formulier "Product toevoegen" opent met het document erbij
- **Opruimen:** de kopie in de cache en, op iOS, het bestand in `Documents/Inbox` worden na verwerking verwijderd.
  Daarna worden de iOS-toegangsrechten vrijgegeven (`releaseIosURIs`).
- **Later mogelijk:** een Share Extension (optie B), als blijkt dat gebruikers die nodig hebben.
  Daarvoor zijn een betaald Apple Developer-account en App Groups nodig.

## Openstaande risico's

| Risico | Aanpak |
|--------|--------|
| ML Kit-tekstherkenning draait waarschijnlijk niet op de iOS-simulator van Apple Silicon-Macs | OCR testen op een echte iPhone. Alternatief: Apple Vision via platform channels. Beslissing in fase 4. |
| Weinig gratis PDF-bibliotheken die zowel tekst lezen als pagina's renderen | Onderzoek aan het begin van fase 4. Licenties (bijv. Syncfusion) expliciet beoordelen. |
| "Delen met app" vanuit Mail vraagt native configuratie (iOS Share Extension, Android intent-filters) | Apart onderdeel in fase 3, op beide platformen handmatig testen. |
| iOS staat maximaal 64 geplande meldingen toe; Android 12+ vraagt aparte toestemming voor exacte alarmen | Niet-exacte meldingen gebruiken, alleen de eerstvolgende plannen en bij het opstarten opnieuw plannen (fase 5). |
| De bundel-ID `nl.garantiebewaker.garantiebewaker` is een tijdelijke keuze | Vóór de eerste publicatie wijzigen naar een domein dat je zelf bezit. |
