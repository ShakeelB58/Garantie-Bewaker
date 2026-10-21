# Website bonvrij.nl

Online op https://bonvrij.nl (DNS bij TransIP: vier A-records naar GitHub Pages en `www` als CNAME naar `shakeelb58.github.io.`).

Statische website: startpagina en privacyverklaring. Wordt automatisch gepubliceerd via
GitHub Pages (`.github/workflows/website.yml`) bij elke wijziging op `main`.

- De privacyverklaring wordt gemaakt uit `docs/privacyverklaring.md`:
  `python3 scripts/build_privacy.py` (vereist het Python-pakket `markdown`).
- Lettertype Poppins: SIL Open Font License, zie `assets/OFL.txt`.
