import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/document_fakes.dart';
import 'helpers/fixtures.dart';
import 'helpers/in_memory_product_repository.dart';
import 'helpers/reminder_fakes.dart';
import 'helpers/test_app.dart';

/// Nieuwe schermen uit het ontwerp: welkom, Home, Documenten, Herinneringen.
void main() {
  testWidgets('welkomstscherm alleen de eerste keer', (tester) async {
    final settings = InMemorySettingsRepository();
    await pumpApp(tester, settings: settings, showWelcome: true);

    expect(find.text('Aan de slag'), findsOneWidget);
    expect(find.text('Nog geen producten'), findsNothing);

    await tester.tap(find.byKey(const Key('welcome.start')));
    await tester.pumpAndSettle();

    expect(find.text('Nog geen producten'), findsOneWidget);
    expect(settings.values['onboarding_done'], 'true');
  });

  testWidgets('Home: begroeting, aantallen en recente aankopen', (
    tester,
  ) async {
    await pumpApp(
      tester,
      repository: InMemoryProductRepository([
        makeProduct(
          name: 'Koelkast',
          reminderEnabled: true,
          reminderDate: DateTime(2026, 11, 1),
        ),
      ]),
    );

    // testNow is 10:00 uur.
    expect(find.text('Goedemorgen,'), findsOneWidget);
    expect(find.text('Je hebt 1 product geregistreerd.'), findsOneWidget);
    expect(find.text('Recent toegevoegd'), findsOneWidget);
    expect(find.text('Binnenkort een herinnering'), findsOneWidget);
  });

  testWidgets('Documenten: alle documenten met productnaam', (tester) async {
    final documents = InMemoryDocumentRepository([
      makeDocument(),
      makeDocument(id: 'd2', productId: 'p2'),
    ]);
    await pumpApp(
      tester,
      repository: InMemoryProductRepository([
        makeProduct(name: 'Wasmachine'),
        makeProduct(id: 'p2', name: 'Tv'),
      ]),
      documents: documents,
    );

    await tester.tap(find.byKey(const Key('nav.documents')));
    await tester.pumpAndSettle();

    expect(find.text('Wasmachine'), findsOneWidget);
    expect(find.text('Tv'), findsOneWidget);
    expect(find.textContaining('Factuur'), findsNWidgets(2));
  });

  group('Herinneringen', () {
    late FakeReminderNotifications notifications;
    late InMemorySettingsRepository settings;

    setUp(() {
      notifications = FakeReminderNotifications();
      settings = InMemorySettingsRepository();
    });

    Future<void> openReminders(WidgetTester tester) async {
      await pumpApp(
        tester,
        repository: InMemoryProductRepository([
          makeProduct(
            name: 'Koelkast',
            reminderEnabled: true,
            reminderDate: DateTime(2026, 11, 1),
          ),
        ]),
        notifications: notifications,
        settings: settings,
      );
      await tester.tap(find.byKey(const Key('dashboard.reminders')));
      await tester.pumpAndSettle();
    }

    testWidgets('komende herinneringen met aantal dagen', (tester) async {
      await openReminders(tester);

      expect(find.text('Komende herinneringen'), findsOneWidget);
      expect(find.text('Koelkast'), findsOneWidget);
      expect(find.textContaining('Over 13 dagen'), findsOneWidget);
    });

    testWidgets('hoofdschakelaar zet alle meldingen uit en weer aan', (
      tester,
    ) async {
      await openReminders(tester);
      expect(notifications.scheduled, hasLength(1));

      await tester.tap(find.byKey(const Key('reminders.enabled')));
      await tester.pumpAndSettle();
      expect(settings.values['reminders_enabled'], 'false');
      expect(notifications.scheduled, isEmpty);
      expect(find.textContaining('Herinneringen staan uit'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reminders.enabled')));
      await tester.pumpAndSettle();
      expect(settings.values['reminders_enabled'], 'true');
      expect(notifications.permissionRequests, 1);
      expect(notifications.scheduled, hasLength(1));
    });
  });
}
