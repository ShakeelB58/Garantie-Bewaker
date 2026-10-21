import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/storage/app_database.dart';
import 'package:garantiebewaker/core/storage/migrations.dart';
import 'package:garantiebewaker/features/products/data/sqflite_product_repository.dart';
import 'package:garantiebewaker/features/products/domain/product_category.dart';
import 'package:garantiebewaker/features/reminders/domain/reminder_planner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fixtures.dart';

/// Tests tegen een echte SQLite-database in het geheugen (via FFI).
void main() {
  late AppDatabase appDatabase;
  late SqfliteProductRepository repository;
  var idCounter = 0;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    appDatabase = AppDatabase(
      factory: databaseFactoryFfi,
      pathProvider: () async => inMemoryDatabasePath,
    );
    repository = SqfliteProductRepository(
      appDatabase,
      newId: () => 'r${idCounter++}',
      clock: () => testNow,
    );
  });

  tearDown(() => appDatabase.close());

  group('schema', () {
    test('alle tabellen bestaan na de migraties', () async {
      final db = await appDatabase.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
      );
      expect(
        tables.map((t) => t['name']),
        containsAll(['products', 'documents', 'reminders', 'settings']),
      );
      expect(await db.getVersion(), Migrations.latestVersion);
    });

    test('foreign keys staan aan', () async {
      final db = await appDatabase.database;
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first.values.first, 1);
    });

    test('lege productnaam wordt door de database geweigerd', () async {
      await expectLater(
        repository.save(makeProduct(name: '   ')),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  test('opslaan en teruglezen levert hetzelfde product op', () async {
    final product = makeProduct(
      brand: 'Bosch',
      warrantyEndDate: DateTime(2028, 9, 30),
      reminderEnabled: true,
      reminderDate: DateTime(2028, 9, 1),
    );
    await repository.save(product);

    expect(await repository.getById(product.id), product);
    expect(await repository.getAll(), [product]);
  });

  test('optionele velden mogen leeg zijn', () async {
    final product = makeProduct(merchant: null, purchasePriceMinor: null);
    await repository.save(product);
    final loaded = await repository.getById(product.id);
    expect(loaded!.merchant, isNull);
    expect(loaded.purchasePriceMinor, isNull);
    expect(loaded.reminderDate, isNull);
  });

  test('getById geeft null voor een onbekend id', () async {
    expect(await repository.getById('bestaat-niet'), isNull);
  });

  test('getAll sorteert op aanmaakmoment, nieuwste eerst', () async {
    await repository.save(
      makeProduct(id: 'oud', createdAt: DateTime.utc(2026, 1, 1)),
    );
    await repository.save(
      makeProduct(id: 'nieuw', createdAt: DateTime.utc(2026, 5, 1)),
    );
    final ids = (await repository.getAll()).map((p) => p.id);
    expect(ids, ['nieuw', 'oud']);
  });

  test('bijwerken behoudt createdAt en vervangt de herinnering', () async {
    final original = makeProduct(
      reminderEnabled: true,
      reminderDate: DateTime(2027, 1, 1),
    );
    await repository.save(original);

    final updated = makeProduct(
      name: 'Wasmachine Pro',
      reminderEnabled: true,
      reminderDate: DateTime(2027, 6, 1),
      createdAt: DateTime.utc(2030, 1, 1), // mag createdAt niet overschrijven
    );
    await repository.save(updated);

    final loaded = (await repository.getById(original.id))!;
    expect(loaded.name, 'Wasmachine Pro');
    expect(loaded.reminderDate, DateTime(2027, 6, 1));
    expect(loaded.createdAt, original.createdAt);

    final db = await appDatabase.database;
    final reminders = await db.query('reminders');
    expect(reminders, hasLength(1));
    expect(reminders.first['trigger_at'], '2027-06-01T09:00:00');
    expect(
      reminders.first['notification_id'],
      ReminderPlanner.notificationIdFor(original.id),
    );
  });

  test('herinnering uitzetten bewaart de datum, maar niet actief', () async {
    await repository.save(
      makeProduct(reminderEnabled: false, reminderDate: DateTime(2027, 1, 1)),
    );
    final loaded = (await repository.getById('p1'))!;
    expect(loaded.reminderEnabled, isFalse);
    expect(loaded.reminderDate, DateTime(2027, 1, 1));
    expect(loaded.activeReminderDate, isNull);
  });

  test('bijwerken verwijdert gekoppelde documenten niet', () async {
    await repository.save(makeProduct());
    final db = await appDatabase.database;
    await db.insert('documents', {
      'id': 'd1',
      'product_id': 'p1',
      'file_path': 'documents/d1.pdf',
      'document_type': 'invoice',
      'mime_type': 'application/pdf',
      'created_at': '2026-10-01T12:00:00.000Z',
    });

    await repository.save(makeProduct(name: 'Andere naam'));

    expect(await db.query('documents'), hasLength(1));
  });

  test('verwijderen verwijdert ook documentrecords en herinneringen', () async {
    await repository.save(
      makeProduct(reminderEnabled: true, reminderDate: DateTime(2027, 1, 1)),
    );
    await repository.save(makeProduct(id: 'p2'));
    final db = await appDatabase.database;
    await db.insert('documents', {
      'id': 'd1',
      'product_id': 'p1',
      'file_path': 'documents/d1.pdf',
      'document_type': 'invoice',
      'mime_type': 'application/pdf',
      'created_at': '2026-10-01T12:00:00.000Z',
    });

    await repository.delete('p1');

    expect(await repository.getById('p1'), isNull);
    expect(await repository.getById('p2'), isNotNull);
    expect(await db.query('documents'), isEmpty);
    expect(await db.query('reminders'), isEmpty);
  });

  test('onbekende categorie uit de database wordt "Overig"', () async {
    await repository.save(makeProduct());
    final db = await appDatabase.database;
    await db.update('products', {'category': 'iets_nieuws'});
    final loaded = (await repository.getById('p1'))!;
    expect(loaded.category, ProductCategory.other);
  });

  test('alles verwijderen wist producten, documenten en herinneringen',
      () async {
    await repository.save(
      makeProduct(reminderEnabled: true, reminderDate: DateTime(2027, 1, 1)),
    );
    await repository.save(makeProduct(id: 'p2'));
    final db = await appDatabase.database;
    await db.insert('documents', {
      'id': 'd1',
      'product_id': 'p1',
      'file_path': 'documents/d1.pdf',
      'document_type': 'invoice',
      'mime_type': 'application/pdf',
      'created_at': '2026-10-01T12:00:00.000Z',
    });

    await repository.deleteAll();

    expect(await repository.getAll(), isEmpty);
    expect(await db.query('documents'), isEmpty);
    expect(await db.query('reminders'), isEmpty);
  });
}
