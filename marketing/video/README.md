# Promotievideo's

Geanimeerde video's (1080×1920, 30 fps) met de echte schermen van de app en fictieve
voorbeeldgegevens. Geen muziek: kies op TikTok/Instagram zelf een geluid.

Opnieuw maken (de afbeeldingen in `a/` komen uit `mobile/screenshots/raw` en `docs/winkel`):

```
node render.js "$PWD/blackfriday.html" "$PWD"
ffmpeg -f concat -safe 0 -i list.txt -c copy joined.mp4
```
