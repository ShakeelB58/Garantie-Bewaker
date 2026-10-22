# Invulgids Google Play Console

Wat je waar invult voor Bonvrij. Volg de volgorde hieronder. De Play Console verandert soms van
indeling of naam; staat iets er net anders, kies dan het antwoord dat hier het dichtst bij komt
of vraag het na.

Teksten voor de winkelpagina staan in [winkelteksten.md](winkelteksten.md), afbeeldingen in
[winkel/](winkel/README.md).

## 1. App maken

Play Console → **Alle apps** → **App maken**.

| Veld | Invullen |
|------|----------|
| App-naam | `Bonvrij – bonnen & garanties` |
| Standaardtaal | Nederlands – nl-NL |
| App of game | **App** |
| Gratis of betaald | **Gratis** (later niet meer te wijzigen naar betaald) |
| Verklaringen | Beide vinkjes: programmabeleid voor ontwikkelaars en exportwetten van de VS |

## 2. App-content (Beleid → App-content)

### Privacybeleid
`https://bonvrij.nl/privacy/`

### App-toegang
**Alle functionaliteit is beschikbaar zonder speciale toegang.** Er is geen account of inlog.

### Advertenties
**Nee**, mijn app bevat geen advertenties.

### Contentclassificatie
- E-mailadres: `bonvrij.app@gmail.com`
- Categorie: **Alle andere app-typen** (geen game, geen sociale app). Heet de keuze anders, kies
  de algemene categorie voor hulpprogramma's of productiviteit.
- Op alle vragen over geweld, angst, seks, grof taalgebruik, drugs, alcohol en gokken: **Nee**.
- Kunnen gebruikers met elkaar communiceren of inhoud uitwisselen? **Nee**
- Deelt de app de locatie van de gebruiker? **Nee**
- Kunnen gebruikers digitale producten kopen? **Nee**
- Is de app een webbrowser of zoekmachine? **Nee**

Verwacht resultaat: PEGI 3 / "Iedereen".

### Doelgroep en content
- Leeftijdsgroepen: **18 en ouder**. (Jonger kiezen brengt extra regels voor kinderapps met zich
  mee; Bonvrij is bedoeld voor volwassenen met aankopen.)
- Kan de app kinderen onbedoeld aanspreken? **Nee**

### Nieuws-apps
**Nee**, mijn app is geen nieuws-app.

### Overheids-apps, financiële functies, gezondheid
- Overheids-app: **Nee**
- Financiële functies: **Mijn app biedt geen financiële functies.** (Bonvrij bewaart bonnen,
  maar doet geen betalingen, leningen, beleggingen of bankzaken.)
- Gezondheidsfuncties: **Geen**

### Advertentie-ID
Gebruikt je app een advertentie-ID? **Nee**

Controle vooraf op je Mac (na `flutter build appbundle`, in de map `mobile`):

```
find build/app/intermediates -name AndroidManifest.xml -path "*release*" -exec grep -o 'android.permission.[A-Z_]*\|permission.AD_ID' {} \; | sort -u
```

Staat `AD_ID` in de lijst, meld het dan eerst (dan voegt een onderdeel het toe en passen we dat
aan). Staat `READ_MEDIA_IMAGES` erin, dan vraagt Google ook een verklaring over foto-toegang.

### Gegevensveiligheid (Data safety)
Zie beslissing B17: Google ML Kit (tekstherkenning op Android) stuurt technische gegevens naar
Google. Dat telt als "verzamelen" door de app.

**Overzicht**
- Verzamelt of deelt je app een van de vereiste typen gebruikersgegevens? **Ja**
- Worden alle verzamelde gegevens versleuteld tijdens de overdracht? **Ja** (ML Kit gebruikt HTTPS)
- Accounts: **Mijn app staat niet toe dat gebruikers een account maken** (of: geen account).
- Kunnen gebruikers verzoeken dat hun gegevens worden verwijderd? **Nee** — wij ontvangen deze
  gegevens niet en kunnen ze dus ook niet verwijderen. (Alles in de app zelf kun je wel wissen,
  maar dat zijn geen "verzamelde" gegevens.)

**Gegevenstypen** (alleen deze twee aanvinken):

| Categorie | Type |
|-----------|------|
| App-informatie en -prestaties | **Diagnostische gegevens** |
| Apparaat- of andere ID's | **Apparaat- of andere ID's** |

**Per type** (voor allebei hetzelfde):
- Verzameld: **ja**. Gedeeld: **nee** (Google verwerkt het als leverancier van ML Kit).
- Tijdelijk verwerkt (ephemeral)? **Nee**
- Vereist of optioneel? **Vereist** (de gebruiker kan het in de app niet uitzetten)
- Doel: **Analyse** (Google gebruikt het voor diagnose en gebruiksstatistieken van ML Kit)

Niet aanvinken: foto's, bestanden, financiële gegevens, aankoopgeschiedenis, locatie,
contacten. Die blijven op het toestel en worden niet verzameld.

## 3. Winkelvermelding (Groeien → Winkelvermelding → Hoofdvermelding)

| Veld | Invullen |
|------|----------|
| App-naam | `Bonvrij – bonnen & garanties` |
| Korte beschrijving | uit [winkelteksten.md](winkelteksten.md) |
| Volledige beschrijving | uit [winkelteksten.md](winkelteksten.md) (de App Store-tekst) |
| App-icoon | `docs/winkel/google-play/icoon-512.png` |
| Feature-afbeelding | `docs/winkel/google-play/feature-graphic-1024x500.png` |
| Telefoonschermafbeeldingen | `docs/winkel/android/1-home.png` t/m `6-privacy.png`, in die volgorde |
| Tablet-schermafbeeldingen | Overslaan (niet verplicht) |

Winkelinstellingen: categorie **Productiviteit**, e-mail `bonvrij.app@gmail.com`, website
`https://bonvrij.nl`. Telefoonnummer niet openbaar invullen.

## 4. Interne test (eerste upload)

Testen → **Interne tests** → **Nieuwe release maken**.

1. **App-ondertekening door Google Play:** accepteren ("Google laat je sleutel beheren").
   Google bewaart de echte ondertekeningssleutel; jij gebruikt alleen je upload-sleutel.
2. Upload `mobile/build/app/outputs/bundle/release/app-release.aab`.
3. Releasenaam: `1.0.0 (1)`. Release-opmerkingen (nl-NL): `Eerste testversie.`
4. Tabblad **Testers**: maak een lijst met je eigen Gmail-adres (en eventueel een paar
   bekenden). Kopieer de **link voor deelname** en open die op je Samsung.

Elke nieuwe upload heeft een hoger buildnummer nodig: in `mobile/pubspec.yaml` wordt
`version: 1.0.0+1` dan `1.0.0+2`, enzovoort.

## 5. Gesloten test (verplicht voor persoonlijke accounts)

- Minimaal **12 testers** die **14 dagen achter elkaar** meedoen.
- Testen → **Gesloten tests** → track maken → testers toevoegen via een e-maillijst (Gmail-adressen
  van mensen met een Android-telefoon).
- Testers openen de link voor deelname, kiezen **Tester worden** en installeren de app via de
  Play Store. Ze moeten hem geïnstalleerd laten tot de 14 dagen voorbij zijn.
- Daarna vraag je in het Dashboard **productietoegang** aan. Google stelt dan vragen over de
  test, bijvoorbeeld hoe je feedback hebt verzameld. Eerlijk antwoorden.

## Bronnen (geraadpleegd 22-10-2026)

- [Play Console Help: app-content](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)
- [Play Console Help: gegevensveiligheid](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [ML Kit: gegevens die Android-SDK's verzamelen](https://developers.google.com/ml-kit/android-data-disclosure)
- [Play Console Help: testvereisten persoonlijke accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en-GB)
