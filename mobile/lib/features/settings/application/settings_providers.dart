import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../l10n/app_strings.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SqfliteSettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Keuzes voor de standaardherinnering: aantal dagen vóór de
/// garantie-einddatum.
enum ReminderLead {
  oneWeek(7),
  twoWeeks(14),
  oneMonth(30),
  twoMonths(60),
  threeMonths(90);

  const ReminderLead(this.days);

  final int days;

  /// Naam in de taal van de app, bijv. "1 maand".
  String get label => switch (this) {
    oneWeek => S.current.leadOneWeek,
    twoWeeks => S.current.leadTwoWeeks,
    oneMonth => S.current.leadOneMonth,
    twoMonths => S.current.leadTwoMonths,
    threeMonths => S.current.leadThreeMonths,
  };

  static const standard = ReminderLead.oneMonth;

  String get description => S.current.leadDescription(label);

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
