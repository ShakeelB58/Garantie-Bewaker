import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/products/application/product_providers.dart';

import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';

void main() {
  late InMemoryProductRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = InMemoryProductRepository();
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('laadt producten uit de repository', () async {
    await repo.save(makeProduct());
    expect(await container.read(productsProvider.future), hasLength(1));
  });

  test('opslaan werkt de lijst en productByIdProvider bij', () async {
    await container.read(productsProvider.future);
    final product = makeProduct();

    await container.read(productsProvider.notifier).save(product);

    expect(container.read(productsProvider).value, [product]);
    expect(container.read(productByIdProvider('p1')).value, product);
    expect(container.read(productByIdProvider('onbekend')).value, isNull);
  });

  test('verwijderen haalt het product uit de lijst', () async {
    await repo.save(makeProduct());
    await container.read(productsProvider.future);

    await container.read(productsProvider.notifier).delete('p1');

    expect(container.read(productsProvider).value, isEmpty);
    expect(repo.all, isEmpty);
  });

  test('een opslagfout wordt doorgegeven en de lijst blijft staan', () async {
    await repo.save(makeProduct());
    await container.read(productsProvider.future);
    repo.failNextSaveWith = StateError('schijf vol');

    await expectLater(
      container.read(productsProvider.notifier).save(makeProduct(id: 'p2')),
      throwsStateError,
    );
    expect(container.read(productsProvider).value, hasLength(1));
  });
}
