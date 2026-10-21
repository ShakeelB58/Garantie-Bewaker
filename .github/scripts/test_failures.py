"""Zet foutmeldingen uit `flutter test --reporter expanded` om naar
GitHub-annotaties (maximaal 9, elk compact), zodat ze zonder logbestand
leesbaar zijn."""
import re
import sys

text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
blocks = re.findall(r"══╡ EXCEPTION CAUGHT BY (.*?)╞═+\n(.*?)\n═{20,}", text, re.S)

seen = set()
count = 0
for source, body in blocks:
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
        elif s.startswith("creator:"):
            keep.append(s[:400])
            extra = 2
        elif "/mobile/lib/" in s or "/mobile/test/" in s:
            keep.append(re.sub(r"file:///.*/mobile/", "", s)[:300])
        elif s.startswith("The test description was"):
            extra = 1
    msg = f"[{source.strip()}] " + "\n".join(dict.fromkeys(keep))
    key = re.sub(r"#\w+|\d+(\.\d+)? pixels", "", msg)
    if key in seen:
        continue
    seen.add(key)
    msg = msg[:3800].replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::error title=Testfout {count + 1}::{msg}")
    count += 1
    if count == 9:
        break
