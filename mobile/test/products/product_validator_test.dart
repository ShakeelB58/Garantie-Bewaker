import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/products/domain/product_category.dart';
import 'package:garantiebewaker/features/products/domain/product_input.dart';

import '../helpers/fixtures.dart';

void main() {
  final today = testNow;

  ProductInput valid({
    String name = 'Wasmachine',
    DateTime? purchaseDate,
    String priceText = '499,00',
    DateTime? warrantyEndDate,
    bool reminderEnabled = false,
    DateTime? reminderDate,
    String currency = 'EUR',
  }) => ProductInput(
    name: name,
    merchant: 'MediaMarkt',
    category: ProductCategory.household,
    purchaseDate: purchaseDate ?? DateTime(2026, 9, 30),
    priceText: priceText,
    currency: currency,
    warrantyEndDate: warrantyEndDate,
    reminderEnabled: reminderEnabled,
    reminderDate: reminderDate,
  );

  Map<ProductField, String> validate(ProductInput input) =>
      ProductValidator.validate(input, today: today);

  test('geldige invoer geeft geen fouten', () {
    expect(validate(valid()), isEmpty);
  });

  test('productnaam is verplicht', () {
    expect(validate(valid(name: '   ')), contains(ProductField.name));
  });

  test('te lange productnaam', () {
    expect(validate(valid(name: 'a' * 121)), contains(ProductField.name));
  });

  test('aankoopdatum is verplicht', () {
    const input = ProductInput(name: 'Tv');
    expect(validate(input)[ProductField.purchaseDate], 'Kies de aankoopdatum.');
  });

  test('aankoopdatum vandaag mag, morgen niet', () {
    expect(validate(valid(purchaseDate: DateTime(2026, 10, 19))), isEmpty);
    expect(
      validate(valid(purchaseDate: DateTime(2026, 10, 20))),
      contains(ProductField.purchaseDate),
    );
  });

  test('prijs is optioneel, maar moet geldig zijn als ingevuld', () {
    expect(validate(valid(priceText: '')), isEmpty);
    expect(validate(valid(priceText: 'twintig')), contains(ProductField.price));
    expect(
      validate(valid(priceText: '2.000.000,00')),
      contains(ProductField.price),
    );
  });

  test('onbekende valuta', () {
    expect(validate(valid(currency: 'XYZ')), contains(ProductField.currency));
  });

  test('garantie-einddatum mag niet vóór de aankoopdatum liggen', () {
    expect(
      validate(valid(warrantyEndDate: DateTime(2026, 9, 1))),
      contains(ProductField.warrantyEndDate),
    );
    expect(validate(valid(warrantyEndDate: DateTime(2028, 9, 30))), isEmpty);
  });

  test('herinnering aan vereist een datum', () {
    expect(
      validate(valid(reminderEnabled: true)),
      contains(ProductField.reminderDate),
    );
    expect(
      validate(
        valid(reminderEnabled: true, reminderDate: DateTime(2028, 9, 1)),
      ),
      isEmpty,
    );
  });

  test('toProduct zet invoer om naar een product', () {
    final product = valid(
      name: '  Wasmachine  ',
      priceText: '1.299,00',
      reminderEnabled: true,
      reminderDate: DateTime(2028, 9, 1, 15, 30),
    ).toProduct(id: 'x', createdAt: testNow, now: testNow);

    expect(product.name, 'Wasmachine');
    expect(product.purchasePriceMinor, 129900);
    expect(product.brand, isNull);
    expect(product.reminderEnabled, isTrue);
    expect(product.reminderDate, DateTime(2028, 9, 1));
    expect(product.createdAt.isUtc, isTrue);
  });

  test('fromProduct en terug levert hetzelfde product op', () {
    final original = makeProduct(
      brand: 'Bosch',
      warrantyEndDate: DateTime(2028, 9, 30),
      reminderEnabled: true,
      reminderDate: DateTime(2028, 9, 1),
    );
    final roundTrip = ProductInput.fromProduct(original).toProduct(
      id: original.id,
      createdAt: original.createdAt,
      now: original.updatedAt,
    );
    expect(roundTrip, original);
  });
}
