# Handmatige acceptatietests

Controlelijst uit het projectplan (hoofdstuk 12). Test met de fictieve bestanden in
[`testbestanden/`](testbestanden/README.md); gebruik geen echte bonnen in de repository.

Toestellen: **Samsung Galaxy S23 (Android 16)** en **iPhone 17-simulator (iOS 27)**.
Een echte iPhone is nog niet getest (ondertekening met een gratis Apple-account lukte niet).

Legenda: ✅ getest en goed · ⚠️ deels getest · ⬜ nog te testen

| # | Test | Android | iOS | Opmerking |
|---|------|---------|-----|-----------|
| 1 | Een product handmatig toevoegen | ✅ | ✅ | Fase 2 |
| 2 | Een kassabon fotograferen | ✅ | ⚠️ | iOS-simulator heeft geen camera; foto's via Foto's getest |
| 3 | Herkende gegevens corrigeren | ✅ | ✅ | Fase 4: hint verdwijnt na aanpassen |
| 4 | Een PDF met tekst importeren | ✅ | ⚠️ | Op iOS niet gelukt de PDF in de simulator te zetten; zelfde code als Android |
| 5 | Een gescande PDF verwerken | ⬜ | ⬜ | Automatisch getest (nep-PDF); geen gescand testbestand op het toestel |
| 6 | Meerdere pagina's verwerken | ⬜ | ⬜ | Automatisch getest (max. 10 pagina's) |
| 7 | Een product met meerdere documenten bewaren | ⬜ | ⬜ | |
| 8 | Een herinnering instellen en wijzigen | ⚠️ | ⚠️ | Instellen en testmelding getest; melding op de dag zelf nog te bevestigen |
| 9 | Een product en documenten verwijderen | ✅ | ✅ | Fase 3a |
| 10 | De app offline gebruiken | ⬜ | ⬜ | Vliegtuigmodus; alleen het eerste ML Kit-model op Android vraagt internet |
| 11 | De app opnieuw starten en opgeslagen gegevens controleren | ⬜ | ⬜ | App volledig afsluiten en opnieuw openen |
| 12 | De app testen op iOS en Android | ✅ | ✅ | Simulator en Samsung |

Extra (fase 5):

| Test | Android | iOS |
|------|---------|-----|
| Gegevens exporteren en ZIP openen | ✅ | ✅ |
| Alle lokale gegevens verwijderen | ⬜ | ⬜ |
| Versienummer bij "Over GarantieBewaker" | ✅ | ✅ |

Extra (fase 6, toegankelijkheid):

| Test | Android | iOS |
|------|---------|-----|
| Grote tekst (systeeminstelling op maximaal): niets valt weg of overlapt | ✅ | ⚠️ |
| Schermlezer (TalkBack / VoiceOver): productkaart wordt als één knop voorgelezen | ✅ | ⬜ |
| Donkere modus van het systeem: app blijft leesbaar (app gebruikt altijd licht thema) | ⬜ | ⬜ |

Opmerking grote tekst iOS: de knop "Aankoop toevoegen" viel deels buiten beeld; opgelost in fase 6, opnieuw te controleren.
