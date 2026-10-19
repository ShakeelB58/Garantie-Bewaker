import 'package:intl/intl.dart';

/// Hulpfuncties voor kalenderdatums (zonder tijd).
///
/// Kalenderdatums worden opgeslagen als ISO 8601-datum (`yyyy-MM-dd`) en in
/// de app weergegeven als lokale [DateTime] om middernacht.
abstract final class Dates {
  /// Alleen jaar, maand en dag; tijd wordt verwijderd.
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// `2026-10-19`
  static String toIsoDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Leest `yyyy-MM-dd`. Gooit [FormatException] bij een ongeldige datum.
  static DateTime parseIsoDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('Ongeldige datum', value);
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw FormatException('Ongeldige datum', value);
    }
    return date;
  }

  /// Aantal kalenderdagen van [from] tot [to] (negatief als [to] eerder is).
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// `19 okt. 2026`
  static String formatShort(DateTime value) =>
      DateFormat.yMMMd('nl').format(value);

  /// `19 oktober 2026`
  static String formatLong(DateTime value) =>
      DateFormat.yMMMMd('nl').format(value);
}
