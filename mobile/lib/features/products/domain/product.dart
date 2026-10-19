import 'product_category.dart';

/// Een geregistreerd product.
///
/// [warrantyEndDate] en [reminderDate] zijn door de gebruiker ingevulde datums.
/// De app leidt nooit zelf een garantietermijn af.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.purchaseDate,
    required this.currency,
    required this.reminderEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.brand,
    this.merchant,
    this.purchasePriceMinor,
    this.warrantyEndDate,
    this.reminderDate,
  });

  final String id;
  final String name;
  final String? brand;
  final ProductCategory category;
  final String? merchant;

  /// Kalenderdatum (zonder tijd).
  final DateTime purchaseDate;

  /// Prijs in centen.
  final int? purchasePriceMinor;

  /// ISO 4217-code, bijv. `EUR`.
  final String currency;

  /// Door de gebruiker ingevulde garantie-einddatum (optioneel).
  final DateTime? warrantyEndDate;

  /// Of de gebruiker een herinnering wil ontvangen.
  final bool reminderEnabled;

  /// Door de gebruiker ingestelde herinneringsdatum (optioneel).
  final DateTime? reminderDate;

  /// Tijdstippen in UTC.
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Herinneringsdatum die actief is, of `null`.
  DateTime? get activeReminderDate => reminderEnabled ? reminderDate : null;

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.brand == brand &&
      other.category == category &&
      other.merchant == merchant &&
      other.purchaseDate == purchaseDate &&
      other.purchasePriceMinor == purchasePriceMinor &&
      other.currency == currency &&
      other.warrantyEndDate == warrantyEndDate &&
      other.reminderEnabled == reminderEnabled &&
      other.reminderDate == reminderDate &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    brand,
    category,
    merchant,
    purchaseDate,
    purchasePriceMinor,
    currency,
    warrantyEndDate,
    reminderEnabled,
    reminderDate,
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'Product($id, $name)';
}
