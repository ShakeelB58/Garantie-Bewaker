import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/data_management/domain/products_csv.dart';

import '../helpers/fixtures.dart';

void main() {
  test('kop, Nederlandse datums en bedragen, aantal documenten', () {
    final csv = ProductsCsv.build([
      makeProduct(
        name: 'Wasmachine',
        brand: 'Bosch',
        merchant: 'Coolblue',
        purchaseDate: DateTime(2026, 3, 5),
        purchasePriceMinor: 129900,
        warrantyEndDate: DateTime(2028, 3, 5),
        reminderEnabled: true,
        reminderDate: DateTime(2028, 2, 5),
      ),
      makeProduct(
        id: 'p2',
        name: 'Föhn',
        merchant: null,
        purchasePriceMinor: null,
      ),
    ], {'p1': 2});

    expect(csv.startsWith('﻿'), isTrue);
    final lines = csv.substring(1).split('\r\n');
    expect(
      lines[0],
      'Naam;Merk;Categorie;Winkel;Aankoopdatum;Aankoopprijs;Valuta;'
      'Garantie tot;Herinnering aan;Herinneringsdatum;Aantal documenten',
    );
    expect(
      lines[1],
      'Wasmachine;Bosch;Huishoudelijk;Coolblue;05-03-2026;1299,00;EUR;'
      '05-03-2028;ja;05-02-2028;2',
    );
    expect(lines[2], 'Föhn;;Huishoudelijk;;30-09-2026;;EUR;;nee;;0');
    expect(lines[3], isEmpty);
  });

  group('cellen veilig maken', () {
    test('scheidingsteken, aanhalingstekens en regeleinden', () {
      expect(ProductsCsv.escape('Tv; 55 inch'), '"Tv; 55 inch"');
      expect(ProductsCsv.escape('Tv "Pro"'), '"Tv ""Pro"""');
      expect(ProductsCsv.escape('regel 1\nregel 2'), '"regel 1\nregel 2"');
      expect(ProductsCsv.escape('Gewoon'), 'Gewoon');
    });

    test('formules worden nooit uitgevoerd (CSV-injectie)', () {
      expect(ProductsCsv.escape('=SUM(A1)'), "'=SUM(A1)");
      // Met aanhalingstekens: apostrof én tussen aanhalingstekens.
      expect(
        ProductsCsv.escape('=HYPERLINK("x")'),
        '"\'=HYPERLINK(""x"")"',
      );
      expect(ProductsCsv.escape('+31 6'), "'+31 6");
      expect(ProductsCsv.escape('-korting'), "'-korting");
      expect(ProductsCsv.escape('@user'), "'@user");
      // Combinatie: apostrof en aanhalingstekens.
      expect(ProductsCsv.escape('=A1;B1'), '"\'=A1;B1"');
    });
  });
}
