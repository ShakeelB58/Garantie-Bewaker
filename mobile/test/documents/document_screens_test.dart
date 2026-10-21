import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/errors/user_message.dart';
import 'package:garantiebewaker/features/documents/data/document_picker.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';

import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/test_app.dart';

Finder _field(String key) => find.byKey(Key('productForm.$key'));

Future<void> _openAddPurchase(WidgetTester tester) async {
  await tester.tap(find.text('Aankoop toevoegen'));
  await tester.pumpAndSettle();
}

void main() {
  late InMemoryDocumentRepository documents;
  late InMemoryDocumentFileStore fileStore;
  late FakeDocumentPicker picker;

  setUp(() {
    documents = InMemoryDocumentRepository();
    fileStore = InMemoryDocumentFileStore();
    picker = FakeDocumentPicker();
  });

  Future<InMemoryProductRepository> start(
    WidgetTester tester, {
    InMemoryProductRepository? repository,
  }) => pumpApp(
    tester,
    repository: repository,
    documents: documents,
    fileStore: fileStore,
    picker: picker,
  );

  group('kassabon scannen', () {
    testWidgets(
      'foto controleren, gebruiken en opslaan bij een nieuw product',
      (tester) async {
        fileStore.addSource('/tmp/camera1.jpg', jpegBytes);
        picker.results.add(const PickedFile(path: '/tmp/camera1.jpg'));
        final products = await start(tester);

        await _openAddPurchase(tester);
        await tester.tap(find.text('Kassabon scannen'));
        await tester.pumpAndSettle();

        expect(picker.requests, [DocumentSource.camera]);
        expect(find.text('Foto controleren'), findsOneWidget);

        await tester.tap(find.text('Gebruiken'));
        await tester.pumpAndSettle();

        // Formulier met het gescande document.
        expect(find.text('Product toevoegen'), findsOneWidget);
        expect(find.text('Kassabon'), findsOneWidget);
        expect(fileStore.stored, hasLength(1));
        // De tijdelijke camerafoto is opgeruimd.
        expect(fileStore.sources, isEmpty);

        await tester.enterText(_field('name'), 'Koffiezetapparaat');
        await tester.tap(_field('save'));
        await tester.pumpAndSettle();

        final product = products.all.single;
        expect(documents.all, hasLength(1));
        expect(documents.all.single.productId, product.id);
        expect(documents.all.single.type, DocumentType.receipt);
        // Detailscherm toont het document.
        expect(find.text('Aankoopbewijzen'), findsOneWidget);
        expect(find.text('Kassabon'), findsOneWidget);
      },
    );

    testWidgets('opnieuw maken gooit de eerste foto weg', (tester) async {
      fileStore
        ..addSource('/tmp/wazig.jpg', jpegBytes)
        ..addSource('/tmp/scherp.jpg', jpegBytes);
      picker.results.addAll(const [
        PickedFile(path: '/tmp/wazig.jpg'),
        PickedFile(path: '/tmp/scherp.jpg'),
      ]);
      await start(tester);

      await _openAddPurchase(tester);
      await tester.tap(find.text('Kassabon scannen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Opnieuw'));
      await tester.pumpAndSettle();

      expect(fileStore.sources.keys, ['/tmp/scherp.jpg']);
      expect(find.text('Foto controleren'), findsOneWidget);

      await tester.tap(find.text('Gebruiken'));
      await tester.pumpAndSettle();
      expect(find.text('Product toevoegen'), findsOneWidget);
      expect(fileStore.stored, hasLength(1));
    });

    testWidgets('geen cameratoegang geeft een begrijpelijke melding', (
      tester,
    ) async {
      picker.error = const AppException(
        'Bonvrij heeft geen toegang tot de camera.',
      );
      await start(tester);

      await _openAddPurchase(tester);
      await tester.tap(find.text('Kassabon scannen'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bonvrij heeft geen toegang tot de camera.'),
        findsOneWidget,
      );
      // Handmatig invoeren blijft altijd mogelijk.
      expect(find.text('Handmatig invoeren'), findsOneWidget);
    });

    testWidgets('formulier weggooien verwijdert ook het gescande document', (
      tester,
    ) async {
      fileStore.addSource('/tmp/camera1.jpg', jpegBytes);
      picker.results.add(const PickedFile(path: '/tmp/camera1.jpg'));
      final products = await start(tester);

      await _openAddPurchase(tester);
      await tester.tap(find.text('Kassabon scannen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gebruiken'));
      await tester.pumpAndSettle();
      expect(fileStore.stored, hasLength(1));

      await tapBack(tester);
      expect(find.text('Wijzigingen weggooien?'), findsOneWidget);
      await tester.tap(find.text('Weggooien'));
      await tester.pumpAndSettle();

      expect(fileStore.stored, isEmpty);
      expect(products.all, isEmpty);
      expect(documents.all, isEmpty);
    });
  });

  group('PDF of afbeelding importeren', () {
    testWidgets('PDF uit bestanden wordt een factuur', (tester) async {
      fileStore.addSource('/tmp/inbox/factuur.pdf', pdfBytes);
      picker.results.add(
        const PickedFile(
          path: '/tmp/inbox/factuur.pdf',
          originalName: 'factuur.pdf',
        ),
      );
      await start(tester);

      await _openAddPurchase(tester);
      await tester.tap(find.text('PDF of afbeelding importeren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiezen uit bestanden (PDF of afbeelding)'));
      await tester.pumpAndSettle();

      expect(picker.requests, [DocumentSource.files]);
      expect(find.text('Product toevoegen'), findsOneWidget);
      expect(find.text('Factuur'), findsOneWidget);
      expect(find.text('factuur.pdf'), findsOneWidget);
    });

    testWidgets('niet-ondersteund bestand wordt geweigerd', (tester) async {
      fileStore.addSource('/tmp/notitie.pdf', textBytes);
      picker.results.add(const PickedFile(path: '/tmp/notitie.pdf'));
      await start(tester);

      await _openAddPurchase(tester);
      await tester.tap(find.text('PDF of afbeelding importeren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiezen uit bestanden (PDF of afbeelding)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('wordt niet ondersteund'), findsOneWidget);
      expect(find.text('Hoe wil je je aankoop toevoegen?'), findsOneWidget);
      expect(fileStore.stored, isEmpty);
    });
  });

  group('documenten bij een bestaand product', () {
    InMemoryProductRepository seeded() =>
        InMemoryProductRepository([makeProduct(name: 'Wasmachine')]);

    Future<void> openProduct(WidgetTester tester) async {
      await tester.tap(find.text('Producten'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wasmachine'));
      await tester.pumpAndSettle();
    }

    testWidgets('document toevoegen via het productscherm', (tester) async {
      fileStore.addSource('/tmp/garantie.pdf', pdfBytes);
      picker.results.add(const PickedFile(path: '/tmp/garantie.pdf'));
      await start(tester, repository: seeded());
      await openProduct(tester);

      expect(find.textContaining('Nog geen documenten'), findsOneWidget);

      await tester.tap(find.byKey(const Key('documents.add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiezen uit bestanden (PDF of afbeelding)'));
      await tester.pumpAndSettle();

      expect(find.text('Document toegevoegd.'), findsOneWidget);
      expect(find.text('Factuur'), findsOneWidget);
      expect(documents.all.single.productId, 'p1');
    });

    testWidgets('soort van een document wijzigen', (tester) async {
      documents = InMemoryDocumentRepository([makeDocument()]);
      fileStore.addStored('documents/d1.pdf', pdfBytes);
      await start(tester, repository: seeded());
      await openProduct(tester);

      await tester.tap(find.byTooltip('Soort wijzigen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garantiebewijs'));
      await tester.pumpAndSettle();

      expect(documents.all.single.type, DocumentType.warranty);
      expect(find.text('Garantiebewijs'), findsOneWidget);
    });

    testWidgets('document openen en verwijderen na bevestiging', (
      tester,
    ) async {
      documents = InMemoryDocumentRepository([makeDocument()]);
      fileStore.addStored('documents/d1.pdf', pdfBytes);
      await start(tester, repository: seeded());
      await openProduct(tester);

      await tester.tap(find.text('Factuur'));
      await tester.pumpAndSettle();
      // In de test bestaat het echte bestand niet; de viewer meldt dat netjes.
      expect(find.textContaining('niet gevonden'), findsOneWidget);

      await tester.tap(find.byTooltip('Verwijderen'));
      await tester.pumpAndSettle();
      expect(find.text('Document verwijderen?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Verwijderen'));
      await tester.pumpAndSettle();

      expect(find.text('Document verwijderd.'), findsOneWidget);
      expect(documents.all, isEmpty);
      expect(fileStore.stored, isEmpty);
      expect(find.textContaining('Nog geen documenten'), findsOneWidget);
    });

    testWidgets('product verwijderen verwijdert ook de bestanden', (
      tester,
    ) async {
      documents = InMemoryDocumentRepository([makeDocument()]);
      fileStore.addStored('documents/d1.pdf', pdfBytes);
      final products = await start(tester, repository: seeded());
      await openProduct(tester);

      await tester.tap(find.byTooltip('Verwijderen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('alle aankoopbewijzen'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Verwijderen'));
      await tester.pumpAndSettle();

      expect(products.all, isEmpty);
      expect(documents.all, isEmpty);
      expect(fileStore.stored, isEmpty);
    });
  });
}
