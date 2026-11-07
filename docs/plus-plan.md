# Plan: Bonvrij Plus

*Opgesteld: 7 november 2026. Alleen een plan: er is nog niets van gebouwd of uitgebracht.*

## Uitgangspunten

- **Je gegevens blijven van jou.** Wat nodig is om je eigen bonnen te bewaren en terug te krijgen,
  blijft gratis. Plus verkoopt gemak, geen toegang tot je eigen gegevens.
- **Geen eigen server, geen account, geen reclame.** Ook Plus werkt op de telefoon en met de
  eigen iCloud of Google Drive van de gebruiker.
- **Eén keer betalen**, geen abonnement. Voorstel: **€ 4,99** (later te toetsen, bijv. € 3,99 of € 6,99).
  Eén aankoop geldt voor alle toestellen met hetzelfde Apple- of Google-account ("Aankopen herstellen").

## Gratis en Plus

| Functie | Gratis | Plus |
|---|---|---|
| Producten, bonnen, facturen, garantiebewijzen | ✅ onbeperkt | ✅ |
| Herkenning van bonnen en facturen (NL en EN) | ✅ | ✅ |
| Model- en serienummer of IMEI | ✅ | ✅ |
| Herinnering per product | ✅ één | ✅ meerdere |
| Export en terugzetten met de hand | ✅ | ✅ |
| Maandelijkse herinnering om een reservekopie te maken | ✅ | ✅ |
| **Automatische reservekopie** naar eigen iCloud Drive / Google Drive | – | ✅ |
| **Overzicht voor de verzekering** (PDF) | – | ✅ |
| **Typeplaatje scannen** (model- en serienummer met de camera) | – | ✅ |
| **App-vergrendeling** (Face ID, Touch ID, vingerafdruk) | – | ✅ |
| **Meerdere herinneringen per product** | – | ✅ |

Twijfelgeval: typeplaatje scannen kan ook gratis blijven om de app aantrekkelijker te maken. Te
beslissen vóór het bouwen.

## De Plus-functies

### 1. Automatische reservekopie ⭐

- **Wat de gebruiker doet:** één keer in Instellingen een map kiezen, bijv. in iCloud Drive of
  Google Drive (via het systeemvenster "Bestanden"). Daarna niets meer.
- **Wat de app doet:** zodra de app wordt geopend en de laatste reservekopie ouder is dan 7 dagen,
  zet hij een nieuwe export in die map. De laatste 3 blijven bewaard; oudere worden opgeruimd.
- **Waarom bij het openen en niet 's nachts:** iOS en Android garanderen geen achtergrondtaken
  op een vast tijdstip. Bij het openen is betrouwbaar en eerlijk. Android kan daarnaast een
  achtergrondtaak proberen (WorkManager).
- **Techniek:**
  - iOS: map kiezen met de documentkiezer en de toegang bewaren
    (*security-scoped bookmark*).
  - Android: map kiezen met het Storage Access Framework
    (*persistable URI permission*).
  - Hiervoor is geen inlog bij Google en geen eigen server nodig.
- **Privacy:** de reservekopie gaat naar de eigen cloud van de gebruiker, onder diens account.
  De privacyverklaring krijgt een alinea erbij; de privacylabels blijven "geen gegevens
  verzameld", omdat de gegevens niet naar ons gaan. Dit laten controleren vóór uitbrengen.
- **Terugzetten:** gewoon gratis, met "Ik heb een reservekopie" (zit al op de branch
  `herstellen`).

### 2. Overzicht voor de verzekering ⭐

- Eén PDF met alle producten, of een selectie:
  - foto van de bon
  - merk, model- en serienummer
  - aankoopdatum, winkel en prijs
  - totale waarde
- Handig na inbraak, brand of waterschade, en om de inboedelwaarde te schatten.
- De PDF wordt op de telefoon gemaakt (pakket `pdf`), en de gebruiker deelt hem zelf.
- Tekst onderaan: "Opgesteld door de gebruiker. Bonvrij controleert de gegevens niet."

### 3. Typeplaatje scannen

- Naast **Modelnummer** en **Serienummer** komt een cameraknopje.
- Foto van de sticker of het typeplaatje → herkenning op de telefoon (dezelfde Apple Vision /
  ML Kit als bij bonnen) → de app zoekt labels als "Model", "Type", "S/N", "Serial", "IMEI".
- De gebruiker kiest of controleert de gevonden nummers, zoals bij de bonnen.
- Beperking: kleine, glimmende of gegraveerde plaatjes worden slechter gelezen. Typen blijft altijd
  mogelijk.

### 4. App-vergrendeling

- De app opent pas na Face ID, Touch ID, vingerafdruk of de code van de telefoon (pakket
  `local_auth`).
- Daarbij vergrendelt de app weer na bijv. 1 minuut op de achtergrond.

### 5. Meerdere herinneringen per product

- Bijv. 3 maanden, 1 maand én 1 week vóór de garantie-einddatum, en een herinnering voor de
  retourtermijn.
- Hiervoor is een kleine aanpassing van de database nodig (meerdere herinneringen per product).

## Betalen in de app

- **Via Apple en Google:** digitale functies moeten via de in-app-aankopen van Apple en Google
  verkocht worden. Een eigen betaallink is niet toegestaan.
- **Kosten:** beide houden een percentage in. Voor kleine ontwikkelaars is dat 15% (Apple Small
  Business Program, aanmelden nodig; Google 15% over de eerste omzet per jaar). Vóór de start
  de actuele voorwaarden nakijken.
- **Techniek:** het Flutter-pakket `in_app_purchase` of de dienst **RevenueCat**.
  - RevenueCat regelt het controleren van aankopen en het terugzetten op een nieuwe telefoon.
  - Het is gratis tot een bepaalde omzet; de voorwaarden nakijken.
  - Let op: RevenueCat is een externe dienst, die het aankoopbewijs en een anonieme
    gebruikers-id verwerkt. Dat moet in de privacyverklaring en mogelijk in de privacylabels
    ("Purchases").
- **Zonder externe dienst:** met alleen `in_app_purchase` kan de app de aankoop zelf bij Apple of
  Google opvragen. Dat is eenvoudiger voor de privacy, maar iets minder goed beveiligd tegen
  misbruik. Voor een eenmalige aankoop van een paar euro is dat aanvaardbaar.
  **Voorkeur: zonder externe dienst.**
- **In de app:**
  - Instellingen → "Bonvrij Plus" met uitleg, prijs, kopen en aankopen herstellen.
  - Plus-functies tonen een slotje met een korte uitleg, zonder opdringerige pop-ups.

## Wat jij zakelijk moet regelen (vóór het uitbrengen)

1. **Apple:** de **Paid Apps Agreement** tekenen in App Store Connect (Business), met
   bankrekening en belastingformulieren. Aanmelden voor het **Small Business Program**.
2. **Google:** een **betaalprofiel** (Merchant) aanmaken in de Play Console, met bank- en
   belastinggegevens.
3. **Handelaarsstatus (EU, DSA):** wie verdient, is waarschijnlijk een **handelaar**. Dan worden
   naam, adres, telefoonnummer en e-mail openbaar getoond in beide winkels. Overweeg een
   zakelijk adres of postadres en een apart telefoonnummer.
4. **KvK en belasting:** laten nagaan of een inschrijving bij de KvK nodig is, en hoe het zit met
   btw (Apple en Google dragen in de EU meestal de btw af) en inkomstenbelasting. Vraag dit na bij
   de KvK of een boekhouder. *Dit plan is geen belasting- of juridisch advies.*
5. **Teksten:** de winkelteksten, de privacyverklaring en de algemene voorwaarden aanpassen
   (wat Plus is, terugbetaling volgens het beleid van Apple en Google).

## Volgorde (advies)

1. De gratis terugzetfunctie uitbrengen (klaar op branch `herstellen`, versie 1.3.0).
2. Ondertussen de zakelijke kant regelen (punten 1 tot en met 4 hierboven).
3. **Plus 1.0:**
   - automatische reservekopie
   - overzicht voor de verzekering
   - de aankoop zelf
4. Daarna, in updates:
   - typeplaatje scannen
   - app-vergrendeling
   - meerdere herinneringen per product

## Open beslissingen

- Prijs: € 3,99 / € 4,99 / € 6,99?
- Typeplaatje scannen: gratis of Plus?
- Aankoop controleren met of zonder RevenueCat?
- Moeten bestaande gebruikers iets gratis krijgen, bijv. de eerste maand automatische
  reservekopie? (Eenvoudiger: nee.)
