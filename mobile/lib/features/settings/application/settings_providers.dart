import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SqfliteSettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Keuzes voor de standaardherinnering: aantal dagen vóór de
/// garantie-einddatum.
enum ReminderLead {
  oneWeek(7, '1 week'),
  twoWeeks(14, '2 weken'),
  oneMonth(30, '1 maand'),
  twoMonths(60, '2 maanden'),
  threeMonths(90, '3 maanden');

  const ReminderLead(this.days, this.label);

  final int days;
  final String label;

  static const standard = ReminderLead.oneMonth;

  String get description => '$label vóór de garantie-einddatum';

  static ReminderLead fromDays(int? days) => ReminderLead.values.firstWhere(
    (lead) => lead.days == days,
    orElse: () => standard,
  );
}

/// De standaardherinnering. Wordt voorgesteld als de gebruiker in het
/// formulier een herinnering aanzet.
final reminderLeadProvider =
    AsyncNotifierProvider<ReminderLeadNotifier, ReminderLead>(
      ReminderLeadNotifier.new,
    );

class ReminderLeadNotifier extends AsyncNotifier<ReminderLead> {
  static const _key = 'reminder_lead_days';

  @override
  Future<ReminderLead> build() async {
    final value = await ref.watch(settingsRepositoryProvider).read(_key);
    return ReminderLead.fromDays(int.tryParse(value ?? ''));
  }

  Future<void> set(ReminderLead lead) async {
    await ref.read(settingsRepositoryProvider).write(_key, '${lead.days}');
    state = AsyncData(lead);
  }
}
