import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/app/app.dart';

Future<void> _startApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: GarantieBewakerApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('start op het dashboard met een lege toestand', (tester) async {
    await _startApp(tester);

    expect(find.text('GarantieBewaker'), findsOneWidget);
    expect(find.text('Nog geen aankopen'), findsOneWidget);
    expect(find.text('Aankoop toevoegen'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('navigeert via de onderste balk naar Producten en Instellingen', (
    tester,
  ) async {
    await _startApp(tester);

    await tester.tap(find.text('Producten'));
    await tester.pumpAndSettle();
    expect(find.text('Geen producten'), findsOneWidget);

    await tester.tap(find.text('Instellingen'));
    await tester.pumpAndSettle();
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Alle lokale gegevens verwijderen'), findsOneWidget);

    await tester.tap(find.text('Overzicht'));
    await tester.pumpAndSettle();
    expect(find.text('Nog geen aankopen'), findsOneWidget);
  });

  testWidgets('Aankoop toevoegen toont drie opties zonder navigatiebalk', (
    tester,
  ) async {
    await _startApp(tester);

    await tester.tap(find.text('Aankoop toevoegen'));
    await tester.pumpAndSettle();

    expect(find.text('Hoe wil je je aankoop toevoegen?'), findsOneWidget);
    expect(find.text('Kassabon scannen'), findsOneWidget);
    expect(find.text('PDF of afbeelding importeren'), findsOneWidget);
    expect(find.text('Handmatig invoeren'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('nog niet gebouwde functies melden dat eerlijk', (tester) async {
    await _startApp(tester);

    await tester.tap(find.text('Aankoop toevoegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Handmatig invoeren'));
    await tester.pump();

    expect(find.text('Deze functie is nog in ontwikkeling.'), findsOneWidget);
  });

  testWidgets('privacyinformatie opent en sluit', (tester) async {
    await _startApp(tester);

    await tester.tap(find.text('Instellingen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('geen toegang tot je mailbox'), findsOneWidget);

    await tester.tap(find.text('Sluiten'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
