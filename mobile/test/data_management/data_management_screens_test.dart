import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/data_management_fakes.dart';
import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/reminder_fakes.dart';
import '../helpers/test_app.dart';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Instellingen'));
  await tester.pumpAndSettle();
}

void main() {
  late InMemoryProductRepository products;
  late InMemoryDocumentRepository documents;
  late InMemoryDocumentFileStore fileStore;
  late FakeReminderNotifications notifications;
  late InMemorySettingsRepository settings;
  late FakeExportSaver saver;

  setUp(() async {
    products = InMemoryProductRepository([
      makeProduct(
        name: 'Koelkast',
        reminderEnabled: true,
        reminderDate: DateTime(2027, 1, 5),
      ),
    ]);
    documents = InMemoryDocumentRepository();
    fileStore = InMemoryDocumentFileStore();
    await documents.insert(makeDocument());
    fileStore.addStored('documents/d1.pdf', pdfBytes);
    notifications = FakeReminderNotifications();
    settings = InMemorySettingsRepository()
      ..values['reminder_lead_days'] = '60';
    saver = FakeExportSaver();
  });

  Future<void> start(WidgetTester tester) async {
    await pumpApp(
      tester,
      repository: products,
      documents: documents,
      fileStore: fileStore,
      notifications: notifications,
      settings: settings,
      exportSaver: saver,
    );
    await _openSettings(tester);
  }

  group('exporteren', () {
    testWidgets('ZIP wordt via het bewaarvenster bewaard', (tester) async {
      await start(tester);

      await tester.tap(find.byKey(const Key('settings.export')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Bewaar het op een veilige plek'),
        findsOneWidget,
      );
      await tester.tap(find.text('Exporteren'));
      await tester.pumpAndSettle();

      expect(saver.fileName, 'garantiebewaker-export-2026-10-19.zip');
      expect(saver.mimeType, 'application/zip');
      final names = ZipDecoder()
          .decodeBytes(saver.bytes!)
          .map((f) => f.name)
          .toList();
      expect(names, contains('documenten/001-koelkast-factuur-1.pdf'));
      expect(
        find.text('Export bewaard: 1 product en 1 document.'),
        findsOneWidget,
      );
    });

    testWidgets('annuleren in het bewaarvenster: geen melding', (tester) async {
      saver.accept = false;
      await start(tester);

      await tester.tap(find.byKey(const Key('settings.export')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exporteren'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Export bewaard'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('alles verwijderen', () {
    testWidgets('pas na het vinkje, daarna is alles weg', (tester) async {
      await start(tester);

      await tester.tap(find.byKey(const Key('settings.deleteAll')));
      await tester.pumpAndSettle();

      final confirm = find.byKey(const Key('deleteAll.confirm'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.tap(find.byKey(const Key('deleteAll.understood')));
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(products.all, isEmpty);
      expect(documents.all, isEmpty);
      expect(fileStore.stored, isEmpty);
      expect(settings.values, isEmpty);
      expect(notifications.cancelAllCalls, 1);
      expect(find.text('Alle gegevens zijn verwijderd.'), findsOneWidget);
      // Terug naar het overzicht, dat nu leeg is.
      expect(find.text('Nog geen aankopen'), findsOneWidget);

      // Standaardherinnering staat weer op de standaardwaarde.
      await _openSettings(tester);
      expect(find.text('1 maand vóór de garantie-einddatum'), findsOneWidget);
    });

    testWidgets('annuleren laat alles staan', (tester) async {
      await start(tester);

      await tester.tap(find.byKey(const Key('settings.deleteAll')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuleren'));
      await tester.pumpAndSettle();

      expect(products.all, hasLength(1));
      expect(fileStore.stored, hasLength(1));
      expect(notifications.cancelAllCalls, 0);
    });
  });

  testWidgets('versienummer staat bij "Over GarantieBewaker"', (tester) async {
    await start(tester);
    expect(find.text('Versie 0.1.0 (1)'), findsOneWidget);
  });
}
