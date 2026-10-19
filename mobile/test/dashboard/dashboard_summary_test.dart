import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/dashboard/application/dashboard_summary.dart';

import '../helpers/fixtures.dart';

void main() {
  test('lege lijst', () {
    final summary = DashboardSummary.from(const [], testNow);
    expect(summary.totalProducts, 0);
    expect(summary.upcoming, isEmpty);
    expect(summary.recent, isEmpty);
  });

  test('binnenkort: alleen datums vanaf vandaag tot en met 30 dagen', () {
    final products = [
      makeProduct(
        id: 'vandaag',
        reminderEnabled: true,
        reminderDate: DateTime(2026, 10, 19),
      ),
      makeProduct(
        id: 'over30',
        reminderEnabled: true,
        reminderDate: DateTime(2026, 11, 18),
      ),
      makeProduct(
        id: 'over31',
        reminderEnabled: true,
        reminderDate: DateTime(2026, 11, 19),
      ),
      makeProduct(
        id: 'gisteren',
        reminderEnabled: true,
        reminderDate: DateTime(2026, 10, 18),
      ),
      makeProduct(
        id: 'uitgeschakeld',
        reminderEnabled: false,
        reminderDate: DateTime(2026, 10, 25),
      ),
    ];
    final summary = DashboardSummary.from(products, testNow);
    expect(summary.upcoming.map((u) => u.product.id), ['vandaag', 'over30']);
  });

  test('garantie-einddatum telt ook mee, per product de eerstvolgende', () {
    final products = [
      makeProduct(
        id: 'beide',
        warrantyEndDate: DateTime(2026, 11, 10),
        reminderEnabled: true,
        reminderDate: DateTime(2026, 10, 27),
      ),
      makeProduct(id: 'garantie', warrantyEndDate: DateTime(2026, 10, 21)),
    ];
    final upcoming = DashboardSummary.from(products, testNow).upcoming;

    expect(upcoming.map((u) => u.product.id), ['garantie', 'beide']);
    expect(upcoming[0].kind, UpcomingKind.warrantyEnd);
    expect(upcoming[1].kind, UpcomingKind.reminder);
    expect(upcoming[1].date, DateTime(2026, 10, 27));
  });

  test('recent: nieuwste eerst, maximaal 5', () {
    final products = [
      for (var i = 0; i < 7; i++)
        makeProduct(id: 'p$i', createdAt: DateTime.utc(2026, 10, 1 + i)),
    ];
    final summary = DashboardSummary.from(products, testNow);
    expect(summary.totalProducts, 7);
    expect(summary.recent.map((p) => p.id), ['p6', 'p5', 'p4', 'p3', 'p2']);
  });
}
