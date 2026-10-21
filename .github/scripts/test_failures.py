"""Zet foutmeldingen uit `flutter test --reporter expanded` om naar
GitHub-annotaties (maximaal 10, elk compact), zodat ze zonder logbestand
leesbaar zijn."""
import re
import sys

text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
blocks = re.findall(r"══╡ EXCEPTION CAUGHT BY (.*?)╞═+\n(.*?)\n═{20,}", text, re.S)

seen = set()
count = 0
for source, body in blocks:
    keep = []
    for line in body.splitlines():
        s = line.strip()
        if (
            s.startswith("The following")
            or "overflowed" in s
            or s.startswith("creator:")
            or "Expected:" in s
            or "Actual:" in s
            or "Which:" in s
            or s.startswith("Bad state")
            or s.startswith("The finder")
            or re.search(r"\(file:///.*/mobile/(lib|test)/", s)
            or s.startswith("The test description was")
            or (keep and keep[-1].startswith("The test description was"))
        ):
            keep.append(s[:1500])
    if not keep:
        keep = [l.strip()[:300] for l in body.splitlines()[:15]]
    msg = f"[{source.strip()}] " + "\n".join(keep)
    key = re.sub(r"#\d+|RenderFlex#\w+|\d+(\.\d+)? pixels", "", msg)
    if key in seen:
        continue
    seen.add(key)
    msg = msg[:3800].replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::error title=Testfout {count + 1}::{msg}")
    count += 1
    if count == 9:
        break
