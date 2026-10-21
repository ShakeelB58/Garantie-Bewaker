import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';
import '../helpers/test_app.dart';

/// Automatische toegankelijkheidscontroles van Flutter:
/// - knoppen zijn groot genoeg om aan te tikken (48×48 Android, 44×44 iOS)
/// - elke knop heeft een naam voor schermlezers (VoiceOver, TalkBack)
/// - tekst heeft genoeg contrast met de achtergrond
void main() {
  Future<void> checkScreen(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  InMemoryProductRepository products() => InMemoryProductRepository([
    makeProduct(
      name: 'Koelkast',
      warrantyEndDate: DateTime(2028, 10, 19),
      reminderEnabled: true,
      reminderDate: DateTime(2026, 10, 25),
    ),
  ]);

  testWidgets('leeg overzicht', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await checkScreen(tester);
    handle.dispose();
  });

  testWidgets('overzicht met producten', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, repository: products());
    await checkScreen(tester);
    handle.dispose();
  });

  testWidgets('productenlijst', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, repository: products());
    await tester.tap(find.text('Producten'));
    await tester.pumpAndSettle();
    await checkScreen(tester);
    handle.dispose();
  });

  testWidgets('productdetails', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, repository: products());
    await tester.tap(find.text('Producten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koelkast'));
    await tester.pumpAndSettle();
    await checkScreen(tester);
    handle.dispose();
  });

  testWidgets('aankoop toevoegen', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await tester.tap(find.text('Aankoop toevoegen'));
    await tester.pumpAndSettle();
    await checkScreen(tester);
    handle.dispose();
  });

  testWidgets('productformulier', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await tester.tap(find.text('Aankoop toevoegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Handmatig invoeren'));
    await tester.pumpAndSettle();
    await checkScreen(tester);
    handle.dispose();
  });

  testWidgets('instellingen', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await tester.tap(find.text('Instellingen'));
    await tester.pumpAndSettle();
    await checkScreen(tester);
    handle.dispose();
  });

  testWidgets('productkaart wordt als één knop voorgelezen', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, repository: products());
    await tester.tap(find.text('Producten'));
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.text('Koelkast'));
    expect(node.label, contains('Koelkast'));
    expect(node.label, contains('MediaMarkt'));
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    handle.dispose();
  });
}
