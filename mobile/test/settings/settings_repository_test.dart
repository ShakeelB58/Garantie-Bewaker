import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/storage/app_database.dart';
import 'package:garantiebewaker/core/storage/migrations.dart';
import 'package:garantiebewaker/features/settings/application/settings_providers.dart';
import 'package:garantiebewaker/features/settings/data/settings_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('voorkeur opslaan, overschrijven en teruglezen', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      pathProvider: () async => inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final repository = SqfliteSettingsRepository(database);

    expect(await repository.read('reminder_lead_days'), isNull);
    await repository.write('reminder_lead_days', '14');
    await repository.write('reminder_lead_days', '60');
    expect(await repository.read('reminder_lead_days'), '60');
  });

  test(
    'bestaande database (versie 1) wordt bijgewerkt zonder dataverlies',
    () async {
      final dir = Directory.systemTemp.createTempSync('gb_migratie');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = p.join(dir.path, 'test.db');

      // Database zoals de app die vóór fase 5 aanmaakte.
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) => Migrations.migrate(db, 0, 1),
        ),
      );
      await old.insert('products', {
        'id': 'p1',
        'name': 'Wasmachine',
        'category': 'household',
        'purchase_date': '2026-09-30',
        'currency': 'EUR',
        'created_at': '2026-10-01T12:00:00.000Z',
        'updated_at': '2026-10-01T12:00:00.000Z',
      });
      await old.close();

      final database = AppDatabase(
        factory: databaseFactoryFfi,
        pathProvider: () async => path,
      );
      addTearDown(database.close);
      final db = await database.database;

      expect(await db.getVersion(), Migrations.latestVersion);
      expect(await db.query('products'), hasLength(1));
      await SqfliteSettingsRepository(database).write('x', 'y');
      expect(await SqfliteSettingsRepository(database).read('x'), 'y');
    },
  );

  test('onbekende of ontbrekende waarde valt terug op 1 maand', () {
    expect(ReminderLead.fromDays(null), ReminderLead.oneMonth);
    expect(ReminderLead.fromDays(5), ReminderLead.oneMonth);
    expect(ReminderLead.fromDays(14), ReminderLead.twoWeeks);
    expect(
      ReminderLead.twoMonths.description,
      '2 maanden vóór de garantie-einddatum',
    );
  });
}
