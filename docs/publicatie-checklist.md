# Publicatiechecklist: App Store en Google Play

Doel: Bonvrij eerst aan een paar testers geven, en daarna publiceren.
Regels van Apple en Google veranderen geregeld. **Controleer elk punt opnieuw vlak voor het
indienen**; de bedragen en termijnen hieronder gelden per oktober 2026.

Legenda: ⬜ te doen · ⏳ deels klaar · ✅ klaar · ❓ beslissing nodig

## 1. Beslissingen vooraf

| | Punt | Advies |
|---|------|--------|
| ✅ | **App-ID:** `nl.bonvrij.app` (B16). Domein **bonvrij.nl** is geregistreerd (TransIP, 21-10-2026). | |
| ⬜ | Later: e-mail doorsturen van support@bonvrij.nl naar bonvrij.app@gmail.com (TransIP-pakket "Forwarding", ca. € 6 per jaar). Tot die tijd wordt bonvrij.app@gmail.com gebruikt. | |
| ✅ | **Alleen iPhone** (B16). | |
| ✅ | **Back-ups van iCloud/Google blijven aan**, vermeld in de privacyverklaring en de app (B16). | |
| ✅ | **Naam:** "Bonvrij" (gekozen op 21-10-2026, beslissing B14). Vlak voor het indienen nog controleren in beide stores en in het merkregister (BOIP). | Store-ondertitel, bijv. "Al je bonnen en garanties veilig op je telefoon". |

## 2. Accounts en kosten

| | Punt |
|---|------|
| ⬜ | **Apple Developer Program:** $99 per jaar (in euro iets meer). Aanmelden via developer.apple.com met je Apple ID. Als particulier staat je eigen naam als verkoper in de App Store. |
| ✅ | **Google Play Console:** account aangemaakt en identiteit goedgekeurd (23-10-2026, persoonlijk, bonvrij.app@gmail.com). |
| ⬜ | **Google Play, persoonlijk account:** vóór publicatie verplicht een **gesloten test met minimaal 12 testers die 14 dagen achter elkaar meedoen**. Plan dit in met de "paar mensen" die de app gaan gebruiken. |
| ✅ | E-mailadres voor ondersteuning: bonvrij.app@gmail.com (ook in de app bij "Over Bonvrij" en in de privacyverklaring). |

## 3. Technisch (in de code; dit kan ik voorbereiden)

| | Punt |
|---|------|
| ✅ | Bundel-ID en applicationId aangepast naar `nl.bonvrij.app`. |
| ✅ | Versienummer `1.0.0+1`. Elke upload krijgt een hoger buildnummer (`+2`, `+3`, …). |
| ✅ | App-icoon (iOS alle maten, Android klassiek en adaptief met monochroom). |
| ✅ | Meldingsicoon voor Android (wit schild op transparant). |
| ✅ | Opstartscherm in de huisstijl (iOS en Android, ook Android 12+). |
| ✅ | **Android-ondertekening:** upload-sleutel aangemaakt (22-10-2026, buiten de projectmap) en `android/key.properties` ingevuld (staat nooit in Git). De releasebuild is ondertekend met "CN=Shakeel Bechan". |
| ✅ | **Android target-SDK:** 36 (gecontroleerd in de releasebuild, 22-10-2026). Google eist vanaf 31 augustus 2026 API 36. |
| ✅ | **iOS:** `ITSAppUsesNonExemptEncryption = false` in `Info.plist`. |
| ✅ | **iOS-privacymanifest** (`ios/Runner/PrivacyInfo.xcprivacy`, getest in de simulator 22-10-2026): vermelden welke "required reason API's" de app gebruikt. Bijvoorbeeld bestandstijdstempels (opruimen van oude bestanden) en UserDefaults (via plug-ins). |
| ⏳ | Releasebuilds: Android ✅ getest met `flutter run --release` op de Samsung (22-10-2026): herkenning, meldingen, geen voorbeeldknop. Daarvoor waren regels nodig voor R8 en resource shrinking (`proguard-rules.pro`, `res/raw/keep.xml`). iOS: `flutter build ipa` volgt na het Apple-account. |
| ✅ | Toestemmingsteksten in het Nederlands (camera, foto's), en meldingen pas vragen als het nodig is. |
| ✅ | iOS: `NSMicrophoneUsageDescription` toegevoegd met een eerlijke tekst (de camera-plug-in verwijst naar de microfoon; de app neemt geen geluid op). Voorkomt een afwijzing bij het uploaden. |
| ✅ | Geen eigen netwerkcode, geen advertenties, geen trackers. Alleen Google ML Kit (Android) stuurt technische gebruiksgegevens naar Google (B17). |
| ✅ | Automatische tests en controle via GitHub Actions. |

## 4. Privacy en juridisch

| | Punt |
|---|------|
| ✅ | **Privacyverklaring** staat online op https://bonvrij.nl/privacy/ (bron `docs/privacyverklaring.md`), met de naam van de verantwoordelijke. |
| ⬜ | **App Store-privacylabel:** "Data Not Collected": op iOS gebruikt de app Apple Vision, er gaat niets naar de ontwikkelaar of derden. |
| ✅ | **Google Play-gegevensveiligheid** (ingevuld 23-10-2026): "verzameld" door Google ML Kit (diagnose en toestel-ID's, niet gedeeld, versleuteld); zie [play-console-invulgids.md](play-console-invulgids.md) en B17. |
| ⏳ | Leeftijdsclassificatie: Google Play ingevuld (23-10-2026); App Store nog doen. |
| ✅ | In de app staat dat Bonvrij geen juridisch advies geeft en geen garantietermijnen berekent. |

## 5. Winkelpagina

| | Punt |
|---|------|
| ✅ | Korte en lange beschrijving in het Nederlands: [winkelteksten.md](winkelteksten.md). |
| ✅ | **Schermafbeeldingen iPhone:** 6 stuks in 6,9 inch (1320×2868), met fictieve gegevens: `docs/winkel/ios/`. Kleinere maten maakt Apple daaruit. |
| ✅ | **Google Play:** 6 telefoonschermafbeeldingen (1080×1920), icoon 512×512 en feature-afbeelding 1024×500: `docs/winkel/android/` en `docs/winkel/google-play/`. |
| ⬜ | Categorie, bijv. Productiviteit (of Financiën). |
| ⬜ | Trefwoorden (iOS, max. 100 tekens): garantie, kassabon, factuur, aankoopbewijs, … |

## 6. Testen vóór publicatie

| | Punt |
|---|------|
| ⬜ | **TestFlight (iOS):** interne testers direct. Externe testers (tot 10.000) na een korte beoordeling door Apple. |
| ⏳ | **Google Play:** interne test actief (versie 1.0.0 (1), 23-10-2026); app-content en winkelpagina ingevuld. Volgende: gesloten test (12 testers, 14 dagen). |
| ⬜ | Op minimaal één echte iPhone testen: camera, meldingen, "Openen met" vanuit Mail. |
| ⬜ | Alle punten uit [acceptatietests.md](acceptatietests.md) opnieuw lopen met de releasebuild. |
| ⬜ | Een update testen over een bestaande installatie heen: gegevens moeten blijven staan (databasemigraties). |

## 7. Na publicatie

- Elke update: buildnummer verhogen, CI groen, acceptatietests op beide platformen.
- Reageer op beoordelingen en meldingen. Vraag gebruikers nooit om echte bonnen te mailen.
- Houd de regels van Apple en Google bij, zoals de jaarlijkse verhoging van de target-SDK van Google.

Bronnen (geraadpleegd oktober 2026):
[Google: target API-level](https://developer.android.com/google/play/requirements/target-sdk) ·
[Google: testvereisten persoonlijke accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en-GB) ·
[App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## Upload-sleutel voor Android aanmaken (eenmalig)

Voer dit uit op je Mac. Bewaar de sleutel en het wachtwoord **buiten** de projectmap, en maak
er een back-up van (bijv. in een wachtwoordmanager). Zonder deze sleutel kun je geen updates
meer uploaden.

```bash
mkdir -p ~/Sleutels
keytool -genkey -v -keystore ~/Sleutels/bonvrij-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Maak daarna het bestand `mobile/android/key.properties` met deze inhoud (eigen wachtwoord invullen):

```
storePassword=<jouw wachtwoord>
keyPassword=<jouw wachtwoord>
keyAlias=upload
storeFile=/Users/<jouw gebruikersnaam>/Sleutels/bonvrij-upload.jks
```

`key.properties` en `.jks`-bestanden staan in `.gitignore` en komen nooit in Git.
Daarna maak je de uploadversie met `flutter build appbundle`.
