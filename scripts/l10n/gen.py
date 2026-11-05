"""Genereert lib/l10n/app_strings*.dart uit registry.py."""
import sys, importlib.util, os
spec = importlib.util.spec_from_file_location('reg', os.path.join(os.path.dirname(__file__), 'registry.py'))
reg = importlib.util.module_from_spec(spec); spec.loader.exec_module(reg)
out = sys.argv[1]
simple = reg.SIMPLE + reg.EXTRA_SIMPLE
keys = [k for k, *_ in simple] + [k for k, *_ in reg.METHODS]
dups = {k for k in keys if keys.count(k) > 1}
assert not dups, dups

def lit(v):
    v = v.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n')
    return f"'{v}'"

head = "// GEGENEREERD door scripts/l10n/gen.py. Pas de teksten aan in\n// scripts/l10n/registry.py en genereer opnieuw; niet met de hand bewerken.\n"
lines = [head, "import 'strings_en.dart';", "import 'strings_nl.dart';", "",
 "/// Alle teksten van de app, per taal. Gebruik: `S.current.save`.",
 "abstract class S {", "  const S();", "",
 "  /// Teksten van de taal die nu actief is (zie [AppLocale]).",
 "  static S current = const StringsNl();", "",
 "  static const S nl = StringsNl();", "  static const S en = StringsEn();", ""]
for k, nl, en in simple:
    lines.append(f"  String get {k};")
for k, params, nl, en in reg.METHODS:
    lines.append(f"  String {k}({params});")
lines.append("}")
open(os.path.join(out, 'app_strings.dart'), 'w').write('\n'.join(lines) + '\n')

for lang, cls, idx in (('nl', 'StringsNl', 1), ('en', 'StringsEn', 2)):
    L = [head, "import 'app_strings.dart';", "", f"class {cls} extends S {{", f"  const {cls}();", ""]
    for row in simple:
        L += ["  @override", f"  String get {row[0]} => {lit(row[idx])};", ""]
    for k, params, nl, en in reg.METHODS:
        L += ["  @override", f"  String {k}({params}) => {(nl, en)[idx-1]};", ""]
    L.append("}")
    open(os.path.join(out, f'strings_{lang}.dart'), 'w').write('\n'.join(L) + '\n')
print(len(keys), 'teksten')
