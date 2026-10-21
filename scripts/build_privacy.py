"""Maakt website/privacy/index.html uit docs/privacyverklaring.md.

Gebruik (vanuit de hoofdmap van de repository):
    python3 scripts/build_privacy.py
"""
import re
from pathlib import Path

import markdown

root = Path(__file__).resolve().parents[1]
source = (root / "docs" / "privacyverklaring.md").read_text(encoding="utf-8")

body = markdown.markdown(source, extensions=["extra"])
# Interne notities (blokcitaten) horen niet op de openbare pagina.
body = re.sub(r"<blockquote>.*?</blockquote>\s*", "", body, flags=re.S)
# Datumregel en nog-in-te-vullen plekken opvallend tonen.
body = body.replace("<p><em>Laatst", '<p class="updated"><em>Laatst', 1)
body = re.sub(r"\[([^\]]+)\]", r'<span class="todo">[\1]</span>', body)

page = f"""<!doctype html>
<html lang="nl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Privacyverklaring – Bonvrij</title>
  <meta name="description" content="Hoe Bonvrij met je gegevens omgaat: alles blijft op je eigen telefoon.">
  <link rel="icon" href="../favicon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="../assets/style.css">
</head>
<body>
  <header class="site">
    <div class="wrap">
      <a class="brand" href="../"><img src="../assets/logo.svg" alt=""><b>Bon<span>vrij</span></b></a>
      <nav><a href="../">Home</a></nav>
    </div>
  </header>
  <main class="wrap">
    <article class="doc">
{body}
    </article>
  </main>
  <footer class="site">
    <div class="wrap">
      <span>Vragen? Mail naar <a href="mailto:bonvrij.app@gmail.com">bonvrij.app@gmail.com</a></span>
      <span><a href="../">Bonvrij</a></span>
    </div>
  </footer>
</body>
</html>
"""
out = root / "website" / "privacy" / "index.html"
out.write_text(page, encoding="utf-8")
print(f"Geschreven: {out.relative_to(root)}")
