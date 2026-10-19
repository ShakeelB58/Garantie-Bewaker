import 'package:sqflite/sqflite.dart';

/// Schemamigraties van de lokale database.
///
/// Regels:
/// - Een uitgebrachte migratie wordt nooit meer gewijzigd; voeg een nieuwe toe.
/// - Datums: `yyyy-MM-dd`. Tijdstippen: ISO 8601 in UTC (`...Z`), behalve
///   `reminders.trigger_at`: dat is lokale wandklok-tijd zonder tijdzone,
///   omdat een herinnering om "09:00 in Nederland" moet afgaan.
/// - Geldbedragen in gehele centen.
abstract final class Migrations {
  static const latestVersion = 1;

  static final Map<int, List<String>> _steps = {
    1: [
      '''
      CREATE TABLE products (
        id                    TEXT PRIMARY KEY NOT NULL,
        name                  TEXT NOT NULL CHECK (length(trim(name)) > 0),
        brand                 TEXT,
        category              TEXT NOT NULL,
        merchant              TEXT,
        purchase_date         TEXT NOT NULL,
        purchase_price_minor  INTEGER CHECK (purchase_price_minor IS NULL OR purchase_price_minor >= 0),
        currency              TEXT NOT NULL DEFAULT 'EUR',
        warranty_end_date     TEXT,
        reminder_enabled      INTEGER NOT NULL DEFAULT 0 CHECK (reminder_enabled IN (0, 1)),
        created_at            TEXT NOT NULL,
        updated_at            TEXT NOT NULL
      )
      ''',
      'CREATE INDEX idx_products_purchase_date ON products (purchase_date)',
      'CREATE INDEX idx_products_category ON products (category)',
      '''
      CREATE TABLE documents (
        id                 TEXT PRIMARY KEY NOT NULL,
        product_id         TEXT NOT NULL REFERENCES products (id) ON DELETE CASCADE,
        file_path          TEXT NOT NULL,
        document_type      TEXT NOT NULL,
        original_filename  TEXT,
        mime_type          TEXT NOT NULL,
        created_at         TEXT NOT NULL
      )
      ''',
      'CREATE INDEX idx_documents_product ON documents (product_id)',
      '''
      CREATE TABLE reminders (
        id               TEXT PRIMARY KEY NOT NULL,
        product_id       TEXT NOT NULL REFERENCES products (id) ON DELETE CASCADE,
        trigger_at       TEXT NOT NULL,
        notification_id  INTEGER,
        enabled          INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0, 1)),
        created_at       TEXT NOT NULL
      )
      ''',
      'CREATE INDEX idx_reminders_product ON reminders (product_id)',
    ],
  };

  /// Voert alle stappen uit na [fromVersion] tot en met [toVersion].
  static Future<void> migrate(
    Database db,
    int fromVersion,
    int toVersion,
  ) async {
    final batch = db.batch();
    for (var version = fromVersion + 1; version <= toVersion; version++) {
      final statements = _steps[version];
      if (statements == null) {
        throw StateError('Geen migratie gevonden voor versie $version');
      }
      for (final sql in statements) {
        batch.execute(sql);
      }
    }
    await batch.commit(noResult: true);
  }
}
