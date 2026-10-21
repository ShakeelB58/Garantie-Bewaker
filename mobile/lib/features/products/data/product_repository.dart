import '../domain/product.dart';

/// Opslag van producten. De UI praat alleen met deze interface, nooit
/// rechtstreeks met SQLite.
abstract interface class ProductRepository {
  /// Alle producten, nieuwste eerst (op aanmaakmoment).
  Future<List<Product>> getAll();

  Future<Product?> getById(String id);

  /// Voegt toe of werkt bij (op basis van [Product.id]).
  Future<void> save(Product product);

  /// Verwijdert het product met gekoppelde documentrecords en herinneringen.
  Future<void> delete(String id);

  /// Verwijdert alle producten, documentrecords en herinneringen.
  Future<void> deleteAll();
}
