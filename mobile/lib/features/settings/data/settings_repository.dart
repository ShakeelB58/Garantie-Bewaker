import 'package:sqflite/sqflite.dart';

import '../../../core/storage/app_database.dart';

/// Voorkeuren van de gebruiker, lokaal opgeslagen.
abstract interface class SettingsRepository {
  Future<String?> read(String key);
  Future<void> write(String key, String value);

  /// Verwijdert alle voorkeuren.
  Future<void> clear();
}

class SqfliteSettingsRepository implements SettingsRepository {
  SqfliteSettingsRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<String?> read(String key) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  @override
  Future<void> clear() async {
    final db = await _appDatabase.database;
    await db.delete('settings');
  }

  @override
  Future<void> write(String key, String value) async {
    final db = await _appDatabase.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
