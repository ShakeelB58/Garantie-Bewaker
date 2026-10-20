import 'package:garantiebewaker/features/products/data/product_repository.dart';
import 'package:garantiebewaker/features/products/domain/product.dart';

/// Eenvoudige [ProductRepository] in het geheugen voor widgettests.
class InMemoryProductRepository implements ProductRepository {
  InMemoryProductRepository([List<Product> initial = const []]) {
    for (final product in initial) {
      _products[product.id] = product;
    }
  }

  final Map<String, Product> _products = {};

  /// Als ingesteld, gooit de volgende [save] deze fout.
  Object? failNextSaveWith;

  /// Wordt aangeroepen na [delete], bijv. om ON DELETE CASCADE na te bootsen.
  void Function(String id)? onDelete;

  List<Product> get all => _products.values.toList();

  @override
  Future<List<Product>> getAll() async {
    final list = _products.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Product?> getById(String id) async => _products[id];

  @override
  Future<void> save(Product product) async {
    final error = failNextSaveWith;
    if (error != null) {
      failNextSaveWith = null;
      throw error;
    }
    _products[product.id] = product;
  }

  @override
  Future<void> deleteAll() async {
    final ids = _products.keys.toList();
    _products.clear();
    for (final id in ids) {
      onDelete?.call(id);
    }
  }

  @override
  Future<void> delete(String id) async {
    _products.remove(id);
    onDelete?.call(id);
  }
}
