import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/storage/app_database.dart';
import 'package:garantiebewaker/core/storage/migrations.dart';
import 'package:garantiebewaker/features/products/data/sqflite_product_repository.dart';
import 'package:garantiebewaker/features/products/domain/product_category.dart';
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
    test('modelnummer wordt opgeslagen en teruggelezen', () async {
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
      final product = makeProduct(
        modelNumber: 'WAN28297NL',
        serialNumber: 'FD9912-001234',
      );
      await repository.save(product);
      expect(await repository.getById(product.id), product);
    });

    test('bestaande database (versie 3) krijgt de kolom erbij', () async {
      final dir = Directory.systemTemp.createTempSync('gb_model');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = p.join(dir.path, 'test.db');
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) => Migrations.migrate(db, 0, 3),
        ),
      );
      await old.insert('products', {
        'id': 'p1',
        'name': 'Telefoon',
        'category': 'phone_tablet',
        'serial_number': '490154203237518',
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
      expect(loaded!.serialNumber, '490154203237518');
      expect(loaded.modelNumber, isNull);
      expect(
        await (await database.database).getVersion(),
        Migrations.latestVersion,
      );
    });
  });

  group('invoer', () {
    test('spaties weg, leeg wordt null, maximaal 64 tekens', () {
      final product = ProductInput(
        name: 'Wasmachine',
        modelNumber: '  WAN28297NL ',
        purchaseDate: testNow,
      ).toProduct(id: 'p1', createdAt: testNow, now: testNow);
      expect(product.modelNumber, 'WAN28297NL');

      final empty = ProductInput(
        name: 'Wasmachine',
        purchaseDate: testNow,
      ).toProduct(id: 'p1', createdAt: testNow, now: testNow);
      expect(empty.modelNumber, isNull);

      final errors = ProductValidator.validate(
        ProductInput(
          name: 'Wasmachine',
          modelNumber: 'A' * 65,
          purchaseDate: testNow,
        ),
        today: testNow,
      );
      expect(errors[ProductField.modelNumber], 'Gebruik maximaal 64 tekens.');
    });

    test('zoeken vindt het modelnummer', () {
      final products = [
        makeProduct(id: 'a', name: 'Wasmachine', modelNumber: 'WAN28297NL'),
        makeProduct(id: 'b', name: 'Laptop', modelNumber: 'KRN-14A'),
      ];
      final result = const ProductQuery(searchText: 'wan282').apply(products);
      expect(result.map((p) => p.id), ['a']);
    });

    test('alleen kleding en meubels zonder model- en serienummer', () {
      final without = ProductCategory.values
          .where((c) => !c.hasDeviceNumbers)
          .toSet();
      expect(without, {ProductCategory.clothing, ProductCategory.furniture});
    });
  });

  group('herkenning', () {
    const parser = ReceiptParser();
    final today = DateTime(2026, 10, 19);

    test('modelnummer met verschillende labels', () {
      expect(
        ReceiptParser.findModelNumber(['Model: SM-S921B']).value,
        'SM-S921B',
      );
      expect(
        ReceiptParser.findModelNumber(['Modelnummer WAN28297NL']).value,
        'WAN28297NL',
      );
      expect(
        ReceiptParser.findModelNumber(['Typenr. HD9252/90']).value,
        'HD9252/90',
      );
      expect(
        ReceiptParser.findModelNumber(['Type: KD-55X85L']).value,
        'KD-55X85L',
      );
      expect(ReceiptParser.findModelNumber(['Model No. A2337']).value, 'A2337');
    });

    test('geen modelnummer zonder label of zonder cijfer', () {
      for (final line in [
        'Type betaling: PIN',
        'Modelauto 1:18',
        'Laptop model 2026',
        'Model Nova',
        'WAN28297NL 649,00',
      ]) {
        expect(
          ReceiptParser.findModelNumber([line]).isFound,
          isFalse,
          reason: line,
        );
      }
    });

    test('factuur met model- en serienummer', () {
      final r = parser.parse('''
Elektro Noord
Factuurdatum: 14-10-2026
Wasmachine 649,00
Model: WAN28297NL
Serienummer: FD9912-001234
Totaal 649,00
''', today: today);
      expect(r.modelNumber.value, 'WAN28297NL');
      expect(r.modelNumber.confidence, RecognitionConfidence.medium);
      expect(r.serialNumber.value, 'FD9912-001234');
      expect(r.productName.value, 'Wasmachine');
    });
  });

  group('formulier', () {
    Future<void> openForm(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('nav.add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Handmatig invoeren'));
      await tester.pumpAndSettle();
    }

    Future<void> chooseCategory(WidgetTester tester, String label) async {
      final dropdown = find.byKey(const Key('productForm.category'));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    final model = find.byKey(const Key('productForm.modelNumber'));
    final serial = find.byKey(const Key('productForm.serialNumber'));

    testWidgets('velden weg bij kleding, terug bij elektronica', (
      tester,
    ) async {
      await openForm(tester);
      expect(model, findsOneWidget);
      expect(serial, findsOneWidget);

      await chooseCategory(tester, 'Kleding en schoenen');
      expect(model, findsNothing);
      expect(serial, findsNothing);

      await chooseCategory(tester, 'Elektronica');
      expect(model, findsOneWidget);
      expect(serial, findsOneWidget);
    });

    testWidgets('ingevuld nummer blijft zichtbaar bij kleding', (tester) async {
      await openForm(tester);
      await tester.ensureVisible(model);
      await tester.enterText(model, 'XY-123');
      await tester.pump();

      await chooseCategory(tester, 'Kleding en schoenen');
      expect(model, findsOneWidget);
      expect(serial, findsNothing);
    });

    testWidgets('modelnummer zien en kopiëren op het detailscherm', (
      tester,
    ) async {
      final repo = InMemoryProductRepository();
      await repo.save(
        makeProduct(id: 'p1', name: 'Wasmachine', modelNumber: 'WAN28297NL'),
      );
      await pumpApp(tester, repository: repo);
      await tester.tap(find.byKey(const Key('nav.products')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wasmachine'));
      await tester.pumpAndSettle();

      expect(find.text('Modelnummer'), findsOneWidget);
      expect(find.text('WAN28297NL'), findsOneWidget);
      expect(find.byKey(const Key('product.copyModel')), findsOneWidget);
    });
  });
}
