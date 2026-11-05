import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/utils/dates.dart';
import 'package:garantiebewaker/core/utils/money.dart';
import 'package:garantiebewaker/features/products/domain/product_category.dart';
import 'package:garantiebewaker/l10n/app_locale.dart';
import 'package:garantiebewaker/l10n/app_strings.dart';

import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/test_app.dart';

void main() {
  group('taalkeuze', () {
    test('Nederlands op een Nederlandse of Belgische telefoon', () {
      expect(
        AppLocale.resolve(const Locale('nl', 'NL')),
        const Locale('nl', 'NL'),
      );
      expect(
        AppLocale.resolve(const Locale('nl', 'BE')),
        const Locale('nl', 'BE'),
      );
      expect(AppLocale.resolve(const Locale('nl')), const Locale('nl', 'NL'));
    });

    test('Engels voor Engelse en alle andere talen', () {
      expect(
        AppLocale.resolve(const Locale('en', 'US')),
        const Locale('en', 'US'),
      );
      expect(
        AppLocale.resolve(const Locale('en', 'GB')),
        const Locale('en', 'GB'),
      );
      expect(AppLocale.resolve(const Locale('en')), const Locale('en', 'GB'));
      expect(
        AppLocale.resolve(const Locale('de', 'DE')),
        const Locale('en', 'GB'),
      );
      expect(
        AppLocale.resolve(const Locale('fr', 'BE')),
        const Locale('en', 'GB'),
      );
    });
  });

  group('in het Engels', () {
    setUp(() => AppLocale.apply(const Locale('en', 'GB')));
    tearDown(() => AppLocale.apply(const Locale('nl', 'NL')));

    test('teksten, categorieën en datums', () {
      expect(S.current.save, 'Save');
      expect(ProductCategory.phoneTablet.label, 'Phone and tablet');
      expect(Dates.formatShort(DateTime(2026, 10, 19)), '19 Oct 2026');
      expect(Dates.formatLong(DateTime(2026, 10, 19)), '19 October 2026');
    });

    test('bedragen invullen en tonen', () {
      expect(Money.parseToMinor('1,299.00'), 129900);
      expect(Money.parseToMinor('1,299'), 129900);
      expect(Money.parseToMinor('£ 9.99'), 999);
      expect(Money.parseToMinor('\$1,299.50'), 129950);
      expect(Money.formatForInput(129900), '1299.00');
      expect(Money.format(129900, 'EUR'), '€1,299.00');
    });

    testWidgets('de app is Engels', (tester) async {
      final repo = InMemoryProductRepository();
      await repo.save(makeProduct(name: 'Washing machine'));
      await pumpApp(tester, repository: repo);

      expect(find.text('Good morning,'), findsOneWidget);
      expect(find.text('You have 1 product registered.'), findsOneWidget);
      expect(find.text('Recently added'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav.settings')));
      await tester.pumpAndSettle();
      expect(find.text('Export data'), findsOneWidget);
      expect(find.text('Delete all local data'), findsOneWidget);
    });
  });

  test('Nederlandse bedragen blijven werken', () {
    expect(Money.parseToMinor('1.299,00'), 129900);
    expect(Money.parseToMinor('1,299'), isNull);
    expect(Money.formatForInput(129900), '1299,00');
  });
}
