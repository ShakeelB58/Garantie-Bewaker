import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/app/app.dart';
import 'package:garantiebewaker/core/storage/storage_providers.dart';
import 'package:garantiebewaker/features/products/application/product_providers.dart';

import 'fixtures.dart';
import 'in_memory_product_repository.dart';

/// Start de volledige app met een in-memory database en een vaste klok.
Future<InMemoryProductRepository> pumpApp(
  WidgetTester tester, {
  InMemoryProductRepository? repository,
}) async {
  // Een hoog scherm, zodat het hele formulier zichtbaar is.
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repo = repository ?? InMemoryProductRepository();
  var nextId = 0;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(() => testNow),
        idGeneratorProvider.overrideWithValue(() => 'id-${nextId++}'),
      ],
      child: const GarantieBewakerApp(),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// Tikt op de terugknop in de AppBar.
///
/// `tester.pageBack()` zoekt naar de Engelse tooltip "Back"; deze app is
/// Nederlandstalig, dus zoeken we de tooltip via de lokalisatie op.
Future<void> tapBack(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).last);
  final tooltip = MaterialLocalizations.of(context).backButtonTooltip;
  await tester.tap(find.byTooltip(tooltip).last);
  await tester.pumpAndSettle();
}
