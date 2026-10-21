import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/utils/dates.dart';
import '../domain/reminder_planner.dart';

/// Lokale meldingen op het toestel. Er is geen pushserver: meldingen worden
/// door het besturingssysteem zelf op het geplande moment getoond.
abstract interface class ReminderNotifications {
  /// Moet één keer bij het starten van de app worden aangeroepen.
  /// [onOpenProduct] wordt aangeroepen als de gebruiker op een melding tikt.
  Future<void> initialize({
    required void Function(String productId) onOpenProduct,
  });

  /// Product van de melding waarmee de app werd gestart, of `null`.
  Future<String?> launchProductId();

  /// Of de app meldingen mag tonen.
  Future<bool> areEnabled();

  /// Vraagt de gebruiker om toestemming (alleen de eerste keer zichtbaar).
  Future<bool> requestPermission();

  /// Vervangt alle geplande herinneringen door [reminders].
  Future<void> replaceAll(List<PlannedReminder> reminders);

  /// Plant een testmelding over ongeveer een minuut.
  Future<void> scheduleTest();

  /// Verwijdert alle geplande én al getoonde meldingen van de app.
  Future<void> cancelAll();
}

/// [ReminderNotifications] met `flutter_local_notifications`.
class LocalReminderNotifications implements ReminderNotifications {
  LocalReminderNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialized;
  void Function(String productId)? _onOpenProduct;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'herinneringen',
      'Herinneringen',
      channelDescription: 'Herinneringen op door jou ingestelde datums',
      // Op het vergrendelscherm geen productnaam tonen.
      visibility: NotificationVisibility.private,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> initialize({
    required void Function(String productId) onOpenProduct,
  }) {
    _onOpenProduct = onOpenProduct;
    return _ensureInitialized();
  }

  Future<void> _ensureInitialized() => _initialized ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Geen toestemmingsvraag bij het starten; pas als de gebruiker een
          // herinnering instelt.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final productId = response.payload;
          if (productId != null && productId.isNotEmpty) {
            _onOpenProduct?.call(productId);
          }
        },
      )
      .then((_) {});

  @override
  Future<String?> launchProductId() async {
    await _ensureInitialized();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final payload = details.notificationResponse?.payload;
    return payload == null || payload.isEmpty ? null : payload;
  }

  @override
  Future<bool> areEnabled() async {
    await _ensureInitialized();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final options = await ios?.checkPermissions();
    return options?.isEnabled ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    await _ensureInitialized();
    // Alleen geplande meldingen; al getoonde meldingen blijven staan.
    await _plugin.cancelAllPendingNotifications();
    for (final reminder in reminders) {
      final end = reminder.warrantyEndDate;
      await _schedule(
        id: reminder.notificationId,
        at: reminder.triggerAt,
        title: 'Herinnering: ${reminder.productName}',
        body: end == null
            ? 'Je hebt deze herinnering zelf ingesteld. Controleer je '
                  'aankoopbewijs en garantie.'
            : 'Je garantie-einddatum is ${Dates.formatLong(end)}. '
                  'Controleer je aankoopbewijs.',
        payload: reminder.productId,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  @override
  Future<void> scheduleTest() async {
    await _ensureInitialized();
    await _schedule(
      id: ReminderPlanner.testNotificationId,
      at: DateTime.now().add(const Duration(minutes: 1)),
      title: 'Testmelding',
      body: 'Meldingen van Bonvrij werken.',
    );
  }

  Future<void> _schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    String? payload,
  }) {
    // Het tijdstip wordt eerst naar UTC omgerekend met de tijdzoneregels van
    // het toestel (inclusief zomer- en wintertijd op die datum).
    return _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: _details,
      // Niet-exact: geen extra toestemming nodig. Android mag de melding iets
      // later tonen om de batterij te sparen.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );
  }
}
