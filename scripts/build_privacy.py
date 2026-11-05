"""Maakt website/privacy/index.html (Nederlands) uit docs/privacyverklaring.md
en website/en/privacy/index.html (Engels) uit docs/privacy-statement-en.md.

Gebruik (vanuit de hoofdmap van de repository):
    python3 scripts/build_privacy.py
"""
import re
from pathlib import Path

import markdown

root = Path(__file__).resolve().parents[1]
PAGES = [
    # bron, uitvoer, taal, prefix naar de hoofdmap, titel, beschrijving, teksten
    dict(src="privacyverklaring.md", out="privacy", lang="nl", up="../",
         title="Privacyverklaring – Bonvrij",
         desc="Hoe Bonvrij met je gegevens omgaat: je aankopen en bonnen blijven op je eigen telefoon.",
         updated="<p><em>Laatst", other=("en/privacy/", "English"),
         contact="Vragen? Mail naar"),
    dict(src="privacy-statement-en.md", out="en/privacy", lang="en", up="../../",
         title="Privacy statement – Bonvrij",
         desc="How Bonvrij handles your data: your purchases and receipts stay on your own phone.",
         updated="<p><em>Last", other=("privacy/", "Nederlands"),
         contact="Questions? Email"),
]

for page_def in PAGES:
    d = page_def
    source = (root / "docs" / d["src"]).read_text(encoding="utf-8")
    body = markdown.markdown(source, extensions=["extra"])
    # Interne notities (blokcitaten) horen niet op de openbare pagina.
    body = re.sub(r"<blockquote>.*?</blockquote>\s*", "", body, flags=re.S)
    # Datumregel en nog-in-te-vullen plekken opvallend tonen.
    body = body.replace(d["updated"], '<p class="updated"><em>' + d["updated"][7:], 1)
    body = re.sub(r"\[([^\]]+)\](?!\()", r'<span class="todo">[\1]</span>', body)
    up = d["up"]
    other_href, other_label = d["other"]
    page = f"""<!doctype html>
<html lang="{d['lang']}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{d['title']}</title>
  <meta name="description" content="{d['desc']}">
  <link rel="icon" href="{up}favicon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="{up}assets/style.css">
</head>
<body>
  <header class="site">
    <div class="wrap">
      <a class="brand" href="{up}"><img src="{up}assets/logo.svg" alt=""><b>Bon<span>vrij</span></b></a>
      <nav><a href="{up}">Home</a> <a href="{up}{other_href}" lang="{'en' if d['lang'] == 'nl' else 'nl'}">{other_label}</a></nav>
    </div>
  </header>
  <main class="wrap">
    <article class="doc">
{body}
    </article>
  </main>
  <footer class="site">
    <div class="wrap">
      <span>{d['contact']} <a href="mailto:bonvrij.app@gmail.com">bonvrij.app@gmail.com</a></span>
      <span><a href="{up}">Bonvrij</a></span>
    </div>
  </footer>
</body>
</html>
"""
    out = root / "website" / d["out"] / "index.html"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(page, encoding="utf-8")
    print(f"Geschreven: {out.relative_to(root)}")
