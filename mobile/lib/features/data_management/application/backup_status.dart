import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../products/application/product_providers.dart';
import '../../settings/application/settings_providers.dart';

/// Wanneer de gebruiker voor het laatst een export (reservekopie) heeft
/// bewaard, of `null` als dat nog nooit is gebeurd.
final lastBackupProvider = AsyncNotifierProvider<LastBackupNotifier, DateTime?>(
  LastBackupNotifier.new,
);

class LastBackupNotifier extends AsyncNotifier<DateTime?> {
  static const key = 'last_backup_at';

  @override
  Future<DateTime?> build() async {
    final value = await ref.watch(settingsRepositoryProvider).read(key);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> markDone() async {
    final now = ref.read(clockProvider)().toUtc();
    await ref.read(settingsRepositoryProvider).write(key, now.toIso8601String());
    state = AsyncData(now);
  }
}

/// Tot wanneer de gebruiker de herinnering heeft uitgesteld ("Later").
final backupSnoozeProvider =
    AsyncNotifierProvider<BackupSnoozeNotifier, DateTime?>(
      BackupSnoozeNotifier.new,
    );

class BackupSnoozeNotifier extends AsyncNotifier<DateTime?> {
  static const key = 'backup_reminder_snoozed_until';

  @override
  Future<DateTime?> build() async {
    final value = await ref.watch(settingsRepositoryProvider).read(key);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> snooze() async {
    final until = ref
        .read(clockProvider)()
        .toUtc()
        .add(const Duration(days: BackupReminder.intervalDays));
    await ref
        .read(settingsRepositoryProvider)
        .write(key, until.toIso8601String());
    state = AsyncData(until);
  }
}

/// Wanneer de app op Home vraagt om een reservekopie te maken.
abstract final class BackupReminder {
  /// Eén keer per maand.
  static const intervalDays = 30;

  /// Pas als het oudste product minstens een week in de app staat, zodat
  /// nieuwe gebruikers niet meteen een melding krijgen.
  static const graceDays = 7;

  static bool isDue({
    required DateTime now,
    required DateTime? oldestProductCreatedAt,
    required DateTime? lastBackup,
    required DateTime? snoozedUntil,
  }) {
    if (oldestProductCreatedAt == null) return false;
    if (now.difference(oldestProductCreatedAt).inDays < graceDays) {
      return false;
    }
    if (snoozedUntil != null && now.isBefore(snoozedUntil)) return false;
    if (lastBackup == null) return true;
    return now.difference(lastBackup).inDays >= intervalDays;
  }
}

/// Of de herinneringskaart op Home zichtbaar is.
final backupReminderDueProvider = Provider<bool>((ref) {
  final products = ref.watch(productsProvider).value;
  final last = ref.watch(lastBackupProvider);
  final snooze = ref.watch(backupSnoozeProvider);
  if (products == null || last.isLoading || snooze.isLoading) return false;
  DateTime? oldest;
  for (final product in products) {
    if (oldest == null || product.createdAt.isBefore(oldest)) {
      oldest = product.createdAt;
    }
  }
  return BackupReminder.isDue(
    now: ref.watch(clockProvider)().toUtc(),
    oldestProductCreatedAt: oldest?.toUtc(),
    lastBackup: last.value,
    snoozedUntil: snooze.value,
  );
});
