import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/storage/app_database.dart';
import 'package:garantiebewaker/features/documents/data/document_repository.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';
import 'package:garantiebewaker/features/products/data/sqflite_product_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';

/// Tests tegen een echte SQLite-database in het geheugen (via FFI).
void main() {
  late AppDatabase appDatabase;
  late SqfliteDocumentRepository documents;
  late SqfliteProductRepository products;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    appDatabase = AppDatabase(
      factory: databaseFactoryFfi,
      pathProvider: () async => inMemoryDatabasePath,
    );
    documents = SqfliteDocumentRepository(appDatabase);
    products = SqfliteProductRepository(
      appDatabase,
      newId: () => 'r',
      clock: () => testNow,
    );
    await products.save(makeProduct(id: 'p1'));
    await products.save(makeProduct(id: 'p2'));
  });

  tearDown(() => appDatabase.close());

  test('opslaan en teruglezen', () async {
    final document = makeDocument();
    await documents.insert(document);

    expect(await documents.getById('d1'), document);
    expect(await documents.getForProduct('p1'), [document]);
    expect(await documents.getForProduct('p2'), isEmpty);
  });

  test('meerdere documenten per product, oudste eerst', () async {
    final later = Document(
      id: 'd2',
      productId: 'p1',
      filePath: 'documents/d2.jpg',
      type: DocumentType.receipt,
      format: DocumentFormat.jpeg,
      createdAt: DateTime.utc(2026, 10, 5),
    );
    await documents.insert(later);
    await documents.insert(makeDocument());

    final ids = (await documents.getForProduct('p1')).map((d) => d.id);
    expect(ids, ['d1', 'd2']);
  });

  test('document zonder bestaand product wordt geweigerd', () async {
    await expectLater(
      documents.insert(makeDocument(productId: 'bestaat-niet')),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('soort wijzigen en verwijderen', () async {
    await documents.insert(makeDocument());

    await documents.updateType('d1', DocumentType.warranty);
    expect((await documents.getById('d1'))!.type, DocumentType.warranty);

    await documents.delete('d1');
    expect(await documents.getById('d1'), isNull);
  });

  test('allFilePaths', () async {
    await documents.insert(makeDocument());
    await documents.insert(makeDocument(id: 'd2', productId: 'p2'));
    expect(
      await documents.allFilePaths(),
      {'documents/d1.pdf', 'documents/d2.pdf'},
    );
  });

  test('product verwijderen verwijdert ook de documentrecords', () async {
    await documents.insert(makeDocument());
    await documents.insert(makeDocument(id: 'd2', productId: 'p2'));

    await products.delete('p1');

    expect(await documents.getById('d1'), isNull);
    expect(await documents.getById('d2'), isNotNull);
  });
}
