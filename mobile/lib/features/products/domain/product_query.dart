import 'product.dart';
import 'product_category.dart';

enum ProductSort {
  purchaseDateNewest('Aankoopdatum (nieuwste eerst)'),
  purchaseDateOldest('Aankoopdatum (oudste eerst)'),
  reminderDateSoonest('Herinneringsdatum (eerstvolgende eerst)');

  const ProductSort(this.label);

  final String label;
}

/// Zoek-, filter- en sorteerinstellingen van het productoverzicht.
class ProductQuery {
  const ProductQuery({
    this.searchText = '',
    this.category,
    this.sort = ProductSort.purchaseDateNewest,
  });

  final String searchText;
  final ProductCategory? category;
  final ProductSort sort;

  bool get isFiltering => searchText.trim().isNotEmpty || category != null;

  ProductQuery copyWith({
    String? searchText,
    ProductCategory? Function()? category,
    ProductSort? sort,
  }) => ProductQuery(
    searchText: searchText ?? this.searchText,
    category: category != null ? category() : this.category,
    sort: sort ?? this.sort,
  );

  /// Past zoeken, filteren en sorteren toe. De invoerlijst blijft ongewijzigd.
  List<Product> apply(List<Product> products) {
    final terms = _normalize(
      searchText,
    ).split(' ').where((t) => t.isNotEmpty).toList();

    final result = products.where((product) {
      if (category != null && product.category != category) return false;
      if (terms.isEmpty) return true;
      final haystack = _normalize(
        '${product.name} ${product.brand ?? ''} ${product.merchant ?? ''}',
      );
      return terms.every(haystack.contains);
    }).toList();

    int byPurchaseDesc(Product a, Product b) {
      final c = b.purchaseDate.compareTo(a.purchaseDate);
      return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
    }

    switch (sort) {
      case ProductSort.purchaseDateNewest:
        result.sort(byPurchaseDesc);
      case ProductSort.purchaseDateOldest:
        result.sort((a, b) => -byPurchaseDesc(a, b));
      case ProductSort.reminderDateSoonest:
        result.sort((a, b) {
          final ra = a.activeReminderDate;
          final rb = b.activeReminderDate;
          if (ra == null && rb == null) return byPurchaseDesc(a, b);
          if (ra == null) return 1;
          if (rb == null) return -1;
          final c = ra.compareTo(rb);
          return c != 0 ? c : byPurchaseDesc(a, b);
        });
    }
    return result;
  }

  static String _normalize(String value) {
    const accents = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ç': 'c',
      'ñ': 'n',
    };
    final lower = value.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(accents[char] ?? char);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }
}
