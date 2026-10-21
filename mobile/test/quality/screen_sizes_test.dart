import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/test_app.dart';

/// Alle hoofdschermen op een klein en een groot toestel, met normale en
/// extra grote tekst. Een tekst of rij die niet past, geeft in Flutter een
/// "overflow"-fout; die laat de test dan mislukken.
void main() {
  const sizes = {
    'klein toestel (iPhone SE 1e generatie)': Size(320, 568),
    'groot toestel (Galaxy S-serie)': Size(412, 915),
  };
  const textScales = {'normale tekst': 1.0, 'grote tekst (200%)': 2.0};

  InMemoryProductRepository products() => InMemoryProductRepository([
    makeProduct(
      name: 'Combimagnetron met heteluchtfunctie en grill, roestvrij staal',
      merchant: 'Voorbeeldwinkel Elektronica en Huishouden',
      purchasePriceMinor: 129999,
      warrantyEndDate: DateTime(2028, 10, 19),
      reminderEnabled: true,
      reminderDate: DateTime(2026, 10, 25),
    ),
    makeProduct(id: 'p2', name: 'Tv', merchant: null),
  ]);

  for (final size in sizes.entries) {
    for (final scale in textScales.entries) {
      group('${size.key}, ${scale.key}', () {
        Future<void> start(WidgetTester tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale.value;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final documents = InMemoryDocumentRepository([makeDocument()]);
          await pumpApp(
            tester,
            repository: products(),
            documents: documents,
            screenSize: size.value,
          );
        }

        testWidgets('overzicht, producten en details', (tester) async {
          await start(tester);
          expect(find.text('Binnenkort'), findsOneWidget);

          await tester.tap(find.text('Producten'));
          await tester.pumpAndSettle();
          await _scrollTo(tester, find.text('Tv'));
          await tester.tap(find.text('Tv'));
          await tester.pumpAndSettle();
          expect(find.byTooltip('Bewerken'), findsOneWidget);

          await tapBack(tester);
          // Terug naar boven: deze kaart staat bovenaan de lijst.
          await tester.drag(_verticalList(), const Offset(0, 5000));
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.textContaining('Combimagnetron').first,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.textContaining('Combimagnetron').first);
          await tester.pumpAndSettle();
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -2000),
          );
          await tester.pumpAndSettle();
        });

        testWidgets('aankoop toevoegen en formulier', (tester) async {
          await start(tester);
          await tester.tap(find.byType(FloatingActionButton).first);
          await tester.pumpAndSettle();
          await _scrollTo(tester, find.text('Handmatig invoeren'));

          await tester.tap(find.text('Handmatig invoeren'));
          await tester.pumpAndSettle();
          expect(find.text('Product toevoegen'), findsOneWidget);
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -3000),
          );
          await tester.pumpAndSettle();
        });

        testWidgets('instellingen en dialogen', (tester) async {
          await start(tester);
          await tester.tap(find.text('Instellingen'));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('settings.reminderLead')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const Key('settings.lead.14')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('settings.lead.14')));
          await tester.pumpAndSettle();

          await _scrollTo(tester, find.byKey(const Key('settings.deleteAll')));
          await tester.tap(find.byKey(const Key('settings.deleteAll')));
          await tester.pumpAndSettle();
          expect(find.text('Alle gegevens verwijderen?'), findsOneWidget);
          await tester.ensureVisible(find.text('Annuleren'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Annuleren'));
          await tester.pumpAndSettle();
        });
      });
    }
  }
}

/// Scrolt in de zichtbare lijst tot [finder] in beeld is.
Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 150,
}) async {
  try {
    await tester.scrollUntilVisible(
      finder,
      delta,
      // De verticale lijst, niet bijv. de horizontale filterknoppen.
      scrollable: _verticalList(),
    );
  } catch (error) {
    final texts = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .join(' | ');
    final scrollables = find.byType(Scrollable).evaluate().length;
    fail(
      'Niet gevonden: $finder ($error). Scrollables: $scrollables. '
      'Zichtbare teksten: $texts',
    );
  }
  await tester.pumpAndSettle();
}

Finder _verticalList() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;
