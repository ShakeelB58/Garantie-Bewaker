import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import 'product.dart';
import 'product_category.dart';

/// Velden van het productformulier.
enum ProductField {
  name,
  brand,
  merchant,
  purchaseDate,
  price,
  currency,
  warrantyEndDate,
  reminderDate,
}

/// Ruwe invoer uit het formulier, nog niet gecontroleerd.
class ProductInput {
  const ProductInput({
    this.name = '',
    this.brand = '',
    this.merchant = '',
    this.category = ProductCategory.other,
    this.purchaseDate,
    this.priceText = '',
    this.currency = 'EUR',
    this.warrantyEndDate,
    this.reminderEnabled = false,
    this.reminderDate,
  });

  factory ProductInput.fromProduct(Product product) => ProductInput(
    name: product.name,
    brand: product.brand ?? '',
    merchant: product.merchant ?? '',
    category: product.category,
    purchaseDate: product.purchaseDate,
    priceText: product.purchasePriceMinor == null
        ? ''
        : Money.formatForInput(product.purchasePriceMinor!),
    currency: product.currency,
    warrantyEndDate: product.warrantyEndDate,
    reminderEnabled: product.reminderEnabled,
    reminderDate: product.reminderDate,
  );

  final String name;
  final String brand;
  final String merchant;
  final ProductCategory category;
  final DateTime? purchaseDate;
  final String priceText;
  final String currency;
  final DateTime? warrantyEndDate;
  final bool reminderEnabled;
  final DateTime? reminderDate;

  /// Maakt een [Product]. Roep dit alleen aan als [ProductValidator.validate]
  /// geen fouten gaf.
  Product toProduct({
    required String id,
    required DateTime createdAt,
    required DateTime now,
  }) {
    String? optional(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return Product(
      id: id,
      name: name.trim(),
      brand: optional(brand),
      category: category,
      merchant: optional(merchant),
      purchaseDate: Dates.dateOnly(purchaseDate!),
      purchasePriceMinor: priceText.trim().isEmpty
          ? null
          : Money.parseToMinor(priceText),
      currency: currency,
      warrantyEndDate: warrantyEndDate == null
          ? null
          : Dates.dateOnly(warrantyEndDate!),
      reminderEnabled: reminderEnabled && reminderDate != null,
      reminderDate: reminderDate == null ? null : Dates.dateOnly(reminderDate!),
      createdAt: createdAt.toUtc(),
      updatedAt: now.toUtc(),
    );
  }
}

/// Controle van productinvoer met Nederlandstalige foutmeldingen.
abstract final class ProductValidator {
  static const maxNameLength = 120;
  static const maxTextLength = 120;

  /// Maximaal € 1.000.000,00 (voorkomt typfouten met te veel nullen).
  static const maxPriceMinor = 100000000;

  static Map<ProductField, String> validate(
    ProductInput input, {
    required DateTime today,
  }) {
    final errors = <ProductField, String>{};
    final todayDate = Dates.dateOnly(today);

    final name = input.name.trim();
    if (name.isEmpty) {
      errors[ProductField.name] = 'Vul een productnaam in.';
    } else if (name.length > maxNameLength) {
      errors[ProductField.name] =
          'Gebruik maximaal $maxNameLength tekens.';
    }

    if (input.brand.trim().length > maxTextLength) {
      errors[ProductField.brand] = 'Gebruik maximaal $maxTextLength tekens.';
    }
    if (input.merchant.trim().length > maxTextLength) {
      errors[ProductField.merchant] =
          'Gebruik maximaal $maxTextLength tekens.';
    }

    final purchaseDate = input.purchaseDate == null
        ? null
        : Dates.dateOnly(input.purchaseDate!);
    if (purchaseDate == null) {
      errors[ProductField.purchaseDate] = 'Kies de aankoopdatum.';
    } else if (purchaseDate.isAfter(todayDate)) {
      errors[ProductField.purchaseDate] =
          'De aankoopdatum kan niet in de toekomst liggen.';
    }

    if (input.priceText.trim().isNotEmpty) {
      final minor = Money.parseToMinor(input.priceText);
      if (minor == null) {
        errors[ProductField.price] =
            'Vul een geldig bedrag in, bijvoorbeeld 1.299,00.';
      } else if (minor > maxPriceMinor) {
        errors[ProductField.price] = 'Dit bedrag is te hoog.';
      }
    }

    if (!Money.supportedCurrencies.contains(input.currency)) {
      errors[ProductField.currency] = 'Kies een valuta.';
    }

    final warrantyEnd = input.warrantyEndDate;
    if (warrantyEnd != null &&
        purchaseDate != null &&
        Dates.dateOnly(warrantyEnd).isBefore(purchaseDate)) {
      errors[ProductField.warrantyEndDate] =
          'De einddatum ligt vóór de aankoopdatum.';
    }

    final reminder = input.reminderDate;
    if (input.reminderEnabled && reminder == null) {
      errors[ProductField.reminderDate] = 'Kies een herinneringsdatum.';
    } else if (reminder != null &&
        purchaseDate != null &&
        Dates.dateOnly(reminder).isBefore(purchaseDate)) {
      errors[ProductField.reminderDate] =
          'De herinnering ligt vóór de aankoopdatum.';
    }

    return errors;
  }
}
