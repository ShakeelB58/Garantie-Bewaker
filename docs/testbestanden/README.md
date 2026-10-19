# Testbestanden

**Fictieve, geanonimiseerde** documenten om de app te testen. Ze bevatten geen echte winkels,
personen of bedragen. Zet hier nooit echte aankoopbewijzen neer (zie `.gitignore` en de masterprompt §12).

| Bestand | Inhoud | Gebruikt voor |
|---|---|---|
| `testfactuur-elektronica.pdf` | Digitale PDF-factuur met tekstlaag: wasmachine € 1.299,00, bezorging € 49,95, totaal € 1.348,95, datum 12-10-2026 | Importeren, delen, PDF-tekstextractie (fase 4) |
| `testbon-supermarkt.jpg` | Afbeelding van een kassabon: waterkoker € 29,99, theedoek € 3,49, totaal € 33,48, datum 15-10-2026 | Afbeelding importeren/delen, OCR (fase 4) |

## Op een toestel zetten

- **iPhone-simulator:** sleep het bestand in het Simulator-venster. Het komt in de Bestanden-app terecht.
- **Android via USB:** `~/Android/Sdk/platform-tools/adb push docs/testbestanden/testfactuur-elektronica.pdf /sdcard/Download/`
- **Via e-mail:** mail het bestand naar jezelf en open de bijlage op je telefoon. Zo test je meteen "Delen" vanuit de mail-app.
