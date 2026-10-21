import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/errors/user_message.dart';
import 'package:garantiebewaker/features/products/domain/product_category.dart';

import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/test_app.dart';

Finder _field(String key) => find.byKey(Key('productForm.$key'));

Future<void> _openNewProductForm(WidgetTester tester) async {
  await tester.tap(find.text('Aankoop toevoegen'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Handmatig invoeren'));
  await tester.pumpAndSettle();
}

Future<void> _openProduct(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('nav.products')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

void main() {
  group('product toevoegen', () {
    testWidgets('handmatig toevoegen toont het product overal', (tester) async {
      final repo = await pumpApp(tester);
      await _openNewProductForm(tester);

      expect(find.text('Product toevoegen'), findsOneWidget);
      // Aankoopdatum staat standaard op vandaag.
      expect(find.text('19 oktober 2026'), findsOneWidget);

      await tester.enterText(_field('name'), 'Wasmachine');
      await tester.enterText(_field('merchant'), 'Coolblue');
      await tester.enterText(_field('price'), '1.299,00');
      await tester.tap(_field('save'));
      await tester.pumpAndSettle();

      // Na opslaan: detailscherm.
      expect(find.text('Product opgeslagen.'), findsOneWidget);
      expect(find.text('Wasmachine'), findsOneWidget);
      expect(find.textContaining('1.299,00'), findsWidgets);

      final saved = repo.all.single;
      expect(saved.name, 'Wasmachine');
      expect(saved.merchant, 'Coolblue');
      expect(saved.purchasePriceMinor, 129900);
      expect(saved.purchaseDate, DateTime(2026, 10, 19));

      // Terug naar het dashboard: product en aantal zichtbaar.
      await tapBack(tester);
      expect(find.text('Nog geen producten'), findsNothing);
      expect(find.text('Je hebt 1 product geregistreerd.'), findsOneWidget);
      expect(find.text('Wasmachine'), findsOneWidget);
    });

    testWidgets('verplichte velden en ongeldig bedrag worden gemeld', (
      tester,
    ) async {
      final repo = await pumpApp(tester);
      await _openNewProductForm(tester);

      await tester.enterText(_field('price'), 'twintig euro');
      await tester.tap(_field('save'));
      await tester.pumpAndSettle();

      expect(find.text('Vul een productnaam in.'), findsOneWidget);
      expect(
        find.text('Vul een geldig bedrag in, bijvoorbeeld 1.299,00.'),
        findsOneWidget,
      );
      expect(find.text('Controleer de gemarkeerde velden.'), findsOneWidget);
      expect(repo.all, isEmpty);

      // Foutmelding verdwijnt zodra het veld wordt aangepast.
      await tester.enterText(_field('name'), 'Tv');
      await tester.pump();
      expect(find.text('Vul een productnaam in.'), findsNothing);
    });

    testWidgets('herinnering aan zonder datum geeft een melding', (
      tester,
    ) async {
      await pumpApp(tester);
      await _openNewProductForm(tester);

      await tester.enterText(_field('name'), 'Laptop');
      await tester.tap(_field('reminderEnabled'));
      await tester.pumpAndSettle();
      expect(_field('reminderDate'), findsOneWidget);

      await tester.tap(_field('save'));
      await tester.pumpAndSettle();
      expect(find.text('Kies een herinneringsdatum.'), findsOneWidget);
    });

    testWidgets('opslagfout toont een begrijpelijke melding', (tester) async {
      final repo = InMemoryProductRepository()
        ..failNextSaveWith = const AppException('Opslaan mislukt.');
      await pumpApp(tester, repository: repo);
      await _openNewProductForm(tester);

      await tester.enterText(_field('name'), 'Laptop');
      await tester.tap(_field('save'));
      await tester.pumpAndSettle();

      expect(find.text('Opslaan mislukt.'), findsOneWidget);
      expect(find.text('Product toevoegen'), findsOneWidget);
      expect(repo.all, isEmpty);
    });

    testWidgets('terug met niet-opgeslagen wijzigingen vraagt bevestiging', (
      tester,
    ) async {
      await pumpApp(tester);
      await _openNewProductForm(tester);

      await tester.enterText(_field('name'), 'Laptop');
      await tapBack(tester);
      expect(find.text('Wijzigingen weggooien?'), findsOneWidget);

      await tester.tap(find.text('Verder bewerken'));
      await tester.pumpAndSettle();
      expect(find.text('Product toevoegen'), findsOneWidget);

      await tapBack(tester);
      await tester.tap(find.text('Weggooien'));
      await tester.pumpAndSettle();
      expect(find.text('Product toevoegen'), findsNothing);
      expect(find.text('Nog geen producten'), findsOneWidget);
    });
  });

  group('productoverzicht', () {
    InMemoryProductRepository seeded() => InMemoryProductRepository([
      makeProduct(
        id: 'a',
        name: 'Wasmachine',
        merchant: 'Coolblue',
        category: ProductCategory.household,
        createdAt: DateTime.utc(2026, 10, 1),
      ),
      makeProduct(
        id: 'b',
        name: 'Telefoon',
        merchant: 'MediaMarkt',
        category: ProductCategory.phoneTablet,
        createdAt: DateTime.utc(2026, 10, 2),
      ),
    ]);

    testWidgets('zoeken filtert de lijst', (tester) async {
      await pumpApp(tester, repository: seeded());
      await tester.tap(find.byKey(const Key('nav.products')));
      await tester.pumpAndSettle();

      expect(find.text('Wasmachine'), findsOneWidget);
      expect(find.text('Telefoon'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('products.search')), 'cool');
      await tester.pumpAndSettle();
      expect(find.text('Wasmachine'), findsOneWidget);
      expect(find.text('Telefoon'), findsNothing);

      await tester.enterText(find.byKey(const Key('products.search')), 'xyz');
      await tester.pumpAndSettle();
      expect(find.text('Geen producten gevonden'), findsOneWidget);

      await tester.tap(find.text('Filters wissen'));
      await tester.pumpAndSettle();
      expect(find.text('Wasmachine'), findsOneWidget);
      expect(find.text('Telefoon'), findsOneWidget);
    });

    testWidgets('filteren op categorie', (tester) async {
      await pumpApp(tester, repository: seeded());
      await tester.tap(find.byKey(const Key('nav.products')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Telefoon en tablet'));
      await tester.pumpAndSettle();
      expect(find.text('Telefoon'), findsOneWidget);
      expect(find.text('Wasmachine'), findsNothing);

      await tester.tap(find.text('Alle'));
      await tester.pumpAndSettle();
      expect(find.text('Wasmachine'), findsOneWidget);
    });

    testWidgets('product bewerken', (tester) async {
      final repo = seeded();
      await pumpApp(tester, repository: repo);
      await _openProduct(tester, 'Wasmachine');

      await tester.tap(find.byKey(const Key('product.edit')));
      await tester.pumpAndSettle();
      expect(find.text('Product bewerken'), findsOneWidget);

      await tester.enterText(_field('name'), 'Wasmachine Pro');
      await tester.tap(_field('save'));
      await tester.pumpAndSettle();

      expect(find.text('Wasmachine Pro'), findsOneWidget);
      final updated = repo.all.firstWhere((p) => p.id == 'a');
      expect(updated.name, 'Wasmachine Pro');
      expect(updated.createdAt, DateTime.utc(2026, 10, 1));
    });

    testWidgets('product verwijderen na bevestiging', (tester) async {
      final repo = seeded();
      await pumpApp(tester, repository: repo);
      await _openProduct(tester, 'Wasmachine');

      await tester.tap(find.byKey(const Key('product.delete')));
      await tester.pumpAndSettle();
      expect(find.text('Product verwijderen?'), findsOneWidget);

      // Eerst annuleren: er gebeurt niets.
      await tester.tap(find.text('Annuleren'));
      await tester.pumpAndSettle();
      expect(repo.all, hasLength(2));

      await tester.tap(find.byKey(const Key('product.delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Verwijderen'));
      await tester.pumpAndSettle();

      expect(find.text('Product verwijderd.'), findsOneWidget);
      expect(repo.all.map((p) => p.id), ['b']);
      expect(find.text('Wasmachine'), findsNothing);
      expect(find.text('Telefoon'), findsOneWidget);
    });
  });

  testWidgets('dashboard toont naderende herinneringen', (tester) async {
    await pumpApp(
      tester,
      repository: InMemoryProductRepository([
        makeProduct(
          name: 'Koelkast',
          reminderEnabled: true,
          reminderDate: DateTime(2026, 10, 25),
        ),
      ]),
    );

    expect(find.text('Binnenkort'), findsOneWidget);
    expect(find.textContaining('Herinnering op 25 okt'), findsWidgets);
  });
}
