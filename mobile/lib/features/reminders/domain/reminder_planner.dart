import '../../products/domain/product.dart';

/// Een herinnering die als melding op het toestel moet worden ingepland.
class PlannedReminder {
  const PlannedReminder({
    required this.notificationId,
    required this.productId,
    required this.productName,
    required this.triggerAt,
    this.warrantyEndDate,
  });

  final int notificationId;
  final String productId;
  final String productName;

  /// Lokale tijd (wandklok) waarop de melding mag verschijnen.
  final DateTime triggerAt;

  final DateTime? warrantyEndDate;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.notificationId == notificationId &&
      other.productId == productId &&
      other.productName == productName &&
      other.triggerAt == triggerAt &&
      other.warrantyEndDate == warrantyEndDate;

  @override
  int get hashCode => Object.hash(
    notificationId,
    productId,
    productName,
    triggerAt,
    warrantyEndDate,
  );

  @override
  String toString() => 'PlannedReminder($productName, $triggerAt)';
}

/// Bepaalt welke meldingen er ingepland moeten worden.
///
/// - Alleen actieve herinneringen met een datum.
/// - Om [hour]:00 lokale tijd op de herinneringsdatum.
/// - Alleen tijdstippen in de toekomst.
/// - De eerstvolgende [maxScheduled]: iOS staat maximaal 64 geplande
///   meldingen per app toe. De rest wordt later ingepland, bij een volgende
///   start van de app.
abstract final class ReminderPlanner {
  static const hour = 9;
  static const maxScheduled = 50;

  /// Gereserveerd voor de testmelding uit de instellingen.
  static const testNotificationId = 0;

  /// Vast meldingsnummer per product (FNV-1a, positief, nooit 0).
  static int notificationIdFor(String productId) {
    var hash = 0x811c9dc5;
    for (final unit in productId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    final id = hash & 0x7fffffff;
    return id == testNotificationId ? 1 : id;
  }

  static List<PlannedReminder> plan(List<Product> products, DateTime now) {
    final planned = <PlannedReminder>[];
    for (final product in products) {
      final date = product.activeReminderDate;
      if (date == null) continue;
      final triggerAt = DateTime(date.year, date.month, date.day, hour);
      if (!triggerAt.isAfter(now)) continue;
      planned.add(
        PlannedReminder(
          notificationId: notificationIdFor(product.id),
          productId: product.id,
          productName: product.name,
          triggerAt: triggerAt,
          warrantyEndDate: product.warrantyEndDate,
        ),
      );
    }
    planned.sort((a, b) => a.triggerAt.compareTo(b.triggerAt));
    return planned.length > maxScheduled
        ? planned.sublist(0, maxScheduled)
        : planned;
  }
}
