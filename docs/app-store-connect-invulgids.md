# Invulgids App Store Connect

Wat je waar invult om Bonvrij in de App Store te krijgen. Volg de volgorde hieronder. Apple
verandert soms namen of indeling; staat iets er net anders, kies dan het antwoord dat hier het
dichtst bij komt of vraag het na.

Teksten staan in [winkelteksten.md](winkelteksten.md), afbeeldingen in [winkel/ios/](winkel/README.md).

## 0. Voorwaarde

Je lidmaatschap van het Apple Developer Program is goedgekeurd (mail van Apple). Daarna kun je
inloggen op https://appstoreconnect.apple.com met je Apple ID.

## 1. Ondertekening in Xcode (eenmalig, op je Mac)

```
cd ~/Projects/garantiebewaker/mobile
open ios/Runner.xcworkspace
```

1. Klik links op **Runner** (blauw icoon) → onder TARGETS op **Runner** → tabblad
   **Signing & Capabilities**.
2. Vink **Automatically manage signing** aan.
3. **Team:** kies je eigen naam (Shakeel Bechan), *niet* "Personal Team".
4. **Bundle Identifier** moet `nl.bonvrij.app` zijn. Xcode registreert die dan automatisch bij Apple.
5. Rode foutmeldingen? Klik op **Try Again** of maak een schermafbeelding.

## 2. App aanmaken in App Store Connect

**Apps** → **+** → **Nieuwe app**.

| Veld | Invullen |
|------|----------|
| Platforms | **iOS** |
| Naam | `Bonvrij` (bezet? dan `Bonvrij – bonnen & garanties`) |
| Primaire taal | **Nederlands** |
| Bundel-ID | `nl.bonvrij.app` (verschijnt na stap 1 in de lijst) |
| SKU | `bonvrij-ios-001` (alleen voor jezelf, niet zichtbaar) |
| Gebruikerstoegang | **Volledige toegang** |

## 3. Bouwen en uploaden

```
cd ~/Projects/garantiebewaker
git pull
cd mobile
flutter build ipa
```

Lukt dat, dan staat er een regel met `build/ios/ipa`. Uploaden:

1. Installeer de gratis app **Transporter** van Apple uit de Mac App Store en log in met je Apple ID.
2. Sleep `mobile/build/ios/ipa/*.ipa` (in Finder: **Cmd + Shift + G** →
   `~/Projects/garantiebewaker/mobile/build/ios/ipa`) naar Transporter en klik **Lever af**.
3. Na 10–30 minuten staat de build in App Store Connect onder **TestFlight**.

Elke nieuwe upload heeft een hoger buildnummer nodig: in `mobile/pubspec.yaml` wordt
`version: 1.0.0+1` dan `1.0.0+2`, enzovoort.

Vraag over **exportcompliance / versleuteling**: die hoort niet te komen, omdat
`ITSAppUsesNonExemptEncryption = false` al in de app staat. Komt hij toch: **Geen versleuteling
buiten de uitzonderingen** (de app gebruikt alleen standaardversleuteling van iOS).

## 4. TestFlight (eerst zelf testen)

- **TestFlight** → **Interne tests** → groep maken (`Eigen toestellen`) → jezelf toevoegen.
- Installeer de app **TestFlight** op een iPhone, log in met dezelfde Apple ID en installeer Bonvrij.
- Test: camera, herkenning, meldingen, "Openen met" vanuit Mail. Heb je geen iPhone? Vraag
  iemand met een iPhone als **externe tester** (TestFlight → Externe tests; Apple doet eerst een
  korte beoordeling).

## 5. App-informatie (menu links: Algemeen → App-informatie)

| Veld | Invullen |
|------|----------|
| Ondertitel | `Bonnen en garanties bewaren` |
| Categorie | Primair **Productiviteit**, secundair **Financiën** |
| Contentrechten | **Nee**, de app bevat geen inhoud van derden waarvoor rechten nodig zijn |
| Leeftijdsclassificatie | zie hieronder |

**Leeftijdsclassificatie** (vragenlijst):
- Alle vragen over geweld, seks, grof taalgebruik, drugs, alcohol, tabak, gokken, horror:
  **Geen / Nee**.
- Medische of welzijnsonderwerpen: **Nee**.
- Ongecontroleerde webtoegang, chat of berichten tussen gebruikers, door gebruikers gemaakte
  content: **Nee**.
- In-app-bediening (bijv. ouderlijk toezicht) en mogelijkheden (bijv. AI-chatbot, locatie
  delen): **Nee / Geen**.
- Verwacht resultaat: **4+**.

## 6. Prijs en beschikbaarheid

- Prijs: **Gratis** (USD 0).
- Beschikbaarheid: **Nederland** en **België** (de app is alleen in het Nederlands). Later
  uitbreiden kan altijd.

## 7. App-privacy

- Privacybeleid-URL: `https://bonvrij.nl/privacy/`
- **Verzamel jij of je externe partners gegevens van deze app?** → **Nee, we verzamelen geen
  gegevens van deze app.** Resultaat: "Data Not Collected".
  Dit klopt voor iOS: de tekstherkenning is Apple Vision op het toestel; ML Kit (B17) zit
  alleen in de Android-versie.

## 8. Versie 1.0 (de productpagina)

| Veld | Invullen |
|------|----------|
| Schermafbeeldingen iPhone 6,9 inch | `docs/winkel/ios/1-home.png` t/m `6-privacy.png`, in die volgorde |
| Promotietekst | uit [winkelteksten.md](winkelteksten.md) |
| Beschrijving | uit [winkelteksten.md](winkelteksten.md) |
| Trefwoorden | uit [winkelteksten.md](winkelteksten.md) |
| Ondersteunings-URL | `https://bonvrij.nl` |
| Marketing-URL | leeg laten (of `https://bonvrij.nl`) |
| Copyright | `2026 Shakeel Bechan` |
| Build | kies de geüploade build `1.0.0 (1)` |
| Inloggen vereist | **Nee** (vinkje "Inloggen vereist" uit) |
| Contactgegevens voor beoordeling | je naam, telefoonnummer en `bonvrij.app@gmail.com` (niet openbaar) |
| Versie vrijgeven | **Deze versie handmatig vrijgeven** |

**Notities voor de beoordelaar** (Engels, zodat elke beoordelaar het begrijpt):

```
Bonvrij stores purchases, receipts, invoices and warranty dates locally on the device.
No account or login is required, and no data is sent to any server.

How to test:
1. Tap the + button, then scan a receipt with the in-app camera, or import a photo or PDF.
2. Text recognition runs on the device (Apple Vision) and suggests store, date, product and price.
   The user always reviews the fields before tapping "Opslaan" (Save).
3. On a product, set a warranty end date and turn on a reminder. Notifications are local.
4. Settings > "Gegevens exporteren" creates a ZIP export; "Alle lokale gegevens verwijderen" wipes all data.

The app is in Dutch. The microphone permission text exists only because the camera framework
references it; the app never records audio.
```

## 9. Handelaarsstatus EU (Digital Services Act)

Apple vraagt bij de eerste app of je een **handelaar** (trader) bent: **Zakelijk → Overeenkomsten
→ Compliance → Digital Services Act**.

- **Handelaar:** je naam, adres, telefoonnummer en e-mail komen **openbaar** op de productpagina
  in de EU, en je moet documenten uploaden.
- **Geen handelaar:** EU-gebruikers krijgen te zien dat consumentenrechten niet van toepassing zijn.

Bonvrij is nu een gratis app zonder inkomsten; dan ligt "geen handelaar" voor de hand. Ga je later
geld verdienen (Bonvrij Plus), dan ben je waarschijnlijk wél handelaar en pas je dit aan. Dit is
geen juridisch advies; twijfel je, kijk dan bij de KvK of de Europese Commissie.

## 10. Indienen

Bovenaan de versiepagina: **Toevoegen voor beoordeling** → **Indienen voor beoordeling**. Apple
beoordeelt meestal binnen 1–3 dagen. Na goedkeuring klik je zelf op **Deze versie vrijgeven**.

## Bronnen (geraadpleegd 23-10-2026)

- [Apple: aanmelden voor het Developer Program](https://developer.apple.com/programs/enroll/)
- [App Store Connect Help: handelaarsstatus EU](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements)
- [9to5Mac: nieuwe leeftijdsclassificaties](https://9to5mac.com/2025/07/24/apple-notifies-developers-of-new-app-store-age-rating-system/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
