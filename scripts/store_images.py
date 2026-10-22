"""Maakt de winkelafbeeldingen voor de App Store en Google Play.

Invoer: de ruwe schermafbeeldingen uit mobile/screenshots/raw/ (gemaakt door
de workflow "Schermafbeeldingen"). Uitvoer: docs/winkel/.

Gebruik (vanuit de hoofdmap):  python3 scripts/store_images.py
Vereist: Python 3 met Playwright (Chromium).
"""

import pathlib
import shutil

from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "mobile" / "screenshots" / "raw"
FONTS = ROOT / "mobile" / "assets" / "fonts"
OUT = ROOT / "docs" / "winkel"
ICON = ROOT / "mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
LOGO = ROOT / "website" / "assets" / "logo.svg"

SCREENS = [
    ("1-home", "Al je aankopen op één plek",
     "Bonnen, facturen en garanties overzichtelijk bij elkaar."),
    ("2-scannen", "Scan je bon met de camera",
     "Of importeer een PDF-factuur, ook vanuit je mail."),
    ("3-controleren", "Winkel, datum en prijs worden herkend",
     "Op je eigen telefoon. Jij controleert alles."),
    ("4-product", "Garantie en documenten bij elkaar",
     "Alles over een aankoop in één overzicht."),
    ("5-herinneringen", "Een melding op de datum die jij kiest",
     "Mis geen retourtermijn of garantie meer."),
    ("6-privacy", "Geen account. Je bonnen blijven op je telefoon.",
     "Geen eigen server en geen reclame."),
]

# Canvas, telefoonbreedte, bovenmarge, status-balkhoogte (in px van de ruwe afbeelding).
DEVICES = {
    "ios": dict(w=1320, h=2868, phone=1040, top=640, title=92, sub=50,
                raw_w=1320, status=62 * 3, radius=150, bezel=26),
    "android": dict(w=1080, h=1920, phone=760, top=430, title=68, sub=37,
                    raw_w=1080, status=int(28 * 2.625), radius=70, bezel=18),
}

CSS_FONTS = f"""
@font-face {{ font-family: Poppins; font-weight: 400; src: url('{(FONTS / 'Poppins-Regular.ttf').as_uri()}'); }}
@font-face {{ font-family: Poppins; font-weight: 500; src: url('{(FONTS / 'Poppins-Medium.ttf').as_uri()}'); }}
@font-face {{ font-family: Poppins; font-weight: 600; src: url('{(FONTS / 'Poppins-SemiBold.ttf').as_uri()}'); }}
@font-face {{ font-family: Poppins; font-weight: 700; src: url('{(FONTS / 'Poppins-Bold.ttf').as_uri()}'); }}
* {{ margin: 0; box-sizing: border-box; }}
body {{ font-family: Poppins; }}
"""

BACKGROUND = "linear-gradient(165deg, #0B7A75 0%, #0A5F67 55%, #0F2A44 100%)"


def status_bar(kind: str, scale: float, dark_screen: bool) -> str:
    color = "#FFFFFF" if dark_screen else "#0F2A44"
    if kind == "ios":
        h = 62 * scale
        island = (f'<div style="position:absolute;left:50%;top:{11*scale}px;width:{124*scale}px;'
                  f'height:{36*scale}px;margin-left:{-62*scale}px;border-radius:{18*scale}px;'
                  'background:#000"></div>')
        time_style = f"left:{50*scale}px;font-size:{17*scale}px;font-weight:600"
        icons_x = f"right:{36*scale}px"
        icon_h = 13 * scale
    else:
        h = 28 * scale
        island = (f'<div style="position:absolute;left:50%;top:{7*scale}px;width:{14*scale}px;'
                  f'height:{14*scale}px;margin-left:{-7*scale}px;border-radius:50%;background:#000"></div>')
        time_style = f"left:{18*scale}px;font-size:{13*scale}px;font-weight:500"
        icons_x = f"right:{18*scale}px"
        icon_h = 11 * scale
    icons = f"""
<svg style="position:absolute;{icons_x};top:50%;transform:translateY(-50%)" height="{icon_h}" viewBox="0 0 76 14">
  <g fill="{color}">
    <rect x="0" y="9" width="3.5" height="5" rx="1"/><rect x="5.5" y="6.5" width="3.5" height="7.5" rx="1"/>
    <rect x="11" y="4" width="3.5" height="10" rx="1"/><rect x="16.5" y="1" width="3.5" height="13" rx="1"/>
    <path d="M33 4.2a11 11 0 0 1 15 0l-1.6 1.7a8.6 8.6 0 0 0-11.8 0z"/>
    <path d="M36 7.4a6.6 6.6 0 0 1 9 0l-1.6 1.7a4.3 4.3 0 0 0-5.8 0z"/>
    <circle cx="40.5" cy="12" r="1.8"/>
    <rect x="52" y="1.5" width="21" height="11" rx="3" fill="none" stroke="{color}" stroke-width="1.4" opacity=".5"/>
    <rect x="54" y="3.5" width="15" height="7" rx="1.5"/>
    <rect x="74" y="5" width="1.8" height="4" rx=".9" opacity=".5"/>
  </g>
</svg>"""
    return (f'<div style="position:absolute;left:0;top:0;right:0;height:{h}px;color:{color}">'
            f'{island}<div style="position:absolute;{time_style};top:50%;transform:translateY(-50%)">9:41</div>'
            f'{icons}</div>')


def screen_page(kind: str, name: str, title: str, sub: str) -> str:
    d = DEVICES[kind]
    raw = RAW / kind / f"{name}.png"
    scale = d["phone"] / d["raw_w"] * (3 if kind == "ios" else 2.625)
    dark = name == "2-scannen" or name == "6-privacy"
    outer_w = d["phone"] + 2 * d["bezel"]
    left = (d["w"] - outer_w) / 2
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{CSS_FONTS}
body {{ width:{d['w']}px; height:{d['h']}px; overflow:hidden; background:{BACKGROUND}; position:relative; }}
.head {{ position:absolute; left:{d['w']*0.08}px; right:{d['w']*0.08}px; top:{d['top']*0.22}px;
  text-align:center; color:#fff; }}
h1 {{ text-wrap:balance; font-size:{d['title']}px; line-height:1.15; font-weight:700; letter-spacing:-0.5px; }}
p {{ text-wrap:balance; margin-top:{d['sub']*0.55}px; font-size:{d['sub']}px; line-height:1.35; opacity:.88; }}
.phone {{ position:absolute; left:{left}px; top:{d['top']}px; width:{outer_w}px;
  padding:{d['bezel']}px; background:#0C1620; border-radius:{d['radius'] + d['bezel']}px;
  box-shadow: 0 40px 90px rgba(0,0,0,.45), inset 0 0 0 3px #26323d; }}
.screen {{ position:relative; border-radius:{d['radius']}px; overflow:hidden; }}
.screen img {{ display:block; width:100%; }}
</style></head><body>
<div class="head"><h1>{title}</h1><p>{sub}</p></div>
<div class="phone"><div class="screen"><img src="{raw.as_uri()}">{status_bar(kind, scale, dark)}</div></div>
</body></html>"""


def feature_page() -> str:
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{CSS_FONTS}
body {{ width:1024px; height:500px; overflow:hidden; background:{BACKGROUND}; position:relative; color:#fff; }}
.logo {{ position:absolute; left:72px; top:70px; display:flex; align-items:center; gap:22px; }}
.logo img {{ width:96px; height:96px; border-radius:22px; box-shadow:0 10px 30px rgba(0,0,0,.25); }}
.logo span {{ font-size:56px; font-weight:700; letter-spacing:-1px; }}
h1 {{ position:absolute; left:72px; top:205px; width:520px; font-size:40px; line-height:1.2; font-weight:700; }}
p {{ position:absolute; left:72px; top:320px; width:500px; font-size:21px; line-height:1.45; opacity:.9; }}
.phone {{ position:absolute; right:70px; top:52px; width:300px; padding:10px; background:#0C1620;
  border-radius:52px; box-shadow:0 30px 70px rgba(0,0,0,.45), inset 0 0 0 2px #26323d; transform:rotate(6deg); }}
.phone img {{ display:block; width:100%; border-radius:42px; }}
</style></head><body>
<div class="logo"><img src="{ICON.as_uri()}"><span>Bonvrij</span></div>
<h1>Bonnen en garanties veilig op je telefoon</h1>
<p>Scan je bon, bewaar je factuur en krijg een herinnering op de datum die jij kiest.</p>
<div class="phone"><img src="{(RAW / 'ios' / '1-home.png').as_uri()}"></div>
</body></html>"""


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    tmp = OUT / ".tmp"
    tmp.mkdir(parents=True)
    with sync_playwright() as pw:
        browser = pw.chromium.launch()

        def render(html: str, path: pathlib.Path, w: int, h: int) -> None:
            page = browser.new_page(viewport={"width": w, "height": h})
            src = tmp / (path.stem + ".html")
            src.write_text(html, encoding="utf-8")
            page.goto(src.as_uri())
            page.wait_for_load_state("networkidle")
            page.evaluate("document.fonts.ready")
            path.parent.mkdir(parents=True, exist_ok=True)
            page.screenshot(path=str(path), omit_background=False)
            page.close()

        for kind in ("ios", "android"):
            d = DEVICES[kind]
            for name, title, sub in SCREENS:
                render(screen_page(kind, name, title, sub),
                       OUT / kind / f"{name}.png", d["w"], d["h"])
        render(feature_page(), OUT / "google-play" / "feature-graphic-1024x500.png", 1024, 500)
        browser.close()
    shutil.rmtree(tmp)

    # Icoon 512×512 voor Google Play (zonder doorzichtigheid).
    from PIL import Image
    icon = Image.open(ICON).convert("RGB").resize((512, 512), Image.LANCZOS)
    icon.save(OUT / "google-play" / "icoon-512.png")
    # Apple en Google accepteren geen doorzichtigheid: alles naar RGB.
    for png in sorted(OUT.rglob("*.png")):
        with Image.open(png) as im:
            im.convert("RGB").save(png)
            print(f"{png.relative_to(ROOT)}  {im.size[0]}x{im.size[1]}")


if __name__ == "__main__":
    main()
