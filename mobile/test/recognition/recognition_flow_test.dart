import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/documents/data/document_picker.dart';

import '../helpers/document_fakes.dart';
import '../helpers/recognition_fakes.dart';
import '../helpers/test_app.dart';

Finder _field(String key) => find.byKey(Key('productForm.$key'));

String _fieldText(WidgetTester tester, String key) =>
    tester.widget<TextField>(_field(key)).controller!.text;

/// Van scannen/importeren tot een ingevuld controleformulier.
void main() {
  late InMemoryDocumentFileStore fileStore;
  late FakeDocumentPicker picker;
  late FakeTextRecognizer recognizer;
  late FakePdfPageSource pdfPages;

  setUp(() {
    fileStore = InMemoryDocumentFileStore();
    picker = FakeDocumentPicker();
    recognizer = FakeTextRecognizer();
    pdfPages = FakePdfPageSource();
  });

  Future<void> start(WidgetTester tester) => pumpApp(
    tester,
    fileStore: fileStore,
    picker: picker,
    recognizer: recognizer,
    pdfPages: pdfPages,
  );

  Future<void> scanReceipt(WidgetTester tester) async {
    fileStore.addSource('/tmp/bon.jpg', jpegBytes);
    picker.results.add(const PickedFile(path: '/tmp/bon.jpg'));
    await tester.tap(find.text('Aankoop toevoegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kassabon scannen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gebruiken'));
    await tester.pumpAndSettle();
  }

  testWidgets('PDF-factuur: velden worden voorgesteld en gemarkeerd', (
    tester,
  ) async {
    fileStore.addSource('/tmp/factuur.pdf', pdfBytes);
    picker.results.add(
      const PickedFile(path: '/tmp/factuur.pdf', originalName: 'factuur.pdf'),
    );
    pdfPages.pageTexts = [testfactuurText];
    await start(tester);

    await tester.tap(find.text('Aankoop toevoegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF of afbeelding importeren'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kiezen uit bestanden (PDF of afbeelding)'));
    await tester.pumpAndSettle();

    expect(find.text('Gegevens overgenomen uit het document'), findsOneWidget);
    expect(find.textContaining('1.348,95'), findsOneWidget);
    expect(_fieldText(tester, 'name'), 'Wasmachine Voorbeeld WM-8000 8 kg');
    expect(_fieldText(tester, 'merchant'), 'Voorbeeldwinkel Elektronica');
    // Eén product: de regelprijs, niet het totaal met bezorging.
    expect(_fieldText(tester, 'price'), '1299,00');
    expect(find.text('12 oktober 2026'), findsOneWidget);
    expect(
      find.text('Herkend uit het document. Controleer dit.'),
      findsWidgets,
    );
    // Eén product: geen keuzelijst.
    expect(find.text('Welk product wil je bewaren?'), findsNothing);
  });

  testWidgets('bon met meerdere producten: gebruiker kiest het product', (
    tester,
  ) async {
    recognizer.text = testbonText;
    await start(tester);
    await scanReceipt(tester);

    expect(find.text('Welk product wil je bewaren?'), findsOneWidget);
    expect(_fieldText(tester, 'merchant'), 'Voorbeeldmarkt');
    expect(find.text('15 oktober 2026'), findsOneWidget);
    // Eerste product als onzeker voorstel, prijs bewust leeg.
    expect(_fieldText(tester, 'name'), 'Waterkoker WK-200');
    expect(find.text('Onzeker herkend. Controleer dit goed.'), findsOneWidget);
    expect(_fieldText(tester, 'price'), isEmpty);

    await tester.tap(find.byKey(const Key('recognition.item.1')));
    await tester.pumpAndSettle();

    expect(_fieldText(tester, 'name'), 'Theedoek');
    expect(_fieldText(tester, 'price'), '3,49');
  });

  testWidgets('aangepast veld telt als eigen invoer', (tester) async {
    recognizer.text = testbonText;
    await start(tester);
    await scanReceipt(tester);

    expect(
      find.text('Herkend uit het document. Controleer dit.'),
      findsWidgets,
    );
    await tester.enterText(_field('merchant'), 'Andere winkel');
    await tester.pump();

    final merchantField = tester.widget<TextField>(_field('merchant'));
    expect(merchantField.decoration!.helperText, isNull);
  });

  testWidgets('herkennen mislukt: melding en handmatig verder', (tester) async {
    recognizer.error = StateError('OCR kapot');
    await start(tester);
    await scanReceipt(tester);

    expect(
      find.text('Automatisch herkennen lukte niet. Vul de gegevens zelf in.'),
      findsOneWidget,
    );
    expect(find.text('Product toevoegen'), findsOneWidget);
    expect(find.byKey(const Key('recognition.banner')), findsNothing);
    expect(_fieldText(tester, 'name'), isEmpty);
    expect(find.text('Kassabon'), findsOneWidget);
  });

  testWidgets('niets herkend: duidelijke uitleg', (tester) async {
    recognizer.text = '';
    await start(tester);
    await scanReceipt(tester);

    expect(find.text('Geen gegevens herkend'), findsOneWidget);
    expect(_fieldText(tester, 'name'), isEmpty);
  });

  testWidgets('herkende gegevens worden pas bij opslaan bewaard', (
    tester,
  ) async {
    pdfPages.pageTexts = [testfactuurText];
    fileStore.addSource('/tmp/factuur.pdf', pdfBytes);
    picker.results.add(const PickedFile(path: '/tmp/factuur.pdf'));
    final products = await pumpApp(
      tester,
      fileStore: fileStore,
      picker: picker,
      recognizer: recognizer,
      pdfPages: pdfPages,
    );

    await tester.tap(find.text('Aankoop toevoegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF of afbeelding importeren'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kiezen uit bestanden (PDF of afbeelding)'));
    await tester.pumpAndSettle();
    expect(products.all, isEmpty);

    await tester.tap(_field('save'));
    await tester.pumpAndSettle();

    final saved = products.all.single;
    expect(saved.name, 'Wasmachine Voorbeeld WM-8000 8 kg');
    expect(saved.merchant, 'Voorbeeldwinkel Elektronica');
    expect(saved.purchaseDate, DateTime(2026, 10, 12));
    expect(saved.purchasePriceMinor, 129900);
  });
}
