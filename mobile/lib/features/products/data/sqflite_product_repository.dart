import '../../../core/storage/app_database.dart';
import '../../../core/utils/dates.dart';
import '../domain/product.dart';
import '../domain/product_category.dart';
import 'product_repository.dart';

/// [ProductRepository] op basis van de lokale SQLite-database.
class SqfliteProductRepository implements ProductRepository {
  SqfliteProductRepository(
    this._appDatabase, {
    required String Function() newId,
    required DateTime Function() clock,
  }) : _newId = newId,
       _clock = clock;

  final AppDatabase _appDatabase;
  final String Function() _newId;
  final DateTime Function() _clock;

  /// Herinneringen gaan af om 09:00 lokale tijd (planning volgt in fase 5).
  static const _reminderTime = 'T09:00:00';

  static const _selectProducts = '''
    SELECT p.*,
           (SELECT r.trigger_at FROM reminders r
             WHERE r.product_id = p.id
             ORDER BY r.trigger_at
             LIMIT 1) AS reminder_trigger_at
      FROM products p
  ''';

  @override
  Future<List<Product>> getAll() async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '$_selectProducts ORDER BY p.created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Product?> getById(String id) async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery('$_selectProducts WHERE p.id = ?', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> save(Product product) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      final values = _toRow(product);
      // Eerst bijwerken; alleen invoegen als het product nog niet bestaat.
      // (Geen INSERT OR REPLACE: dat verwijdert de rij en daarmee via
      // ON DELETE CASCADE ook gekoppelde documenten.)
      final updated = await txn.update(
        'products',
        values..remove('created_at'),
        where: 'id = ?',
        whereArgs: [product.id],
      );
      if (updated == 0) {
        await txn.insert('products', _toRow(product));
      }

      await txn.delete(
        'reminders',
        where: 'product_id = ?',
        whereArgs: [product.id],
      );
      final reminderDate = product.reminderDate;
      if (reminderDate != null) {
        await txn.insert('reminders', {
          'id': _newId(),
          'product_id': product.id,
          'trigger_at': '${Dates.toIsoDate(reminderDate)}$_reminderTime',
          'notification_id': null,
          'enabled': product.reminderEnabled ? 1 : 0,
          'created_at': _clock().toUtc().toIso8601String(),
        });
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    final db = await _appDatabase.database;
    // Documentrecords en herinneringen worden via ON DELETE CASCADE verwijderd.
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _toRow(Product product) => {
    'id': product.id,
    'name': product.name,
    'brand': product.brand,
    'category': product.category.key,
    'merchant': product.merchant,
    'purchase_date': Dates.toIsoDate(product.purchaseDate),
    'purchase_price_minor': product.purchasePriceMinor,
    'currency': product.currency,
    'warranty_end_date': product.warrantyEndDate == null
        ? null
        : Dates.toIsoDate(product.warrantyEndDate!),
    'reminder_enabled': product.reminderEnabled ? 1 : 0,
    'created_at': product.createdAt.toUtc().toIso8601String(),
    'updated_at': product.updatedAt.toUtc().toIso8601String(),
  };

  Product _fromRow(Map<String, Object?> row) {
    final warrantyEnd = row['warranty_end_date'] as String?;
    final reminderAt = row['reminder_trigger_at'] as String?;
    return Product(
      id: row['id']! as String,
      name: row['name']! as String,
      brand: row['brand'] as String?,
      category: ProductCategory.fromKey(row['category']! as String),
      merchant: row['merchant'] as String?,
      purchaseDate: Dates.parseIsoDate(row['purchase_date']! as String),
      purchasePriceMinor: row['purchase_price_minor'] as int?,
      currency: row['currency']! as String,
      warrantyEndDate: warrantyEnd == null
          ? null
          : Dates.parseIsoDate(warrantyEnd),
      reminderEnabled: (row['reminder_enabled']! as int) == 1,
      reminderDate: reminderAt == null
          ? null
          : Dates.parseIsoDate(reminderAt.substring(0, 10)),
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }
}
