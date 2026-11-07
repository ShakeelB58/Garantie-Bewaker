import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/in_memory_product_repository.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('snelkeuze garantie: aankoopdatum plus gekozen jaren', (
    tester,
  ) async {
    final repo = InMemoryProductRepository();
    await pumpApp(tester, repository: repo);
    await tester.tap(find.byKey(const Key('nav.add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Handmatig invoeren'));
    await tester.pumpAndSettle();

    expect(find.text('Merk'), findsOneWidget);
    expect(find.text('bijv. Bosch'), findsOneWidget);

    final twoYears = find.byKey(const Key('productForm.warranty2y'));
    await tester.ensureVisible(twoYears);
    await tester.tap(twoYears);
    await tester.pumpAndSettle();
    // Aankoopdatum is standaard vandaag (19 oktober 2026).
    expect(find.text('19 oktober 2028'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(twoYears).selected, isTrue);

    final fiveYears = find.byKey(const Key('productForm.warranty5y'));
    await tester.tap(fiveYears);
    await tester.pumpAndSettle();
    expect(find.text('19 oktober 2031'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(twoYears).selected, isFalse);
  });
}
