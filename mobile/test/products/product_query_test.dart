import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/products/domain/product_category.dart';
import 'package:garantiebewaker/features/products/domain/product_query.dart';

import '../helpers/fixtures.dart';

void main() {
  final wasmachine = makeProduct(
    id: 'a',
    name: 'Wasmachine',
    brand: 'Bosch',
    merchant: 'Coolblue',
    category: ProductCategory.household,
    purchaseDate: DateTime(2026, 1, 10),
    reminderEnabled: true,
    reminderDate: DateTime(2027, 12, 1),
  );
  final telefoon = makeProduct(
    id: 'b',
    name: 'Telefoon',
    brand: 'Samsung',
    merchant: 'MediaMarkt',
    category: ProductCategory.phoneTablet,
    purchaseDate: DateTime(2026, 6, 1),
    reminderEnabled: true,
    reminderDate: DateTime(2027, 5, 1),
  );
  final fohn = makeProduct(
    id: 'c',
    name: 'Föhn',
    merchant: 'Kruidvat',
    category: ProductCategory.household,
    purchaseDate: DateTime(2025, 3, 3),
  );
  final all = [wasmachine, telefoon, fohn];

  List<String> ids(ProductQuery query) =>
      query.apply(all).map((p) => p.id).toList();

  test('standaard: aankoopdatum, nieuwste eerst', () {
    expect(ids(const ProductQuery()), ['b', 'a', 'c']);
  });

  test('aankoopdatum, oudste eerst', () {
    expect(ids(const ProductQuery(sort: ProductSort.purchaseDateOldest)), [
      'c',
      'a',
      'b',
    ]);
  });

  test('herinneringsdatum: eerstvolgende eerst, zonder datum achteraan', () {
    expect(ids(const ProductQuery(sort: ProductSort.reminderDateSoonest)), [
      'b',
      'a',
      'c',
    ]);
  });

  test('zoeken op naam, merk en winkel, zonder hoofdletters', () {
    expect(ids(const ProductQuery(searchText: 'wasm')), ['a']);
    expect(ids(const ProductQuery(searchText: 'SAMSUNG')), ['b']);
    expect(ids(const ProductQuery(searchText: 'media')), ['b']);
  });

  test('zoeken negeert accenten', () {
    expect(ids(const ProductQuery(searchText: 'fohn')), ['c']);
  });

  test('meerdere zoekwoorden moeten allemaal voorkomen', () {
    expect(ids(const ProductQuery(searchText: 'bosch coolblue')), ['a']);
    expect(ids(const ProductQuery(searchText: 'bosch mediamarkt')), isEmpty);
  });

  test('filteren op categorie', () {
    expect(ids(const ProductQuery(category: ProductCategory.household)), [
      'a',
      'c',
    ]);
  });

  test('copyWith kan de categorie wissen', () {
    const query = ProductQuery(category: ProductCategory.household);
    expect(query.copyWith(category: () => null).category, isNull);
    expect(query.copyWith(searchText: 'x').category, ProductCategory.household);
  });

  test('de invoerlijst wordt niet aangepast', () {
    final copy = [...all];
    const ProductQuery(sort: ProductSort.purchaseDateOldest).apply(copy);
    expect(copy, all);
  });
}
