import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../products/application/product_providers.dart';
import '../../products/data/product_repository.dart';
import '../data/reminder_notifications.dart';
import '../domain/reminder_planner.dart';

/// Lokale meldingen. In tests vervangen door een nepversie.
final reminderNotificationsProvider = Provider<ReminderNotifications>(
  (ref) => LocalReminderNotifications(),
);

final reminderSyncProvider = Provider<ReminderSync>(
  (ref) => ReminderSync(
    notifications: ref.watch(reminderNotificationsProvider),
    repository: ref.watch(productRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Of meldingen zijn toegestaan (voor het instellingenscherm).
final notificationsEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(reminderNotificationsProvider).areEnabled(),
);

/// Houdt de geplande meldingen gelijk aan de herinneringen in de database.
///
/// Er wordt steeds alles opnieuw ingepland. Dat is eenvoudig en robuust: na
/// wijzigen, verwijderen of een herstart klopt de planning altijd.
class ReminderSync {
  ReminderSync({
    required ReminderNotifications notifications,
    required ProductRepository repository,
    required DateTime Function() clock,
  }) : _notifications = notifications,
       _repository = repository,
       _clock = clock;

  final ReminderNotifications _notifications;
  final ProductRepository _repository;
  final DateTime Function() _clock;

  Future<void> sync() async {
    final products = await _repository.getAll();
    await _notifications.replaceAll(ReminderPlanner.plan(products, _clock()));
  }

  /// Zoals [sync], maar een fout bij het inplannen blokkeert nooit het
  /// opslaan of verwijderen van een product.
  Future<void> syncSafely() async {
    try {
      await sync();
    } catch (error) {
      debugPrint('Meldingen inplannen mislukt (${error.runtimeType})');
    }
  }
}
