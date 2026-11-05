# Teksten van de app (Nederlands en Engels)

Alle teksten die gebruikers zien, staan in `registry.py`, met per tekst de Nederlandse en de
Engelse versie. Daaruit worden de Dart-bestanden gemaakt:

```
python3 scripts/l10n/gen.py mobile/lib/l10n
```

Dat schrijft `mobile/lib/l10n/app_strings.dart`, `strings_nl.dart` en `strings_en.dart`.
Pas die drie bestanden niet met de hand aan.

In de code gebruik je een tekst zo: `S.current.save`. De taal wordt bij het starten gekozen
in `AppLocale.apply` (Nederlands als de telefoon op Nederlands staat, anders Engels).
