import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/utils/money.dart';

void main() {
  group('Money.parseToMinor', () {
    final valid = <String, int>{
      '1.299,00': 129900,
      '1299,00': 129900,
      '1299': 129900,
      '1.299': 129900,
      '12,5': 1250,
      '12,50': 1250,
      '0,99': 99,
      ',99': 99,
      '€ 12,50': 1250,
      '€12,50': 1250,
      'EUR 12,50': 1250,
      '12.50': 1250,
      '12.5': 1250,
      '1.234.567,89': 123456789,
      '  49,95 ': 4995,
      '1\u00A0299,00': 129900,
    };
    for (final MapEntry(key: input, value: expected) in valid.entries) {
      test('"$input" -> $expected', () {
        expect(Money.parseToMinor(input), expected);
      });
    }

    final invalid = [
      '',
      '   ',
      'abc',
      '12,345',
      '1,2,3',
      '1.29,00',
      '12.34.5',
      '-5,00',
      '12,5a',
      '1299,00,00',
    ];
    for (final input in invalid) {
      test('"$input" is ongeldig', () {
        expect(Money.parseToMinor(input), isNull);
      });
    }
  });

  group('Money.format', () {
    String normalize(String s) => s.replaceAll(RegExp(r'[\s\u00A0]'), ' ');

    test('eurobedrag in Nederlandse notatie', () {
      expect(normalize(Money.format(129900, 'EUR')), '€ 1.299,00');
    });

    test('centen blijven exact', () {
      expect(normalize(Money.format(5, 'EUR')), '€ 0,05');
    });
  });

  test('formatForInput maakt een bewerkbaar bedrag', () {
    expect(Money.formatForInput(129900), '1299,00');
    expect(Money.formatForInput(5), '0,05');
    expect(Money.parseToMinor(Money.formatForInput(123456)), 123456);
  });
}
