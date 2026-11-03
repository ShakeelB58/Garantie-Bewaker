import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/storage/app_database.dart';
import 'package:garantiebewaker/core/storage/migrations.dart';
import 'package:garantiebewaker/features/data_management/domain/products_csv.dart';
import 'package:garantiebewaker/features/products/data/sqflite_product_repository.dart';
import 'package:garantiebewaker/features/products/domain/product_input.dart';
import 'package:garantiebewaker/features/products/domain/product_query.dart';
import 'package:garantiebewaker/features/recognition/domain/parsed_receipt.dart';
import 'package:garantiebewaker/features/recognition/domain/receipt_parser.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/test_app.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  group('opslag', () {
    test('serienummer wordt opgeslagen en teruggelezen', () async {
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        pathProvider: () async => inMemoryDatabasePath,
      );
      addTearDown(database.close);
      var id = 0;
      final repository = SqfliteProductRepository(
        database,
        newId: () => 'r${id++}',
        clock: () => testNow,
      );
      final product = makeProduct(serialNumber: '490154203237518');
      await repository.save(product);
      expect(await repository.getById(product.id), product);
    });

    test('bestaande database (versie 2) krijgt de kolom erbij', () async {
      final dir = Directory.systemTemp.createTempSync('gb_serie');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = p.join(dir.path, 'test.db');
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) => Migrations.migrate(db, 0, 2),
        ),
      );
      await old.insert('products', {
        'id': 'p1',
        'name': 'Telefoon',
        'category': 'phone_tablet',
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
      final repository = SqfliteProductRepository(
        database,
        newId: () => 'x',
        clock: () => testNow,
      );
      final loaded = await repository.getById('p1');
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Telefoon');
      expect(loaded.serialNumber, isNull);
      expect(
        await (await database.database).getVersion(),
        Migrations.latestVersion,
      );
    });
  });

  group('invoer', () {
    test('wordt bijgesneden en is optioneel', () {
      final product = ProductInput(
        name: 'Telefoon',
        purchaseDate: testNow,
        serialNumber: '  490154203237518 ',
      ).toProduct(id: 'a', createdAt: testNow, now: testNow);
      expect(product.serialNumber, '490154203237518');
      final empty = ProductInput(
        name: 'Telefoon',
        purchaseDate: testNow,
      ).toProduct(id: 'a', createdAt: testNow, now: testNow);
      expect(empty.serialNumber, isNull);
    });

    test('maximaal 64 tekens', () {
      final errors = ProductValidator.validate(
        ProductInput(
          name: 'Telefoon',
          purchaseDate: testNow,
          serialNumber: 'A' * 65,
        ),
        today: testNow,
      );
      expect(errors[ProductField.serialNumber], 'Gebruik maximaal 64 tekens.');
    });
  });

  test('zoeken op serienummer', () {
    final products = [
      makeProduct(id: 'a', name: 'Telefoon', serialNumber: '490154203237518'),
      makeProduct(id: 'b', name: 'Laptop', serialNumber: 'KRN14-2026-0042'),
    ];
    List<String> ids(String text) => ProductQuery(
      searchText: text,
    ).apply(products).map((p) => p.id).toList();
    expect(ids('4901542'), ['a']);
    expect(ids('krn14'), ['b']);
  });

  test('export bevat het serienummer', () {
    final csv = ProductsCsv.build([
      makeProduct(serialNumber: '490154203237518'),
    ], const {});
    expect(csv, contains(';490154203237518;'));
  });

  group('herkenning', () {
    const parser = ReceiptParser();
    final today = DateTime(2026, 10, 19);
    ParsedReceipt parse(String text) => parser.parse(text, today: today);

    test('IMEI met label en kloppend controlecijfer: hoge zekerheid', () {
      final r = parse('''
Elektro Noord
Factuur 19-10-2026
Smartphone Nova 9 799,00
IMEI: 49 015420 323751 8
Totaal 799,00
''');
      expect(r.serialNumber.value, '490154203237518');
      expect(r.serialNumber.confidence, RecognitionConfidence.high);
    });

    test('IMEI met verkeerd controlecijfer: onzeker', () {
      final r = parse('''
Factuur 19-10-2026
Smartphone 799,00
IMEI-nummer 490154203237519
Totaal 799,00
''');
      expect(r.serialNumber.value, '490154203237519');
      expect(r.serialNumber.confidence, RecognitionConfidence.low);
    });

    test('serienummer met S/N of Serienummer', () {
      expect(
        parse('Datum 19-10-2026\nLaptop 1.099,00\nS/N: c02xk1abcd\nTotaal 1.099,00')
            .serialNumber
            .value,
        'C02XK1ABCD',
      );
      final r = parse(
        'Datum 19-10-2026\nKoptelefoon 149,00\nSerienummer: SNR-7731-4420\nTotaal 149,00',
      );
      expect(r.serialNumber.value, 'SNR-7731-4420');
      expect(r.serialNumber.confidence, RecognitionConfidence.medium);
    });

    test('zonder label wordt niets gegokt', () {
      final r = parse('Datum 19-10-2026\nKassa 4 bon 490154203237518\nTotaal 9,99');
      expect(r.serialNumber.isFound, isFalse);
      final sn = parse('Datum 19-10-2026\nSN Bakkerij 1234\nTotaal 3,50');
      expect(sn.serialNumber.isFound, isFalse);
    });
  });

  group('schermen', () {
    testWidgets('serienummer invullen, zien en kopiëren', (tester) async {
      final repo = InMemoryProductRepository();
      await repo.save(
        makeProduct(id: 'p1', name: 'Telefoon', serialNumber: '490154203237518'),
      );
      await pumpApp(tester, repository: repo);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.tap(find.byKey(const Key('nav.products')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Telefoon'));
      await tester.pumpAndSettle();

      expect(find.text('490154203237518'), findsOneWidget);
      await tester.tap(find.byKey(const Key('product.copySerial')));
      await tester.pumpAndSettle();
      expect(copied, '490154203237518');
      expect(find.text('Serienummer of IMEI gekopieerd.'), findsOneWidget);
    });

    testWidgets('formulier waarschuwt bij een IMEI met een typfout', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('nav.add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Handmatig invoeren'));
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('productForm.serialNumber'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '490154203237519');
      await tester.pump();
      expect(find.textContaining('controlecijfer klopt niet'), findsOneWidget);

      await tester.enterText(field, '490154203237518');
      await tester.pump();
      expect(find.textContaining('controlecijfer klopt niet'), findsNothing);
    });
  });
}
