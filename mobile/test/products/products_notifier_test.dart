import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/documents/application/document_service.dart';
import 'package:garantiebewaker/features/products/application/product_providers.dart';
import 'package:garantiebewaker/features/reminders/application/reminder_service.dart';
import 'package:garantiebewaker/features/settings/application/settings_providers.dart';

import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/reminder_fakes.dart';

void main() {
  late InMemoryProductRepository repo;
  late InMemoryDocumentRepository documents;
  late InMemoryDocumentFileStore fileStore;
  late ProviderContainer container;

  setUp(() {
    repo = InMemoryProductRepository();
    documents = InMemoryDocumentRepository();
    fileStore = InMemoryDocumentFileStore();
    repo.onDelete = documents.removeForProduct;
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(repo),
        documentRepositoryProvider.overrideWithValue(documents),
        documentFileStoreProvider.overrideWithValue(fileStore),
        settingsRepositoryProvider.overrideWithValue(
          InMemorySettingsRepository(),
        ),
        reminderNotificationsProvider.overrideWithValue(
          FakeReminderNotifications(),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test('laadt producten uit de repository', () async {
    await repo.save(makeProduct());
    expect(await container.read(productsProvider.future), hasLength(1));
  });

  test('opslaan werkt de lijst en productByIdProvider bij', () async {
    await container.read(productsProvider.future);
    final product = makeProduct();

    await container.read(productsProvider.notifier).save(product);

    expect(container.read(productsProvider).value, [product]);
    expect(container.read(productByIdProvider('p1')).value, product);
    expect(container.read(productByIdProvider('onbekend')).value, isNull);
  });

  test('verwijderen haalt het product uit de lijst', () async {
    await repo.save(makeProduct());
    await container.read(productsProvider.future);

    await container.read(productsProvider.notifier).delete('p1');

    expect(container.read(productsProvider).value, isEmpty);
    expect(repo.all, isEmpty);
  });

  test('verwijderen ruimt ook de documentbestanden op', () async {
    await repo.save(makeProduct());
    await documents.insert(makeDocument());
    fileStore.addStored('documents/d1.pdf', pdfBytes);
    await repo.save(makeProduct(id: 'p2'));
    await documents.insert(makeDocument(id: 'd2', productId: 'p2'));
    fileStore.addStored('documents/d2.pdf', pdfBytes);
    await container.read(productsProvider.future);

    await container.read(productsProvider.notifier).delete('p1');

    expect(documents.all.map((d) => d.id), ['d2']);
    expect(fileStore.stored.keys, ['documents/d2.pdf']);
  });

  test('een opslagfout wordt doorgegeven en de lijst blijft staan', () async {
    await repo.save(makeProduct());
    await container.read(productsProvider.future);
    repo.failNextSaveWith = StateError('schijf vol');

    await expectLater(
      container.read(productsProvider.notifier).save(makeProduct(id: 'p2')),
      throwsStateError,
    );
    expect(container.read(productsProvider).value, hasLength(1));
  });
}
