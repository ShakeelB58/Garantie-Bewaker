import 'package:garantiebewaker/features/reminders/data/reminder_notifications.dart';
import 'package:garantiebewaker/features/reminders/domain/reminder_planner.dart';
import 'package:garantiebewaker/features/settings/data/settings_repository.dart';

/// Meldingen zonder echt toestel; houdt bij wat er is ingepland.
class FakeReminderNotifications implements ReminderNotifications {
  /// Of meldingen al zijn toegestaan.
  bool enabled = true;

  /// Antwoord van de gebruiker op de toestemmingsvraag.
  bool grantOnRequest = true;

  int permissionRequests = 0;
  int testsScheduled = 0;
  bool initialized = false;
  String? launchedForProduct;
  void Function(String productId)? onOpenProduct;

  /// Elke aanroep van [replaceAll], in volgorde.
  final List<List<PlannedReminder>> replacements = [];

  /// Wat er nu ingepland staat.
  List<PlannedReminder> get scheduled =>
      replacements.isEmpty ? const [] : replacements.last;

  @override
  Future<void> initialize({
    required void Function(String productId) onOpenProduct,
  }) async {
    initialized = true;
    this.onOpenProduct = onOpenProduct;
  }

  @override
  Future<String?> launchProductId() async => launchedForProduct;

  @override
  Future<bool> areEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (grantOnRequest) enabled = true;
    return enabled;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    replacements.add(List.of(reminders));
  }

  @override
  Future<void> scheduleTest() async => testsScheduled++;

  int cancelAllCalls = 0;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    replacements.add(const []);
  }
}

class InMemorySettingsRepository implements SettingsRepository {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> clear() async => values.clear();
}
