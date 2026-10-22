import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/app/app.dart';
import 'package:garantiebewaker/core/storage/storage_providers.dart';
import 'package:garantiebewaker/features/data_management/application/data_management_providers.dart';
import 'package:garantiebewaker/features/demo/demo_data.dart';
import 'package:garantiebewaker/features/documents/application/document_service.dart';
import 'package:garantiebewaker/features/documents/data/camera_scanner.dart';
import 'package:garantiebewaker/features/documents/presentation/scanner_screen.dart';
import 'package:garantiebewaker/features/products/application/product_providers.dart';
import 'package:garantiebewaker/features/recognition/application/recognition_service.dart';
import 'package:garantiebewaker/features/reminders/application/reminder_service.dart';
import 'package:garantiebewaker/features/settings/application/settings_providers.dart';

import 'data_management_fakes.dart';
import 'document_fakes.dart';
import 'fixtures.dart';
import 'in_memory_product_repository.dart';
import 'recognition_fakes.dart';
import 'reminder_fakes.dart';

/// Start de volledige app met opslag in het geheugen en een vaste klok.
///
/// Geef eigen nepobjecten mee om ze in de test te kunnen inspecteren.
Future<InMemoryProductRepository> pumpApp(
  WidgetTester tester, {
  InMemoryProductRepository? repository,
  InMemoryDocumentRepository? documents,
  InMemoryDocumentFileStore? fileStore,
  FakeDocumentPicker? picker,
  FakeIncomingFileSource? incoming,
  FakeTextRecognizer? recognizer,
  FakePdfPageSource? pdfPages,
  FakeReminderNotifications? notifications,
  InMemorySettingsRepository? settings,
  FakeExportSaver? exportSaver,
  Size screenSize = const Size(800, 1800),
  bool showWelcome = false,
  Widget? scannerPreview,
}) async {
  final settingsRepo = settings ?? InMemorySettingsRepository();
  final documentPicker = picker ?? FakeDocumentPicker();
  // Het welkomstscherm alleen tonen als de test daarom vraagt.
  if (!showWelcome) {
    settingsRepo.values.putIfAbsent('onboarding_done', () => 'true');
  }
  // Standaard een hoog scherm, zodat het hele formulier zichtbaar is.
  tester.view.physicalSize = screenSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final files = fileStore ?? InMemoryDocumentFileStore();
  final repo = repository ?? InMemoryProductRepository();
  final documentRepo = documents ?? InMemoryDocumentRepository();
  // Bootst ON DELETE CASCADE van de echte database na.
  repo.onDelete = documentRepo.removeForProduct;
  var nextId = 0;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(repo),
        documentRepositoryProvider.overrideWithValue(documentRepo),
        documentFileStoreProvider.overrideWithValue(files),
        // Voorbeeldgegevens: "tijdelijke bestanden" in het geheugen.
        demoTempFileWriterProvider.overrideWithValue((name, bytes) async {
          final path = '/tmp/$name';
          files.addSource(path, bytes);
          return path;
        }),
        documentPickerProvider.overrideWithValue(documentPicker),
        // Geen echte camera in tests: de nepkiezer levert de "foto".
        cameraScannerProvider.overrideWithValue(
          PickerCameraScanner(documentPicker),
        ),
        scannerPreviewOverrideProvider.overrideWithValue(scannerPreview),
        incomingFileSourceProvider.overrideWithValue(
          incoming ?? FakeIncomingFileSource(),
        ),
        textRecognizerProvider.overrideWithValue(
          recognizer ?? FakeTextRecognizer(),
        ),
        pdfPageSourceProvider.overrideWithValue(
          pdfPages ?? FakePdfPageSource(),
        ),
        reminderNotificationsProvider.overrideWithValue(
          notifications ?? FakeReminderNotifications(),
        ),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        exportSaverProvider.overrideWithValue(exportSaver ?? FakeExportSaver()),
        appVersionProvider.overrideWith((ref) async => '0.1.0 (1)'),
        clockProvider.overrideWithValue(() => testNow),
        idGeneratorProvider.overrideWithValue(() => 'id-${nextId++}'),
      ],
      child: const BonvrijApp(),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// Tikt op de terugknop in de AppBar.
///
/// `tester.pageBack()` zoekt naar de Engelse tooltip "Back"; deze app is
/// Nederlandstalig, dus zoeken we de tooltip via de lokalisatie op.
Future<void> tapBack(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).last);
  final tooltip = MaterialLocalizations.of(context).backButtonTooltip;
  await tester.tap(find.byTooltip(tooltip).last);
  await tester.pumpAndSettle();
}
