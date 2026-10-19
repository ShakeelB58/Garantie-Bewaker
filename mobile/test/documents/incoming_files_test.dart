import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/documents/data/incoming_files.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';

import '../helpers/document_fakes.dart';
import '../helpers/test_app.dart';

/// "Openen met" en "Delen" vanuit andere apps.
void main() {
  testWidgets('gedeelde PDF opent het formulier met het document', (
    tester,
  ) async {
    final fileStore = InMemoryDocumentFileStore()
      ..addSource('/cache/open_file_handler/factuur.pdf', pdfBytes)
      ..addSource('/Documents/Inbox/factuur.pdf', pdfBytes);
    final incoming = FakeIncomingFileSource();
    final documents = InMemoryDocumentRepository();
    await pumpApp(
      tester,
      fileStore: fileStore,
      incoming: incoming,
      documents: documents,
    );

    incoming.send(
      const IncomingFile(
        path: '/cache/open_file_handler/factuur.pdf',
        name: 'factuur.pdf',
        originalPath: '/Documents/Inbox/factuur.pdf',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product toevoegen'), findsOneWidget);
    expect(find.text('Factuur'), findsOneWidget);
    expect(find.text('factuur.pdf'), findsOneWidget);

    // Opgeslagen in de app; tijdelijke kopie én iOS-inbox opgeruimd.
    expect(fileStore.stored.keys.single, endsWith('.pdf'));
    expect(fileStore.sources, isEmpty);
    expect(incoming.releaseCount, 1);
    // Pas gekoppeld na opslaan.
    expect(documents.all, isEmpty);
  });

  testWidgets('gedeeld bestand opslaan koppelt het aan het nieuwe product', (
    tester,
  ) async {
    final fileStore = InMemoryDocumentFileStore()
      ..addSource('/cache/bon.jpg', jpegBytes);
    final incoming = FakeIncomingFileSource();
    final documents = InMemoryDocumentRepository();
    final products = await pumpApp(
      tester,
      fileStore: fileStore,
      incoming: incoming,
      documents: documents,
    );

    incoming.send(const IncomingFile(path: '/cache/bon.jpg'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('productForm.name')),
      'Stofzuiger',
    );
    await tester.tap(find.byKey(const Key('productForm.save')));
    await tester.pumpAndSettle();

    expect(products.all.single.name, 'Stofzuiger');
    expect(documents.all.single.type, DocumentType.receipt);
    expect(documents.all.single.productId, products.all.single.id);
  });

  testWidgets('niet-ondersteund gedeeld bestand geeft een melding', (
    tester,
  ) async {
    final fileStore = InMemoryDocumentFileStore()
      ..addSource('/cache/notitie.txt', textBytes);
    final incoming = FakeIncomingFileSource();
    await pumpApp(tester, fileStore: fileStore, incoming: incoming);

    incoming.send(const IncomingFile(path: '/cache/notitie.txt'));
    await tester.pumpAndSettle();

    expect(find.textContaining('wordt niet ondersteund'), findsOneWidget);
    expect(find.text('Product toevoegen'), findsNothing);
    expect(fileStore.stored, isEmpty);
    expect(incoming.releaseCount, 1);
  });

  testWidgets('fout bij ontvangen geeft een melding', (tester) async {
    final incoming = FakeIncomingFileSource();
    await pumpApp(tester, incoming: incoming);

    incoming.controller.addError(Exception('kapot'));
    await tester.pumpAndSettle();

    expect(find.text('Er ging iets mis. Probeer het opnieuw.'), findsOneWidget);
  });
}
