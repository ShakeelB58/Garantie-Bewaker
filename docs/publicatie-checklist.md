# Publicatiechecklist: App Store en Google Play

Doel: Bonvrij eerst aan een paar testers geven, en daarna publiceren.
Regels van Apple en Google veranderen geregeld. **Controleer elk punt opnieuw vlak voor het
indienen**; de bedragen en termijnen hieronder gelden per oktober 2026.

Legenda: ⬜ te doen · ✅ klaar · ❓ beslissing nodig

## 1. Beslissingen vooraf

| | Punt | Advies |
|---|------|--------|
| ❓ | **Eigen app-ID (bundel-ID).** Nu `nl.garantiebewaker.garantiebewaker`, tijdelijk en niet van jou. Na publicatie is dit **nooit meer te wijzigen**. | Kies een omgekeerd domein dat je bezit, bijv. `nl.bonvrij.app` als je bonvrij.nl bezit. Heb je geen domein, dan kan iets unieks met je naam. |
| ❓ | **iPad.** De app staat nu ingesteld voor iPhone én iPad (`TARGETED_DEVICE_FAMILY = "1,2"`). Dan vraagt Apple ook iPad-schermafbeeldingen en wordt de app op iPad beoordeeld. | Eerst alleen iPhone (`"1"`). iPad kan later. |
| ❓ | **Back-ups van het besturingssysteem.** iCloud-back-up (iOS) en Google-back-up (Android) nemen de database en documenten van de app standaard mee, versleuteld. Voordeel: gegevens komen terug op een nieuwe telefoon. Nadeel: "alles blijft op je telefoon" is dan niet helemaal waar. | Aan laten (de app heeft geen eigen back-up) en dit eerlijk vermelden in de privacyverklaring en in de app. |
| ✅ | **Naam:** "Bonvrij" (gekozen op 21-10-2026, beslissing B14). Vlak voor het indienen nog controleren in beide stores en in het merkregister (BOIP). | Store-ondertitel, bijv. "Al je bonnen en garanties veilig op je telefoon". |

## 2. Accounts en kosten

| | Punt |
|---|------|
| ⬜ | **Apple Developer Program:** $99 per jaar (in euro iets meer). Aanmelden via developer.apple.com met je Apple ID. Als particulier staat je eigen naam als verkoper in de App Store. |
| ⬜ | **Google Play Console:** eenmalig $25, met identiteitscontrole. |
| ⬜ | **Google Play, persoonlijk account:** vóór publicatie verplicht een **gesloten test met minimaal 12 testers die 14 dagen achter elkaar meedoen**. Plan dit in met de "paar mensen" die de app gaan gebruiken. |
| ⬜ | Een e-mailadres voor ondersteuning (verplicht in beide stores). Gebruik bij voorkeur een apart adres. |

## 3. Technisch (in de code; dit kan ik voorbereiden)

| | Punt |
|---|------|
| ⬜ | Bundel-ID en applicationId aanpassen: iOS `PRODUCT_BUNDLE_IDENTIFIER`; Android `namespace`, `applicationId` en de map van `MainActivity.kt`. |
| ⬜ | Versienummer in `pubspec.yaml` (`version: 1.0.0+1`). Elke upload krijgt een hoger buildnummer (`+2`, `+3`, …). |
| ✅ | App-icoon (iOS alle maten, Android klassiek en adaptief met monochroom). |
| ✅ | Meldingsicoon voor Android (wit schild op transparant). |
| ✅ | Opstartscherm in de huisstijl (iOS en Android, ook Android 12+). |
| ⬜ | **Android-ondertekening:** een eigen upload-sleutel (keystore) en een `key.properties` die **nooit in Git** komt; Play App Signing aanzetten. Bewaar de keystore en het wachtwoord veilig, buiten de repository. |
| ⬜ | **Android target-SDK:** vanaf 31 augustus 2026 moeten nieuwe apps en updates API 36 (Android 16) als doel hebben. Controleren met `grep targetSdk` in de build-uitvoer; de app volgt nu de standaard van Flutter. |
| ⬜ | **iOS:** `ITSAppUsesNonExemptEncryption = NO` in `Info.plist`. De app gebruikt geen eigen versleuteling, dus er is geen exportdocumentatie nodig. |
| ⬜ | **iOS-privacymanifest** (`PrivacyInfo.xcprivacy`): vermelden welke "required reason API's" de app gebruikt. Bijvoorbeeld bestandstijdstempels (opruimen van oude bestanden) en UserDefaults (via plug-ins). |
| ⬜ | Releasebuilds maken en testen: `flutter build appbundle` (Android) en `flutter build ipa` (iOS). |
| ✅ | Toestemmingsteksten in het Nederlands (camera, foto's), en meldingen pas vragen als het nodig is. |
| ⬜ | iOS: controleren of Apple `NSMicrophoneUsageDescription` eist vanwege de camera-plug-in (de app neemt geen geluid op). Zo ja, een eerlijke tekst toevoegen. |
| ✅ | Geen netwerkcode, geen analytics, geen advertenties, geen trackers. |
| ✅ | Automatische tests en controle via GitHub Actions. |

## 4. Privacy en juridisch

| | Punt |
|---|------|
| ⬜ | **Privacyverklaring** op een openbare webpagina (verplicht in beide stores). Bijvoorbeeld via GitHub Pages. Inhoud: welke gegevens (alleen lokaal), geen delen met derden, OS-back-ups, meldingen, export, verwijderen, contact. |
| ⬜ | **App Store-privacylabel:** waarschijnlijk "Geen gegevens verzameld", omdat er niets naar de ontwikkelaar of derden gaat. |
| ⬜ | **Google Play-gegevensveiligheid:** "Geen gegevens verzameld of gedeeld", plus een vermelding dat gebruikers alles zelf kunnen verwijderen. |
| ⬜ | Leeftijdsclassificatie invullen in beide stores; zou "voor iedereen" moeten zijn. |
| ✅ | In de app staat dat Bonvrij geen juridisch advies geeft en geen garantietermijnen berekent. |

## 5. Winkelpagina

| | Punt |
|---|------|
| ⬜ | Korte en lange beschrijving in het Nederlands (en eventueel Engels). |
| ⬜ | **Schermafbeeldingen iPhone:** de grootste maat die App Store Connect vraagt (6,9 inch, 1320×2868). Kleinere maten worden daaruit gemaakt. Gebruik alleen fictieve gegevens, zoals de testbestanden. |
| ⬜ | **Google Play:** minimaal 2 telefoonschermafbeeldingen, een icoon van 512×512 en een feature-afbeelding van 1024×500. |
| ⬜ | Categorie, bijv. Productiviteit (of Financiën). |
| ⬜ | Trefwoorden (iOS, max. 100 tekens): garantie, kassabon, factuur, aankoopbewijs, … |

## 6. Testen vóór publicatie

| | Punt |
|---|------|
| ⬜ | **TestFlight (iOS):** interne testers direct. Externe testers (tot 10.000) na een korte beoordeling door Apple. |
| ⬜ | **Google Play:** eerst intern testen, dan de verplichte gesloten test (12 testers, 14 dagen). |
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
