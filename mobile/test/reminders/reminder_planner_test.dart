import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/products/domain/product.dart';
import 'package:garantiebewaker/features/reminders/domain/reminder_planner.dart';

import '../helpers/fixtures.dart';

void main() {
  // testNow = 19 oktober 2026, 10:00.
  List<PlannedReminder> plan(List<Product> products) =>
      ReminderPlanner.plan(products, testNow);

  test('actieve herinnering wordt om 9:00 op de datum ingepland', () {
    final result = plan([
      makeProduct(
        name: 'Koelkast',
        reminderEnabled: true,
        reminderDate: DateTime(2027, 3, 1),
        warrantyEndDate: DateTime(2027, 4, 1),
      ),
    ]);

    expect(result, [
      PlannedReminder(
        notificationId: ReminderPlanner.notificationIdFor('p1'),
        productId: 'p1',
        productName: 'Koelkast',
        triggerAt: DateTime(2027, 3, 1, 9),
        warrantyEndDate: DateTime(2027, 4, 1),
      ),
    ]);
  });

  test('uitgezette, lege en verlopen herinneringen worden overgeslagen', () {
    final result = plan([
      makeProduct(id: 'uit', reminderDate: DateTime(2027, 1, 1)),
      makeProduct(id: 'leeg', reminderEnabled: true),
      makeProduct(
        id: 'gisteren',
        reminderEnabled: true,
        reminderDate: DateTime(2026, 10, 18),
      ),
      // Vandaag 9:00 is al voorbij (het is 10:00).
      makeProduct(
        id: 'vandaag',
        reminderEnabled: true,
        reminderDate: DateTime(2026, 10, 19),
      ),
      makeProduct(
        id: 'morgen',
        reminderEnabled: true,
        reminderDate: DateTime(2026, 10, 20),
      ),
    ]);

    expect(result.map((r) => r.productId), ['morgen']);
  });

  test('vandaag vóór 9:00 wordt nog ingepland', () {
    final result = ReminderPlanner.plan([
      makeProduct(reminderEnabled: true, reminderDate: DateTime(2026, 10, 19)),
    ], DateTime(2026, 10, 19, 8, 30));
    expect(result.single.triggerAt, DateTime(2026, 10, 19, 9));
  });

  test('eerstvolgende eerst en maximaal ${ReminderPlanner.maxScheduled}', () {
    final products = [
      for (var i = 0; i < 60; i++)
        makeProduct(
          id: 'p$i',
          reminderEnabled: true,
          reminderDate: DateTime(2027, 1, 1).add(Duration(days: 59 - i)),
        ),
    ];

    final result = plan(products);

    expect(result, hasLength(ReminderPlanner.maxScheduled));
    expect(result.first.productId, 'p59');
    expect(result.first.triggerAt, DateTime(2027, 1, 1, 9));
    for (var i = 1; i < result.length; i++) {
      expect(result[i].triggerAt.isAfter(result[i - 1].triggerAt), isTrue);
    }
  });

  test('meldingsnummer is vast, positief en nooit dat van de testmelding', () {
    final a = ReminderPlanner.notificationIdFor(
      '3f6c2a10-5b7e-4c1d-9a8b-0e2f4d6c8a1b',
    );
    expect(
      ReminderPlanner.notificationIdFor('3f6c2a10-5b7e-4c1d-9a8b-0e2f4d6c8a1b'),
      a,
    );
    expect(a, greaterThan(0));
    expect(a, lessThanOrEqualTo(0x7fffffff));

    final ids = {
      for (var i = 0; i < 1000; i++) ReminderPlanner.notificationIdFor('id-$i'),
    };
    expect(ids, hasLength(1000));
    expect(ids, isNot(contains(ReminderPlanner.testNotificationId)));
  });
}
