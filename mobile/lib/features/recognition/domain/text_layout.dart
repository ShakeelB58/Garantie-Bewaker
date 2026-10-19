/// Een stukje tekst met zijn positie. Coördinaten met de oorsprong
/// linksboven (y loopt naar beneden), in willekeurige maar consistente eenheden.
class TextBox {
  const TextBox({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get height => (bottom - top).abs();
  double get centerY => (top + bottom) / 2;
}

/// Zet losse tekstblokken (OCR-regels of PDF-tekens) om naar tekst met één
/// regel per printregel.
///
/// OCR-engines geven kolommen van een bon vaak los terug ("Theedoek" en
/// "3,49" als aparte blokken). Door blokken op dezelfde hoogte samen te
/// voegen, staan omschrijving en bedrag weer op één regel.
abstract final class TextLayout {
  /// [characterLevel]: `true` voor losse tekens (PDF); dan wordt alleen een
  /// spatie ingevoegd bij een duidelijk gat. `false` voor hele regels/woorden
  /// (OCR); dan komt er altijd een spatie tussen.
  static String assemble(List<TextBox> boxes, {bool characterLevel = false}) {
    final usable = boxes
        .where((b) => b.text.trim().isNotEmpty && b.height > 0)
        .toList()
      ..sort((a, b) => a.centerY.compareTo(b.centerY));
    if (usable.isEmpty) return '';

    final rows = <_Row>[];
    for (final box in usable) {
      final row = rows.isEmpty ? null : rows.last;
      if (row != null && row.accepts(box)) {
        row.add(box);
      } else {
        rows.add(_Row(box));
      }
    }

    return rows.map((r) => r.render(characterLevel: characterLevel)).join('\n');
  }
}

class _Row {
  _Row(TextBox first) : _boxes = [first], _centerY = first.centerY;

  final List<TextBox> _boxes;
  double _centerY;

  double get _height =>
      _boxes.map((b) => b.height).reduce((a, b) => a + b) / _boxes.length;

  /// Zelfde regel als het midden binnen de halve regelhoogte ligt.
  bool accepts(TextBox box) {
    final tolerance =
        0.5 * (box.height < _height ? box.height : _height);
    return (box.centerY - _centerY).abs() <= tolerance;
  }

  void add(TextBox box) {
    _boxes.add(box);
    _centerY =
        _boxes.map((b) => b.centerY).reduce((a, b) => a + b) / _boxes.length;
  }

  String render({required bool characterLevel}) {
    final sorted = [..._boxes]..sort((a, b) => a.left.compareTo(b.left));
    final buffer = StringBuffer(sorted.first.text.trim());
    for (var i = 1; i < sorted.length; i++) {
      final previous = sorted[i - 1];
      final current = sorted[i];
      if (characterLevel) {
        final gap = current.left - previous.right;
        if (gap > 0.25 * _height) buffer.write(' ');
        buffer.write(current.text.trim());
      } else {
        buffer
          ..write(' ')
          ..write(current.text.trim());
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
