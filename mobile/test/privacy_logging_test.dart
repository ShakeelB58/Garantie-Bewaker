import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Logregels mogen nooit gegevens van de gebruiker bevatten (productnamen,
/// paden, herkende tekst). Alleen het soort fout (`runtimeType`) is
/// toegestaan.
void main() {
  test('logregels bevatten alleen het fouttype', () {
    final violations = <String>[];
    // debugPrint('...') met één tekst tussen enkele aanhalingstekens.
    final call = RegExp(r"debugPrint\(\s*(')?((?:[^'\\]|\\.)*)'?");
    final interpolation = RegExp(r'\$\{([^}]*)\}|\$([A-Za-z_]\w*)');

    for (final file in _dartFiles()) {
      final source = file.readAsStringSync();
      for (final match in call.allMatches(source)) {
        if (match.group(1) == null) {
          violations.add('${file.path}: geen vaste tekst in debugPrint');
          continue;
        }
        for (final value in interpolation.allMatches(match.group(2)!)) {
          final expression = value.group(1) ?? value.group(2)!;
          if (!expression.trim().endsWith('.runtimeType')) {
            violations.add('${file.path}: ${match.group(0)}');
          }
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('geen print() in de app-code', () {
    for (final file in _dartFiles()) {
      expect(
        RegExp(r'(?<![\w.])print\(').hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }
  });
}

Iterable<File> _dartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));
