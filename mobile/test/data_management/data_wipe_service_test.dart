import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/data_management/application/data_wipe_service.dart';

import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/reminder_fakes.dart';

class _FailingNotifications extends FakeReminderNotifications {
  @override
  Future<void> cancelAll() => Future.error(StateError('kapot'));
}

void main() {
  late InMemoryProductRepository products;
  late InMemorySettingsRepository settings;
  late InMemoryDocumentFileStore fileStore;
  late FakeDocumentPicker picker;

  setUp(() async {
    products = InMemoryProductRepository([
      makeProduct(),
      makeProduct(id: 'p2', name: 'Tv'),
    ]);
    settings = InMemorySettingsRepository()
      ..values['reminder_lead_days'] = '14';
    fileStore = InMemoryDocumentFileStore()
      ..addStored('documents/d1.pdf', pdfBytes)
      ..addStored('documents/d2.jpg', jpegBytes);
    picker = FakeDocumentPicker();
  });

  DataWipeService service(FakeReminderNotifications notifications) =>
      DataWipeService(
        products: products,
        settings: settings,
        fileStore: fileStore,
        notifications: notifications,
        picker: picker,
      );

  test('verwijdert producten, voorkeuren, bestanden en meldingen', () async {
    final notifications = FakeReminderNotifications();

    await service(notifications).wipeAll();

    expect(products.all, isEmpty);
    expect(settings.values, isEmpty);
    expect(fileStore.stored, isEmpty);
    expect(notifications.cancelAllCalls, 1);
    expect(picker.temporaryFilesCleared, 1);
  });

  test('een fout bij meldingen houdt de rest niet tegen', () async {
    await service(_FailingNotifications()).wipeAll();

    expect(products.all, isEmpty);
    expect(fileStore.stored, isEmpty);
    expect(picker.temporaryFilesCleared, 1);
  });
}
