import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/reminder_fakes.dart';
import '../helpers/test_app.dart';

Finder _field(String key) => find.byKey(Key('productForm.$key'));

Future<void> _editProduct(WidgetTester tester, String name) async {
  await tester.tap(find.text('Producten'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Bewerken'));
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Instellingen'));
  await tester.pumpAndSettle();
}

void main() {
  late FakeReminderNotifications notifications;
  late InMemorySettingsRepository settings;

  setUp(() {
    notifications = FakeReminderNotifications()..enabled = false;
    settings = InMemorySettingsRepository();
  });

  group('herinnering in het formulier', () {
    testWidgets(
      'aanzetten vraagt toestemming en gebruikt de standaardherinnering',
      (tester) async {
        settings.values['reminder_lead_days'] = '14';
        final repo = await pumpApp(
          tester,
          repository: InMemoryProductRepository([
            makeProduct(
              name: 'Koelkast',
              warrantyEndDate: DateTime(2027, 10, 19),
            ),
          ]),
          notifications: notifications,
          settings: settings,
        );
        await _editProduct(tester, 'Koelkast');

        await tester.ensureVisible(_field('reminderEnabled'));
        await tester.tap(_field('reminderEnabled'));
        await tester.pumpAndSettle();

        expect(notifications.permissionRequests, 1);
        // 2 weken vóór 19 oktober 2027.
        expect(find.text('5 oktober 2027'), findsOneWidget);

        await tester.ensureVisible(_field('save'));
        await tester.tap(_field('save'));
        await tester.pumpAndSettle();

        expect(repo.all.single.reminderDate, DateTime(2027, 10, 5));
        expect(
          notifications.scheduled.single.triggerAt,
          DateTime(2027, 10, 5, 9),
        );
      },
    );

    testWidgets('zonder toestemming: uitleg, herinnering blijft bewaard', (
      tester,
    ) async {
      notifications.grantOnRequest = false;
      final repo = await pumpApp(
        tester,
        repository: InMemoryProductRepository([
          makeProduct(
            name: 'Koelkast',
            warrantyEndDate: DateTime(2027, 10, 19),
          ),
        ]),
        notifications: notifications,
        settings: settings,
      );
      await _editProduct(tester, 'Koelkast');

      await tester.ensureVisible(_field('reminderEnabled'));
      await tester.tap(_field('reminderEnabled'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Meldingen staan uit voor Bonvrij'),
        findsOneWidget,
      );
      // Standaard 1 maand vóór de einddatum.
      expect(find.text('19 september 2027'), findsOneWidget);

      await tester.ensureVisible(_field('save'));
      await tester.tap(_field('save'));
      await tester.pumpAndSettle();
      expect(repo.all.single.reminderEnabled, isTrue);
    });

    testWidgets('uitzetten vraagt geen toestemming', (tester) async {
      await pumpApp(
        tester,
        repository: InMemoryProductRepository([
          makeProduct(
            name: 'Koelkast',
            reminderEnabled: true,
            reminderDate: DateTime(2027, 1, 5),
          ),
        ]),
        notifications: notifications,
        settings: settings,
      );
      await _editProduct(tester, 'Koelkast');

      await tester.ensureVisible(_field('reminderEnabled'));
      await tester.tap(_field('reminderEnabled'));
      await tester.pumpAndSettle();

      expect(notifications.permissionRequests, 0);
    });
  });

  group('instellingen', () {
    testWidgets('standaardherinnering kiezen wordt bewaard', (tester) async {
      await pumpApp(tester, notifications: notifications, settings: settings);
      await _openSettings(tester);

      expect(find.text('1 maand vóór de garantie-einddatum'), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings.reminderLead')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.lead.60')));
      await tester.pumpAndSettle();

      expect(find.text('2 maanden vóór de garantie-einddatum'), findsOneWidget);
      expect(settings.values['reminder_lead_days'], '60');
    });

    testWidgets('meldingen toestaan vanuit de instellingen', (tester) async {
      await pumpApp(tester, notifications: notifications, settings: settings);
      await _openSettings(tester);

      expect(find.text('Uit. Tik om meldingen toe te staan.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings.notifications')));
      await tester.pumpAndSettle();

      expect(notifications.permissionRequests, 1);
      expect(find.text('Aan'), findsOneWidget);
    });

    testWidgets('testmelding wordt ingepland', (tester) async {
      notifications.enabled = true;
      await pumpApp(tester, notifications: notifications, settings: settings);
      await _openSettings(tester);

      await tester.tap(find.byKey(const Key('settings.testNotification')));
      await tester.pumpAndSettle();

      expect(notifications.testsScheduled, 1);
      expect(
        find.textContaining(
          'Over ongeveer een minuut krijg je een testmelding',
        ),
        findsOneWidget,
      );
    });

    testWidgets('testmelding zonder toestemming wordt niet ingepland', (
      tester,
    ) async {
      notifications.grantOnRequest = false;
      await pumpApp(tester, notifications: notifications, settings: settings);
      await _openSettings(tester);

      await tester.tap(find.byKey(const Key('settings.testNotification')));
      await tester.pumpAndSettle();

      expect(notifications.testsScheduled, 0);
      expect(find.textContaining('Meldingen staan uit.'), findsOneWidget);
    });
  });

  group('bij het starten van de app', () {
    testWidgets('herinneringen worden opnieuw ingepland', (tester) async {
      await pumpApp(
        tester,
        repository: InMemoryProductRepository([
          makeProduct(
            name: 'Koelkast',
            reminderEnabled: true,
            reminderDate: DateTime(2027, 1, 5),
          ),
        ]),
        notifications: notifications,
        settings: settings,
      );

      expect(notifications.initialized, isTrue);
      expect(notifications.scheduled.single.productName, 'Koelkast');
      // Bij het starten wordt geen toestemming gevraagd.
      expect(notifications.permissionRequests, 0);
    });

    testWidgets('tikken op een melding opent het product', (tester) async {
      notifications.launchedForProduct = 'p1';
      await pumpApp(
        tester,
        repository: InMemoryProductRepository([makeProduct(name: 'Koelkast')]),
        notifications: notifications,
        settings: settings,
      );

      expect(find.byTooltip('Bewerken'), findsOneWidget);

      // Ook als de app al open is.
      await tapBack(tester);
      expect(find.byTooltip('Bewerken'), findsNothing);
      notifications.onOpenProduct!('p1');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Bewerken'), findsOneWidget);
    });
  });
}
