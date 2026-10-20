import '../../../core/utils/money.dart';
import '../../products/domain/product.dart';

/// Productgegevens als CSV voor Excel/Numbers met Nederlandse instellingen:
/// puntkomma als scheidingsteken, datums als dd-mm-jjjj, bedragen met komma.
abstract final class ProductsCsv {
  static const separator = ';';

  static const header = [
    'Naam',
    'Merk',
    'Categorie',
    'Winkel',
    'Aankoopdatum',
    'Aankoopprijs',
    'Valuta',
    'Garantie tot',
    'Herinnering aan',
    'Herinneringsdatum',
    'Aantal documenten',
  ];

  /// [documentCounts]: aantal documenten per product-id.
  static String build(List<Product> products, Map<String, int> documentCounts) {
    final buffer = StringBuffer()
      // BOM, zodat Excel de tekst als UTF-8 leest (é, ë, €).
      ..write('﻿')
      ..write(_row(header));
    for (final product in products) {
      buffer.write(
        _row([
          product.name,
          product.brand ?? '',
          product.category.label,
          product.merchant ?? '',
          _date(product.purchaseDate),
          product.purchasePriceMinor == null
              ? ''
              : Money.formatForInput(product.purchasePriceMinor!),
          product.currency,
          product.warrantyEndDate == null
              ? ''
              : _date(product.warrantyEndDate!),
          product.reminderEnabled ? 'ja' : 'nee',
          product.reminderDate == null ? '' : _date(product.reminderDate!),
          '${documentCounts[product.id] ?? 0}',
        ]),
      );
    }
    return buffer.toString();
  }

  static String _row(List<String> cells) =>
      '${cells.map(escape).join(separator)}\r\n';

  /// Zet een waarde veilig in een CSV-cel.
  ///
  /// - Aanhalingstekens rond waarden met scheidingsteken, aanhalingsteken of
  ///   regeleinde.
  /// - Een waarde die met `=`, `+`, `-`, `@` of een tab begint, krijgt een
  ///   apostrof ervoor. Zo voert een spreadsheet tekst uit een productnaam
  ///   nooit uit als formule (CSV-injectie).
  static String escape(String value) {
    var result = value;
    if (result.isNotEmpty && '=+-@\t\r'.contains(result[0])) {
      result = "'$result";
    }
    if (result.contains(separator) ||
        result.contains('"') ||
        result.contains('\n') ||
        result.contains('\r')) {
      result = '"${result.replaceAll('"', '""')}"';
    }
    return result;
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.year.toString().padLeft(4, '0')}';
}
