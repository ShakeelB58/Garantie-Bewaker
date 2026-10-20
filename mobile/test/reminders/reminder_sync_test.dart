import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/storage/storage_providers.dart';
import 'package:garantiebewaker/features/documents/application/document_service.dart';
import 'package:garantiebewaker/features/products/application/product_providers.dart';
import 'package:garantiebewaker/features/reminders/application/reminder_service.dart';
import 'package:garantiebewaker/features/reminders/data/reminder_notifications.dart';
import 'package:garantiebewaker/features/reminders/domain/reminder_planner.dart';

import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/reminder_fakes.dart';

class _BrokenNotifications extends FakeReminderNotifications {
  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) =>
      Future.error(StateError('kapot'));
}

void main() {
  late InMemoryProductRepository repo;
  late FakeReminderNotifications notifications;

  ProviderContainer makeContainer([ReminderNotifications? override]) {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(repo),
        documentRepositoryProvider.overrideWithValue(
          InMemoryDocumentRepository(),
        ),
        documentFileStoreProvider.overrideWithValue(
          InMemoryDocumentFileStore(),
        ),
        reminderNotificationsProvider.overrideWithValue(
          override ?? notifications,
        ),
        clockProvider.overrideWithValue(() => testNow),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    repo = InMemoryProductRepository();
    notifications = FakeReminderNotifications();
  });

  test('opslaan plant de herinnering in', () async {
    final container = makeContainer();
    await container.read(productsProvider.future);

    await container
        .read(productsProvider.notifier)
        .save(
          makeProduct(
            reminderEnabled: true,
            reminderDate: DateTime(2027, 1, 5),
          ),
        );

    expect(notifications.scheduled.single.triggerAt, DateTime(2027, 1, 5, 9));
  });

  test('datum wijzigen vervangt de melding', () async {
    final container = makeContainer();
    await container.read(productsProvider.future);
    final notifier = container.read(productsProvider.notifier);

    await notifier.save(
      makeProduct(reminderEnabled: true, reminderDate: DateTime(2027, 1, 5)),
    );
    await notifier.save(
      makeProduct(reminderEnabled: true, reminderDate: DateTime(2027, 2, 7)),
    );

    expect(notifications.scheduled.single.triggerAt, DateTime(2027, 2, 7, 9));
  });

  test('herinnering uitzetten haalt de melding weg', () async {
    final container = makeContainer();
    await container.read(productsProvider.future);
    final notifier = container.read(productsProvider.notifier);

    await notifier.save(
      makeProduct(reminderEnabled: true, reminderDate: DateTime(2027, 1, 5)),
    );
    await notifier.save(makeProduct(reminderDate: DateTime(2027, 1, 5)));

    expect(notifications.scheduled, isEmpty);
  });

  test('verwijderd product laat geen melding achter', () async {
    await repo.save(
      makeProduct(reminderEnabled: true, reminderDate: DateTime(2027, 1, 5)),
    );
    final container = makeContainer();
    await container.read(productsProvider.future);

    await container.read(productsProvider.notifier).delete('p1');

    expect(notifications.replacements, isNotEmpty);
    expect(notifications.scheduled, isEmpty);
  });

  test('fout bij inplannen blokkeert opslaan niet', () async {
    final container = makeContainer(_BrokenNotifications());
    await container.read(productsProvider.future);

    await container
        .read(productsProvider.notifier)
        .save(
          makeProduct(
            reminderEnabled: true,
            reminderDate: DateTime(2027, 1, 5),
          ),
        );

    expect(repo.all, hasLength(1));
  });
}
