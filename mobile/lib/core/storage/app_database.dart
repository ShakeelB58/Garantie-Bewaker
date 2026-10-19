import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

/// Toegang tot de lokale SQLite-database van de app.
///
/// De database staat in de app-private opslag van het toestel en wordt pas
/// geopend bij het eerste gebruik.
class AppDatabase {
  AppDatabase({
    required DatabaseFactory factory,
    required Future<String> Function() pathProvider,
  }) : _factory = factory,
       _pathProvider = pathProvider;

  /// Database op het toestel (iOS/Android).
  factory AppDatabase.device() => AppDatabase(
    factory: databaseFactory,
    pathProvider: () async => p.join(await getDatabasesPath(), fileName),
  );

  static const fileName = 'garantiebewaker.db';

  final DatabaseFactory _factory;
  final Future<String> Function() _pathProvider;
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final path = await _pathProvider();
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: Migrations.latestVersion,
        onConfigure: (db) async {
          // Nodig voor ON DELETE CASCADE: SQLite staat dit standaard uit.
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) => Migrations.migrate(db, 0, version),
        onUpgrade: (db, oldVersion, newVersion) =>
            Migrations.migrate(db, oldVersion, newVersion),
        onDowngrade: (db, oldVersion, newVersion) {
          throw StateError(
            'Database-versie $oldVersion is nieuwer dan deze app '
            '($newVersion).',
          );
        },
      ),
    );
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    if (db != null) await (await db).close();
  }
}
