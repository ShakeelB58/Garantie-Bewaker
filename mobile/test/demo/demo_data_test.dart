import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/utils/dates.dart';
import 'package:garantiebewaker/features/demo/demo_data.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';
import 'package:garantiebewaker/features/documents/domain/document_validation.dart';
import 'package:garantiebewaker/features/products/domain/product_input.dart';

import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';

void main() {
  group('DemoData', () {
    var next = 0;
    final products = DemoData.buildProducts(
      now: testNow,
      newId: () => 'demo-${next++}',
    );

    test('levert zes geldige producten', () {
      expect(products, hasLength(6));
      for (final product in products) {
        final errors = ProductValidator.validate(
          ProductInput.fromProduct(product),
          today: testNow,
        );
        expect(errors, isEmpty, reason: product.name);
      }
    });

    test('herinneringen liggen in de toekomst', () {
      final today = Dates.dateOnly(testNow);
      for (final product in products.where((p) => p.reminderEnabled)) {
        expect(product.reminderDate!.isAfter(today), isTrue);
      }
    });

    test('PDF wordt als PDF herkend', () {
      final bytes = DemoData.pdfFor(products.first, DocumentType.receipt);
      expect(DocumentValidation.detectFormat(bytes), DocumentFormat.pdf);
      expect(String.fromCharCodes(bytes.take(8)), startsWith('%PDF-1.4'));
    });
  });

  testWidgets('voorbeeldgegevens laden via Instellingen (testversie)', (
    tester,
  ) async {
    final documents = InMemoryDocumentRepository();
    final repo = await pumpApp(tester, documents: documents);

    await tester.tap(find.byKey(const Key('nav.settings')));
    await tester.pumpAndSettle();
    final tile = find.byKey(const Key('settings.demoData'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('6 voorbeeldproducten toegevoegd.'), findsOneWidget);
    expect(await repo.getAll(), hasLength(6));
    expect(documents.all, hasLength(7));
  });
}
