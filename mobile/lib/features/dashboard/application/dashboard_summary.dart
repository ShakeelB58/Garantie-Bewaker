import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/dates.dart';
import '../../products/application/product_providers.dart';
import '../../products/domain/product.dart';

/// Soort datum die binnenkort valt.
enum UpcomingKind {
  /// Door de gebruiker ingestelde herinneringsdatum.
  reminder,

  /// Door de gebruiker ingevulde garantie-einddatum.
  warrantyEnd,
}

class UpcomingItem {
  const UpcomingItem({
    required this.product,
    required this.date,
    required this.kind,
  });

  final Product product;
  final DateTime date;
  final UpcomingKind kind;
}

/// Gegevens voor het dashboard.
class DashboardSummary {
  const DashboardSummary({
    required this.totalProducts,
    required this.upcoming,
    required this.recent,
  });

  /// Hoeveel dagen vooruit "binnenkort" kijkt.
  static const upcomingWindowDays = 30;
  static const maxItems = 5;

  final int totalProducts;
  final List<UpcomingItem> upcoming;
  final List<Product> recent;

  factory DashboardSummary.from(List<Product> products, DateTime today) {
    final todayDate = Dates.dateOnly(today);
    final upcoming = <UpcomingItem>[];

    for (final product in products) {
      final candidates = <UpcomingItem>[
        if (product.activeReminderDate != null)
          UpcomingItem(
            product: product,
            date: product.activeReminderDate!,
            kind: UpcomingKind.reminder,
          ),
        if (product.warrantyEndDate != null)
          UpcomingItem(
            product: product,
            date: product.warrantyEndDate!,
            kind: UpcomingKind.warrantyEnd,
          ),
      ];
      // Per product alleen de eerstvolgende datum binnen het venster tonen.
      final inWindow = candidates.where((item) {
        final days = Dates.daysBetween(todayDate, item.date);
        return days >= 0 && days <= upcomingWindowDays;
      }).toList()..sort((a, b) => a.date.compareTo(b.date));
      if (inWindow.isNotEmpty) upcoming.add(inWindow.first);
    }
    upcoming.sort((a, b) => a.date.compareTo(b.date));

    final recent = [...products]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DashboardSummary(
      totalProducts: products.length,
      upcoming: upcoming.take(maxItems).toList(),
      recent: recent.take(maxItems).toList(),
    );
  }
}

final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final today = ref.watch(clockProvider)();
  return ref
      .watch(productsProvider)
      .whenData((products) => DashboardSummary.from(products, today));
});
