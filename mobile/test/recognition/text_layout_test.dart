import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/recognition/domain/text_layout.dart';

TextBox box(String text, double left, double top, {double height = 0.03}) =>
    TextBox(
      text: text,
      left: left,
      top: top,
      right: left + 0.05 * text.length,
      bottom: top + height,
    );

void main() {
  test('kolommen op dezelfde hoogte worden één regel', () {
    // Zoals OCR een bon teruggeeft: eerst alle omschrijvingen, dan bedragen.
    final text = TextLayout.assemble([
      box('Waterkoker WK-200', 0.05, 0.40),
      box('Theedoek', 0.05, 0.45),
      box('29,99', 0.80, 0.402),
      box('3,49', 0.82, 0.448),
      box('TOTAAL', 0.05, 0.55),
      box('EUR 33,48', 0.70, 0.551),
    ]);
    expect(text.split('\n'), [
      'Waterkoker WK-200 29,99',
      'Theedoek 3,49',
      'TOTAAL EUR 33,48',
    ]);
  });

  test(
    'regels staan van boven naar beneden, woorden van links naar rechts',
    () {
      final text = TextLayout.assemble([
        box('onder', 0.1, 0.9),
        box('rechts', 0.6, 0.1),
        box('links', 0.1, 0.1),
      ]);
      expect(text, 'links rechts\nonder');
    },
  );

  test('losse tekens: spatie alleen bij een duidelijk gat', () {
    // Tekens van 6 breed en 10 hoog; tussen "Bon" en "42" zit een gat.
    TextBox char(String c, double left) =>
        TextBox(text: c, left: left, top: 0, right: left + 6, bottom: 10);
    final text = TextLayout.assemble([
      char('B', 0),
      char('o', 6.5),
      char('n', 13),
      char('4', 30),
      char('2', 36.5),
    ], characterLevel: true);
    expect(text, 'Bon 42');
  });

  test('lege blokken en blokken zonder hoogte worden overgeslagen', () {
    expect(TextLayout.assemble([]), '');
    expect(
      TextLayout.assemble([
        box('  ', 0.1, 0.1),
        const TextBox(text: 'x', left: 0, top: 0.2, right: 0.1, bottom: 0.2),
      ]),
      '',
    );
  });
}
