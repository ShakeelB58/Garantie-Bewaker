import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/data_management/application/backup_status.dart';
import 'package:garantiebewaker/features/data_management/application/export_service.dart';
import 'package:garantiebewaker/features/data_management/application/restore_service.dart';
import 'package:garantiebewaker/features/data_management/domain/backup_manifest.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';
import 'package:garantiebewaker/features/products/domain/product_category.dart';

import '../helpers/data_management_fakes.dart';
import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/reminder_fakes.dart';
import '../helpers/test_app.dart';

/// Een volledige export van twee producten met drie documenten.
Future<Uint8List> _makeExport() async {
  final products = InMemoryProductRepository();
  final documents = InMemoryDocumentRepository();
  final files = InMemoryDocumentFileStore();
  await products.save(
    makeProduct(
      name: 'Wasmachine',
      brand: 'Bosch',
      modelNumber: 'WAN28297NL',
      serialNumber: 'FD9912-001234',
      warrantyEndDate: DateTime(2028, 9, 30),
      reminderEnabled: true,
      reminderDate: DateTime(2028, 8, 30),
    ),
  );
  await products.save(
    makeProduct(
      id: 'p2',
      name: 'Telefoon',
      category: ProductCategory.phoneTablet,
      currency: 'GBP',
      purchasePriceMinor: null,
    ),
  );
  final factuur = makeDocument();
  final bon = makeDocument(
    id: 'd2',
    type: DocumentType.receipt,
    format: DocumentFormat.jpeg,
    originalFilename: null,
  );
  final telefoon = makeDocument(id: 'd3', productId: 'p2');
  for (final d in [factuur, bon, telefoon]) {
    await documents.insert(d);
  }
  files
    ..addStored(factuur.filePath, pdfBytes)
    ..addStored(bon.filePath, jpegBytes)
    ..addStored(telefoon.filePath, pdfBytes);
  final export = await ExportService(
    products: products,
    documents: documents,
    fileStore: files,
    clock: () => testNow,
  ).build();
  return export.bytes;
}

Uint8List _zip(Map<String, List<int>> files) {
  final archive = Archive();
  files.forEach(
    (name, bytes) => archive.addFile(ArchiveFile(name, bytes.length, bytes)),
  );
  return ZipEncoder().encodeBytes(archive);
}

/// Past het backupbestand in een export aan.
Uint8List _withManifest(
  Uint8List zip,
  void Function(Map<String, dynamic> data) change,
) {
  final files = {
    for (final f in ZipDecoder().decodeBytes(zip))
      if (f.isFile) f.name: f.readBytes()!.toList(),
  };
  final data =
      jsonDecode(utf8.decode(files[BackupManifest.fileName]!))
          as Map<String, dynamic>;
  change(data);
  files[BackupManifest.fileName] = utf8.encode(jsonEncode(data));
  return _zip(files);
}

void main() {
  late InMemoryProductRepository products;
  late InMemoryDocumentRepository documents;
  late InMemoryDocumentFileStore files;
  late RestoreService service;
  var nextId = 0;

  setUp(() {
    products = InMemoryProductRepository();
    documents = InMemoryDocumentRepository();
    files = InMemoryDocumentFileStore();
    service = RestoreService(
      products: products,
      documents: documents,
      fileStore: files,
      newId: () => 'nieuw-${nextId++}',
    );
  });

  Future<BackupProblem?> problemOf(Uint8List bytes) async {
    try {
      await service.inspect(bytes);
      return null;
    } on BackupFormatException catch (e) {
      return e.problem;
    }
  }

  group('terugzetten', () {
    test('alles komt exact terug op een lege telefoon', () async {
      final zip = await _makeExport();

      final plan = await service.inspect(zip);
      expect(plan.productCount, 2);
      expect(plan.documentCount, 3);
      expect(plan.skipped, 0);

      final result = await service.restore(plan);
      expect(result.products, 2);
      expect(result.documents, 3);

      final wasmachine = await products.getById('p1');
      expect(
        wasmachine,
        makeProduct(
          name: 'Wasmachine',
          brand: 'Bosch',
          modelNumber: 'WAN28297NL',
          serialNumber: 'FD9912-001234',
          warrantyEndDate: DateTime(2028, 9, 30),
          reminderEnabled: true,
          reminderDate: DateTime(2028, 8, 30),
        ),
      );
      final telefoon = await products.getById('p2');
      expect(telefoon!.currency, 'GBP');
      expect(telefoon.purchasePriceMinor, isNull);

      final docs = await documents.getForProduct('p1');
      expect(docs.map((d) => d.id), containsAll(['d1', 'd2']));
      final bon = docs.firstWhere((d) => d.id == 'd2');
      expect(bon.type, DocumentType.receipt);
      expect(bon.format, DocumentFormat.jpeg);
      expect(files.stored[bon.filePath], jpegBytes);
      expect(files.stored['documents/d3.pdf'], pdfBytes);
    });

    test('wat al in de app staat wordt overgeslagen, geen dubbelen', () async {
      final zip = await _makeExport();
      await products.save(makeProduct(name: 'Wasmachine (al aanwezig)'));

      final plan = await service.inspect(zip);
      expect(plan.skipped, 1);
      expect(plan.productCount, 2);
      expect(plan.documentCount, 1);
      await service.restore(plan);

      expect(await products.getAll(), hasLength(2));
      expect((await products.getById('p1'))!.name, 'Wasmachine (al aanwezig)');
      expect(await documents.getForProduct('p1'), isEmpty);

      // Nog een keer: niets nieuws meer.
      expect((await service.inspect(zip)).hasNothingNew, isTrue);
    });

    test('schrijffout: het product wordt helemaal opgeruimd', () async {
      final zip = await _makeExport();
      final plan = await service.inspect(zip);
      files.failWrites = true;

      await expectLater(service.restore(plan), throwsA(anything));
      expect(await products.getAll(), isEmpty);
      expect(await documents.getAll(), isEmpty);
      expect(files.stored, isEmpty);
    });
  });

  group('verkeerde of kapotte bestanden', () {
    test('geen ZIP', () async {
      expect(
        await problemOf(Uint8List.fromList(utf8.encode('hallo'))),
        BackupProblem.notABackup,
      );
    });

    test('ZIP zonder backupbestand', () async {
      expect(
        await problemOf(_zip({'foto.jpg': jpegBytes})),
        BackupProblem.notABackup,
      );
    });

    test('export van een oudere versie (alleen CSV)', () async {
      expect(
        await problemOf(_zip({'producten.csv': utf8.encode('Naam;Merk')})),
        BackupProblem.oldExport,
      );
    });

    test('gemaakt met een nieuwere versie', () async {
      final zip = _withManifest(await _makeExport(), (d) => d['version'] = 99);
      expect(await problemOf(zip), BackupProblem.newerVersion);
    });

    test('verwijzing naar een bestand dat ontbreekt of buiten de ZIP ligt', () async {
      final zip = _withManifest(await _makeExport(), (d) {
        final product = (d['products'] as List).first as Map<String, dynamic>;
        final doc = (product['documents'] as List).first as Map<String, dynamic>;
        doc['file'] = '../../geheim.pdf';
      });
      expect(await problemOf(zip), BackupProblem.damaged);
      expect(files.stored, isEmpty);
    });

    test('bestand is geen PDF terwijl dat wel zo staat', () async {
      final export = await _makeExport();
      final names = {
        for (final f in ZipDecoder().decodeBytes(export))
          if (f.isFile) f.name: f.readBytes()!.toList(),
      };
      final pdfName = names.keys.firstWhere((n) => n.endsWith('.pdf'));
      names[pdfName] = textBytes;
      expect(await problemOf(_zip(names)), BackupProblem.damaged);
    });

    test('ongeldige id of datum', () async {
      var zip = _withManifest(await _makeExport(), (d) {
        ((d['products'] as List).first as Map<String, dynamic>)['id'] = '../x';
      });
      expect(await problemOf(zip), BackupProblem.damaged);
      zip = _withManifest(await _makeExport(), (d) {
        ((d['products'] as List).first
                as Map<String, dynamic>)['purchaseDate'] =
            'gisteren';
      });
      expect(await problemOf(zip), BackupProblem.damaged);
    });
  });

  group('herinnering op Home', () {
    final now = DateTime.utc(2026, 10, 19, 8);
    final old = DateTime.utc(2026, 9, 1);

    test('pas na een week, daarna elke maand', () {
      expect(
        BackupReminder.isDue(
          now: now,
          oldestProductCreatedAt: DateTime.utc(2026, 10, 15),
          lastBackup: null,
          snoozedUntil: null,
        ),
        isFalse,
      );
      expect(
        BackupReminder.isDue(
          now: now,
          oldestProductCreatedAt: old,
          lastBackup: null,
          snoozedUntil: null,
        ),
        isTrue,
      );
      expect(
        BackupReminder.isDue(
          now: now,
          oldestProductCreatedAt: old,
          lastBackup: DateTime.utc(2026, 10, 1),
          snoozedUntil: null,
        ),
        isFalse,
      );
      expect(
        BackupReminder.isDue(
          now: now,
          oldestProductCreatedAt: old,
          lastBackup: DateTime.utc(2026, 9, 1),
          snoozedUntil: null,
        ),
        isTrue,
      );
      expect(
        BackupReminder.isDue(
          now: now,
          oldestProductCreatedAt: old,
          lastBackup: null,
          snoozedUntil: DateTime.utc(2026, 11, 1),
        ),
        isFalse,
      );
      expect(
        BackupReminder.isDue(
          now: now,
          oldestProductCreatedAt: null,
          lastBackup: null,
          snoozedUntil: null,
        ),
        isFalse,
      );
    });
  });

  group('schermen', () {
    testWidgets('herstellen via Instellingen', (tester) async {
      final picker = FakeBackupFilePicker()..bytes = await _makeExport();
      final notifications = FakeReminderNotifications();
      final repo = await pumpApp(
        tester,
        backupPicker: picker,
        notifications: notifications,
      );
      await tester.tap(find.byKey(const Key('nav.settings')));
      await tester.pumpAndSettle();
      expect(find.text('Gegevens herstellen'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings.restore')));
      await tester.pumpAndSettle();
      expect(
        find.text('2 producten en 3 documenten gevonden.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('restore.confirm')));
      await tester.pumpAndSettle();

      expect(
        find.text('Teruggezet: 2 producten en 3 documenten.'),
        findsOneWidget,
      );
      expect(await repo.getAll(), hasLength(2));
    });

    testWidgets('verkeerd bestand: duidelijke melding, niets veranderd', (
      tester,
    ) async {
      final picker = FakeBackupFilePicker()
        ..bytes = _zip({'producten.csv': utf8.encode('Naam')});
      final repo = await pumpApp(tester, backupPicker: picker);
      await tester.tap(find.byKey(const Key('nav.settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.restore')));
      await tester.pumpAndSettle();

      expect(find.textContaining('oudere versie van Bonvrij'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(await repo.getAll(), isEmpty);
    });

    testWidgets('welkomstscherm: "Ik heb een reservekopie"', (tester) async {
      final picker = FakeBackupFilePicker()..bytes = await _makeExport();
      final settings = InMemorySettingsRepository();
      await pumpApp(
        tester,
        showWelcome: true,
        settings: settings,
        backupPicker: picker,
      );
      await tester.tap(find.byKey(const Key('welcome.restore')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore.confirm')));
      await tester.pumpAndSettle();

      expect(settings.values['onboarding_done'], 'true');
      expect(find.text('Wasmachine'), findsOneWidget);
      expect(find.text('Telefoon'), findsOneWidget);
    });

    testWidgets('herinneringskaart op Home: Later en Nu maken', (
      tester,
    ) async {
      final settings = InMemorySettingsRepository();
      final saver = FakeExportSaver();
      await pumpApp(
        tester,
        repository: InMemoryProductRepository([makeProduct()]),
        settings: settings,
        exportSaver: saver,
        recentBackup: false,
      );
      final card = find.byKey(const Key('dashboard.backupReminder'));
      expect(card, findsOneWidget);

      await tester.tap(find.byKey(const Key('backupReminder.later')));
      await tester.pumpAndSettle();
      expect(card, findsNothing);
      expect(settings.values['backup_reminder_snoozed_until'], isNotNull);

      // Snooze weg: kaart terug; na een export verdwijnt hij.
      settings.values.remove('backup_reminder_snoozed_until');
      await tester.tap(find.byKey(const Key('nav.settings')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nog geen reservekopie gemaakt'), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings.export')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('export.confirm')));
      await tester.pumpAndSettle();
      expect(saver.bytes, isNotNull);
      expect(find.textContaining('Laatste reservekopie: 19 okt 2026'), findsOneWidget);
      expect(settings.values['last_backup_at'], isNotNull);
    });
  });
}
