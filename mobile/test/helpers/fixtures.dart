import 'package:garantiebewaker/features/products/domain/product.dart';
import 'package:garantiebewaker/features/products/domain/product_category.dart';

/// Vaste "nu" in tests: maandag 19 oktober 2026, 10:00 lokale tijd.
final testNow = DateTime(2026, 10, 19, 10);

Product makeProduct({
  String id = 'p1',
  String name = 'Wasmachine',
  String? brand,
  ProductCategory category = ProductCategory.household,
  String? merchant = 'MediaMarkt',
  DateTime? purchaseDate,
  int? purchasePriceMinor = 49900,
  String currency = 'EUR',
  DateTime? warrantyEndDate,
  bool reminderEnabled = false,
  DateTime? reminderDate,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 10, 1, 12);
  return Product(
    id: id,
    name: name,
    brand: brand,
    category: category,
    merchant: merchant,
    purchaseDate: purchaseDate ?? DateTime(2026, 9, 30),
    purchasePriceMinor: purchasePriceMinor,
    currency: currency,
    warrantyEndDate: warrantyEndDate,
    reminderEnabled: reminderEnabled,
    reminderDate: reminderDate,
    createdAt: created,
    updatedAt: created,
  );
}
