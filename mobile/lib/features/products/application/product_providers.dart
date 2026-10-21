import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../documents/application/document_service.dart';
import '../../reminders/application/reminder_service.dart';
import '../data/product_repository.dart';
import '../data/sqflite_product_repository.dart';
import '../domain/product.dart';
import '../domain/product_category.dart';
import '../domain/product_query.dart';

/// De productopslag. In widgettests vervangen door een in-memory variant.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SqfliteProductRepository(
    ref.watch(appDatabaseProvider),
    newId: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
  );
});

/// Alle producten. Wijzigingen lopen via deze notifier, zodat dashboard,
/// overzicht en detailscherm automatisch bijwerken.
final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(
      ProductsNotifier.new,
    );

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  ProductRepository get _repository => ref.read(productRepositoryProvider);

  @override
  Future<List<Product>> build() =>
      ref.watch(productRepositoryProvider).getAll();

  /// Slaat op en leest de lijst opnieuw in. Fouten worden doorgegeven aan de
  /// aanroeper, zodat het formulier een melding kan tonen. De huidige lijst
  /// blijft zichtbaar tijdens het opslaan (geen laadtoestand).
  Future<void> save(Product product) async {
    await _repository.save(product);
    state = AsyncData(await _repository.getAll());
    await ref.read(reminderSyncProvider).syncSafely();
  }

  /// Verwijdert het product. Documentrecords en herinneringen verdwijnen via
  /// ON DELETE CASCADE; daarna worden ook de documentbestanden verwijderd.
  Future<void> delete(String id) async {
    final documents = await ref
        .read(documentRepositoryProvider)
        .getForProduct(id);
    await _repository.delete(id);
    await ref.read(documentServiceProvider).deleteFiles(documents);
    ref.invalidate(documentsForProductProvider(id));
    state = AsyncData(await _repository.getAll());
    // Geen melding laten staan voor een verwijderd product.
    await ref.read(reminderSyncProvider).syncSafely();
  }
}

/// Eén product op basis van id, afgeleid van [productsProvider].
final productByIdProvider = Provider.family<AsyncValue<Product?>, String>((
  ref,
  id,
) {
  return ref.watch(productsProvider).whenData((products) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  });
});

/// Zoek-, filter- en sorteerinstellingen van het productoverzicht.
final productQueryProvider = NotifierProvider<ProductQueryNotifier, ProductQuery>(
  ProductQueryNotifier.new,
);

class ProductQueryNotifier extends Notifier<ProductQuery> {
  @override
  ProductQuery build() => const ProductQuery();

  void setSearchText(String text) =>
      state = state.copyWith(searchText: text);

  void setCategory(ProductCategory? category) =>
      state = state.copyWith(category: () => category);

  void setSort(ProductSort sort) => state = state.copyWith(sort: sort);

  void reset() => state = const ProductQuery();
}
