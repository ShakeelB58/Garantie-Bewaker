# Winkelafbeeldingen

Alle afbeeldingen bevatten alleen **fictieve gegevens** (verzonnen merken, winkels en bedragen).

| Map | Waarvoor | Formaat |
|-----|----------|---------|
| `ios-6.3/` | App Store Connect, "iPhone with Dynamic Island (medium display)" (6,1/6,3 inch) — dit vraagt App Store Connect nu | 1206×2622 |
| `ios/` | App Store Connect, iPhone 6,9 inch (via Media Manager, optioneel) | 1320×2868 |
| `android/` | Google Play, telefoon | 1080×1920 |
| `google-play/feature-graphic-1024x500.png` | Google Play, feature-afbeelding | 1024×500 |
| `google-play/icoon-512.png` | Google Play, app-icoon | 512×512 |

Upload ze in de volgorde 1 t/m 6.

## Opnieuw maken (na een wijziging in de app)

1. Op GitHub: tabblad **Actions** → **Schermafbeeldingen** → **Run workflow**. Die maakt de ruwe
   schermen (`mobile/screenshots/raw/`) met de voorbeeldgegevens uit
   `mobile/lib/features/demo/demo_data.dart` en zet ze terug in de repository.
2. `git pull`, daarna `python3 scripts/store_images.py` (vereist Python met Playwright).
   Dat zet de koppen en het toestelkader eromheen en schrijft deze map opnieuw.

In de testversie van de app (gestart met `flutter run`) staat onder **Instellingen → Testversie**
de knop **Voorbeeldgegevens laden**, om dezelfde fictieve gegevens op je eigen toestel te zien.
In de versie voor de App Store en Google Play ontbreekt die knop.
