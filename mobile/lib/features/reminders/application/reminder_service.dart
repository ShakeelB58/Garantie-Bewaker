import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../products/application/product_providers.dart';
import '../../products/data/product_repository.dart';
import '../../settings/application/settings_providers.dart';
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
    enabled: () async =>
        await ref.read(settingsRepositoryProvider).read(remindersEnabledKey) !=
        'false',
  ),
);

/// Instelling: alle herinneringen aan of uit (standaard aan).
const remindersEnabledKey = 'reminders_enabled';

/// Hoofdschakelaar "Herinneringen inschakelen" op het scherm Herinneringen.
final remindersEnabledProvider =
    AsyncNotifierProvider<RemindersEnabledNotifier, bool>(
      RemindersEnabledNotifier.new,
    );

class RemindersEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      await ref.watch(settingsRepositoryProvider).read(remindersEnabledKey) !=
      'false';

  /// Zet alle meldingen aan of uit. De herinneringsdatums per product
  /// blijven bewaard.
  Future<void> set(bool enabled) async {
    await ref
        .read(settingsRepositoryProvider)
        .write(remindersEnabledKey, enabled ? 'true' : 'false');
    state = AsyncData(enabled);
    await ref.read(reminderSyncProvider).syncSafely();
  }
}

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
    Future<bool> Function()? enabled,
  }) : _notifications = notifications,
       _repository = repository,
       _clock = clock,
       _enabled = enabled ?? (() async => true);

  final ReminderNotifications _notifications;
  final ProductRepository _repository;
  final DateTime Function() _clock;
  final Future<bool> Function() _enabled;

  Future<void> sync() async {
    if (!await _enabled()) {
      // Hoofdschakelaar uit: niets ingepland laten.
      await _notifications.replaceAll(const []);
      return;
    }
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
