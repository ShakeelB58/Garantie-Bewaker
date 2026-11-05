import 'package:intl/intl.dart';

import '../../l10n/app_locale.dart';

/// Geldbedragen worden altijd als gehele centen (`minor units`) opgeslagen.
abstract final class Money {
  /// Ondersteunde valuta in de app.
  static const supportedCurrencies = ['EUR', 'USD', 'GBP', 'CHF'];

  /// Zet een ingevuld bedrag om naar centen.
  ///
  /// Voorbeelden die worden geaccepteerd:
  /// `1.299,00`, `1299,00`, `1299`, `12,5`, `€ 12,50`, `EUR 12,50`, `12.50`,
  /// `1,299.00`, `£ 9.99`, `\$1,299` (Engelse notatie).
  ///
  /// Staan er een punt en een komma in, dan is het laatste teken het
  /// decimaalteken. Een punt met 1–2 cijfers erachter is een decimaalteken.
  /// `1,299` (komma met precies 3 cijfers) geldt in het Engels als duizendtal
  /// en is in het Nederlands ongeldig.
  ///
  /// Geeft `null` terug als de tekst geen eenduidig bedrag is.
  static int? parseToMinor(String input, {bool? dutch}) {
    final isDutch = dutch ?? AppLocale.isDutch;
    var text = input.trim();
    if (text.isEmpty) return null;

    text = text
        .replaceAll(
          RegExp(r'(EUR|USD|GBP|CHF|€|\$|£)', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'[\s\u00A0]'), '');
    if (text.startsWith('-')) return null;
    if (!RegExp(r'^[0-9.,]+$').hasMatch(text)) return null;

    String integerPart;
    String fractionPart;

    final lastComma = text.lastIndexOf(',');
    final lastDot = text.lastIndexOf('.');

    if (lastComma >= 0 && lastDot >= 0) {
      // Beide tekens: het laatste is het decimaalteken.
      final decimal = lastComma > lastDot ? ',' : '.';
      final thousands = decimal == ',' ? '.' : ',';
      if (decimal.allMatches(text).length > 1) return null;
      final parts = text.split(decimal);
      integerPart = parts[0];
      fractionPart = parts[1];
      if (fractionPart.isEmpty || fractionPart.length > 2) return null;
      if (!_validThousands(integerPart, thousands)) return null;
      integerPart = integerPart.replaceAll(thousands, '');
    } else if (lastComma >= 0) {
      if (!isDutch && RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(text)) {
        // Engels: `1,299` = duizend tweehonderdnegenennegentig.
        integerPart = text.replaceAll(',', '');
        fractionPart = '';
      } else {
        // Komma is decimaalteken.
        if (','.allMatches(text).length > 1) return null;
        final parts = text.split(',');
        integerPart = parts[0];
        fractionPart = parts[1];
        if (fractionPart.isEmpty || fractionPart.length > 2) return null;
      }
    } else if (lastDot >= 0) {
      final parts = text.split('.');
      final last = parts.last;
      if (parts.length == 2 && (last.length == 1 || last.length == 2)) {
        // `12.50`: punt als decimaalteken.
        integerPart = parts[0];
        fractionPart = last;
      } else {
        // `1.299` of `1.299.000`: punten als duizendtallen.
        if (!_validThousands(text, '.')) return null;
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

  static bool _validThousands(String value, String separator) {
    if (!value.contains(separator)) return true;
    final sep = RegExp.escape(separator);
    return RegExp('^\\d{1,3}($sep\\d{3})+\$').hasMatch(value);
  }

  /// `€ 1.299,00` (Nederlands) of `€1,299.00` (Engels).
  static String format(int minor, String currency) {
    final format = NumberFormat.simpleCurrency(
      locale: Intl.defaultLocale,
      name: currency,
    );
    return format.format(minor / 100);
  }

  /// Notatie voor een invoerveld: `1299,00` (Nederlands) of `1299.00`.
  static String formatForInput(int minor, {bool? dutch}) {
    final euros = minor ~/ 100;
    final cents = (minor % 100).toString().padLeft(2, '0');
    return (dutch ?? AppLocale.isDutch) ? '$euros,$cents' : '$euros.$cents';
  }
}
