# Uitbreidingen: hoe later veilig toe te voegen

Dit document beschrijft hoe de MVP later kan groeien. **Niets hiervan is gebouwd.** De MVP blijft
local-first: geen account, geen server, geen cloud. Elke uitbreiding hieronder vraagt eerst een
eigen beslissing in [beslissingen.md](beslissingen.md), een privacy-afweging en tests.

## Uitgangspunten die blijven gelden

- **De app moet zonder account blijven werken.** Uitbreidingen zijn opt-in.
- **De gebruiker controleert herkende gegevens altijd zelf.** De app berekent nooit zelf een garantietermijn.
- **Gegevensminimalisatie:** alleen naar een server sturen wat strikt nodig is.
- **Geen geheimen in Git**, en geen echte aankoopbewijzen of persoonsgegevens in tests of logs.
- **AVG/GDPR:** zodra er gegevens van gebruikers op een server komen, zijn er nodig:
  - een privacyverklaring
  - een verwerkingsregister
  - verwerkersovereenkomsten met hostingpartijen
  - een manier om alle gegevens te verwijderen

## Wat er al klaarstaat

- **UUID's als id's** voor producten, documenten en herinneringen. Ze kunnen later ongewijzigd naar
  een server, zonder botsingen tussen toestellen.
- **Tijdstempels:** `createdAt` en `updatedAt` (UTC) op producten, nodig voor synchronisatie.
- **Opslag achter interfaces:**
  - `ProductRepository`, `DocumentRepository`, `DocumentFileStore`, `SettingsRepository`
  - `TextRecognizer` en `ReceiptParser`

  Een cloudvariant kan ernaast komen zonder de schermen te wijzigen.
- **Backend:**
  - Spring Boot 4 met Flyway-migraties (`V1__baseline.sql`), PostgreSQL en integratietests met Testcontainers
  - de geplande endpoints in [api-overzicht.md](api-overzicht.md) zijn bewust geblokkeerd (401)
  - het `prod`-profiel schakelt Swagger uit

## 1. Accounts en authenticatie

**Aanpak**
- **Geen eigen wachtwoordopslag.** Gebruik een bewezen identiteitsdienst met OpenID Connect,
  bijvoorbeeld Keycloak (zelf hosten), Auth0, Firebase Authentication of Supabase Auth.
- **Inloggen met Apple:** biedt de iOS-app inloggen met Google of Facebook aan, dan eist Apple
  ook een gelijkwaardige, privacyvriendelijke inlogoptie, zoals "Inloggen met Apple"
  (App Store-richtlijn 4.8).
- **Backend:** Spring Security als *resource server* die JWT-tokens controleert op uitgever,
  doelgroep, vervaldatum en handtekening.
- **App:**
  - kortlevende access tokens (minuten) en refresh tokens
  - opslag in de Keychain (iOS) of Keystore (Android), via `flutter_secure_storage`
  - nooit in SQLite of in logs
- **Account verwijderen in de app** is verplicht in de App Store (richtlijn 5.1.1(v)) en in
  Google Play. Dat verwijdert ook alle servergegevens.

**Gegevensisolatie**
- Elke tabel krijgt een `owner_id`.
- Elke query filtert op de ingelogde gebruiker; die komt uit het token, nooit uit de request-body.
- Integratietests bewijzen dat gebruiker A de gegevens van gebruiker B niet kan lezen, wijzigen
  of verwijderen. Dat is de belangrijkste test.
- Overweeg *row level security* in PostgreSQL als extra laag.

**Overig**
- Rate limiting op inloggen en API-aanroepen.
- Sessies intrekken bij uitloggen of verdachte activiteit.
- Auditlog zonder inhoud van documenten.

## 2. Cloudback-up en synchronisatie

**Stap 1: alleen back-up (eenvoudigst)**
- Versleutelde export naar de cloud van de gebruiker zelf (iCloud Drive of Google Drive),
  gebaseerd op de bestaande ZIP-export.
- Geen eigen server nodig, en daarmee weinig AVG-verplichtingen.

**Stap 2: synchronisatie tussen toestellen (eigen server)**
- **Per wijziging** een `updatedAt` en een versienummer. Bij een conflict wint per veld de
  laatste wijziging; meld het aan de gebruiker als dat gegevens raakt die hij zelf heeft ingevuld.
- **Verwijderen** als markering (*tombstone*), zodat andere toestellen het ook verwijderen.
  Na een termijn wordt het definitief opgeruimd.
- **Lokaal blijft leidend:** de app werkt offline en synchroniseert later.
- Opslag in de EU.

**Versleuteling**
- Minimaal TLS onderweg en versleuteling op de server (*at rest*).
- Sterker is end-to-end-versleuteling met een sleutel die alleen op de toestellen van de
  gebruiker staat. Dan kan de server niets lezen, maar bij verlies van de sleutel is alles weg.
  Dit is een bewuste productkeuze.

## 3. Veilige serveropslag van documenten

- **Objectopslag** (S3-compatibel), privé-buckets, versleuteld, in de EU.
- **Nooit publiek toegankelijke URL's.** Uploaden en downloaden via kortlevende *presigned URLs*
  (bijvoorbeeld 5 minuten), na controle van eigenaarschap.
- **Op de server opnieuw controleren**, want de app is niet te vertrouwen:
  - bestandstype op inhoud (magic bytes)
  - maximale grootte
  - bestandsnaam alleen als metadata, nooit als opslagpad (voorkomt path traversal)
- Optioneel een virusscan bij het uploaden.
- Bij account verwijderen ook de objecten verwijderen; dat is aantoonbaar te testen.
- Bewaartermijn en back-ups van de server vastleggen in de privacyverklaring.

## 4. Betaalde Plus-functionaliteit

> **Wens van de gebruiker (23-10-2026):** geld verdienen met de app. Afspraak: versie 1.0 gratis
> publiceren, daarna "Bonvrij Plus" als **eenmalige aankoop** in een update (1.1). Ideeën zonder
> server: app-vergrendeling (Face ID/vingerafdruk), PDF-overzicht voor de verzekering, meerdere
> herinneringen per product, widget. Geen advertenties (botst met de privacybelofte). Bij
> verdienen: adres openbaar in Google Play, handelaarsstatus (EU), betaalprofiel, belasting en
> mogelijk KvK; dat zelf laten nagaan.

- **Digitale functies** (zoals cloudback-up) moeten via de in-app-aankopen van Apple en Google
  worden verkocht (App Store-richtlijn 3.1.1, Google Play Billing). Een eigen betaallink voor
  digitale functies wordt in de app geweigerd.
- **Implementatie:**
  - via het Flutter-pakket `in_app_purchase` of een dienst als RevenueCat
  - aankopen altijd op de server controleren (*receipt validation*), niet alleen in de app
- **Gratis blijft alles wat lokaal kan:** producten, documenten, herkenning, herinneringen,
  export. Plus kan bijvoorbeeld bevatten: cloudback-up, synchronisatie, delen met huisgenoten.
- Zakelijk: een betaalprofiel in App Store Connect en Play Console, met belastinggegevens.
  Mogelijk is een KvK-inschrijving nodig.

## 5. AI-ondersteunde herkenning

Het projectplan sluit externe OCR uit zonder expliciete architectuurwijziging. Als dit ooit
wordt overwogen:

- **Alleen opt-in, per document**, met een duidelijke uitleg vóór het versturen.
  De lokale herkenning blijft de standaard en de terugvaloptie.
- **Minimaal versturen:** liever de herkende tekst dan de foto. Waar mogelijk eerst
  persoonsgegevens weghalen: naam, adres, kaartnummers, klantnummers.
- **Aanbieder:**
  - verwerking in de EU
  - verwerkersovereenkomst
  - contractueel geen training op gebruikersgegevens
  - geen opslag na verwerking
- **De gebruiker controleert altijd.** Het resultaat gaat door hetzelfde controleformulier,
  met dezelfde markering van onzekere velden.
- **Technisch:** een extra implementatie achter de bestaande interfaces (`TextRecognizer` of een
  nieuwe `ReceiptInterpreter`). De rest van de app hoeft niet te veranderen.
- **Kosten:** betaalde API's per aanroep. Alleen binnen Plus aanbieden, met een limiet.
- Vooraf een DPIA (gegevensbeschermingseffectbeoordeling) overwegen.

## Volgorde (advies)

1. Publicatie van de lokale app (zie [publicatie-checklist.md](publicatie-checklist.md)).
2. Back-up naar de eigen cloud van de gebruiker (geen server nodig).
3. Accounts en synchronisatie, met gegevensisolatie en tests.
4. Plus via in-app-aankopen.
5. Eventueel AI-herkenning, opt-in.
