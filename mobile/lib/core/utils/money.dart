import 'package:intl/intl.dart';

/// Geldbedragen worden altijd als gehele centen (`minor units`) opgeslagen.
abstract final class Money {
  /// Ondersteunde valuta in de app.
  static const supportedCurrencies = ['EUR', 'USD', 'GBP', 'CHF'];

  /// Zet een bedrag zoals het in Nederland wordt geschreven om naar centen.
  ///
  /// Voorbeelden die worden geaccepteerd:
  /// `1.299,00`, `1299,00`, `1299`, `12,5`, `€ 12,50`, `EUR 12,50`, `12.50`
  /// (punt met 1–2 cijfers erachter wordt als decimaalteken gezien).
  ///
  /// Geeft `null` terug als de tekst geen eenduidig bedrag is.
  static int? parseToMinor(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;

    text = text
        .replaceAll(RegExp(r'(EUR|eur|€)'), '')
        .replaceAll(RegExp(r'[\s\u00A0]'), '');
    if (text.startsWith('-')) return null;
    if (!RegExp(r'^[0-9.,]+$').hasMatch(text)) return null;

    String integerPart;
    String fractionPart;

    if (text.contains(',')) {
      // Komma is decimaalteken; punten zijn duizendtallen.
      if (','.allMatches(text).length > 1) return null;
      final parts = text.split(',');
      integerPart = parts[0];
      fractionPart = parts[1];
      if (fractionPart.isEmpty || fractionPart.length > 2) return null;
      if (fractionPart.contains('.')) return null;
      if (!_validThousands(integerPart)) return null;
      integerPart = integerPart.replaceAll('.', '');
    } else if (text.contains('.')) {
      final parts = text.split('.');
      final last = parts.last;
      if (parts.length == 2 && (last.length == 1 || last.length == 2)) {
        // `12.50`: punt als decimaalteken.
        integerPart = parts[0];
        fractionPart = last;
      } else {
        // `1.299` of `1.299.000`: punten als duizendtallen.
        if (!_validThousands(text)) return null;
        integerPart = text.replaceAll('.', '');
        fractionPart = '';
      }
    } else {
      integerPart = text;
      fractionPart = '';
    }

    if (integerPart.isEmpty) integerPart = '0';
    if (!RegExp(r'^\d+$').hasMatch(integerPart)) return null;
    if (fractionPart.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fractionPart)) {
      return null;
    }
    if (integerPart.length > 12) return null;

    final cents = int.parse(fractionPart.padRight(2, '0'));
    return int.parse(integerPart) * 100 + cents;
  }

  static bool _validThousands(String value) {
    if (!value.contains('.')) return true;
    return RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(value);
  }

  /// `€ 1.299,00`
  static String format(int minor, String currency) {
    final format = NumberFormat.simpleCurrency(locale: 'nl', name: currency);
    return format.format(minor / 100);
  }

  /// Notatie voor een invoerveld: `1299,00`.
  static String formatForInput(int minor) {
    final euros = minor ~/ 100;
    final cents = (minor % 100).toString().padLeft(2, '0');
    return '$euros,$cents';
  }
}
