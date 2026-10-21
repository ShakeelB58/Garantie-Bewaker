"""Zet foutmeldingen uit `flutter test --reporter expanded` om naar
GitHub-annotaties (maximaal 9, elk compact), zodat ze zonder logbestand
leesbaar zijn."""
import re
import sys

text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
test_line = re.compile(r"^\d+:\d+ \+\d+.*?: (?:.*/mobile/)?(test/.*?)(?: \[E\])?$", re.M)
block_re = re.compile(r"══╡ EXCEPTION CAUGHT BY (.*?)╞═+\n(.*?)\n═{20,}", re.S)

seen = set()
count = 0
matches = list(block_re.finditer(text))
# Fouten uit de app zelf (layout, widgets) eerst: die zijn meestal de oorzaak
# van mislukte zoekopdrachten in tests.
matches.sort(key=lambda m: "FLUTTER TEST FRAMEWORK" in m.group(1))
for match in matches:
    source, body = match.group(1), match.group(2)
    tests = test_line.findall(text, 0, match.start())
    current = tests[-1] if tests else "?"
    lines = [l.strip() for l in body.splitlines()]
    keep = []
    extra = 0
    for s in lines:
        if extra > 0 and s:
            keep.append(s[:400])
            extra -= 1
            continue
        if s.startswith("The following"):
            keep.append(s)
            extra = 2
        elif s.startswith("The relevant error-causing widget was"):
            extra = 1
        elif s.startswith(("constraints:", "size:")):
            keep.append(s[:200])
        elif s.startswith("creator:") and "DEFUNCT" not in s:
            keep.append(s[:300])
        elif "/mobile/lib/" in s or "/mobile/test/" in s:
            keep.append(re.sub(r"file:///.*/mobile/", "", s)[:300])
    msg = f"[{source.strip()}] in {current}\n" + "\n".join(dict.fromkeys(keep))
    key = re.sub(r"in test/.*\n|#\w+|\d+(\.\d+)? pixels", "", msg)
    if key in seen:
        continue
    seen.add(key)
    msg = msg[:3800].replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::error title=Testfout {count + 1}::{msg}")
    count += 1
    if count == 9:
        break


# Waarschuwingen van tap() die niet raakten: laten zien wat er wél geraakt werd.
warn = re.search(r"Warning: A call to tap\(\).*?(?:\n\s*\n|$)", text, re.S)
if warn:
    msg = warn.group(0)[:3800].replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::error title=Tik mist::{msg}")
