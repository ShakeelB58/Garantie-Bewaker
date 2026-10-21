import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/utils/dates.dart';

void main() {
  test('ISO-datum heen en terug', () {
    final date = DateTime(2026, 2, 3);
    expect(Dates.toIsoDate(date), '2026-02-03');
    expect(Dates.parseIsoDate('2026-02-03'), date);
  });

  test('ongeldige datums worden geweigerd', () {
    expect(() => Dates.parseIsoDate('2026-02-30'), throwsFormatException);
    expect(() => Dates.parseIsoDate('19-10-2026'), throwsFormatException);
    expect(() => Dates.parseIsoDate(''), throwsFormatException);
  });

  test('dateOnly verwijdert de tijd', () {
    expect(
      Dates.dateOnly(DateTime(2026, 10, 19, 23, 59)),
      DateTime(2026, 10, 19),
    );
  });

  test('daysBetween telt kalenderdagen, ook rond zomertijd', () {
    // Op 25 oktober 2026 gaat in Nederland de wintertijd in.
    expect(
      Dates.daysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 26)),
      2,
    );
    expect(
      Dates.daysBetween(DateTime(2026, 10, 26), DateTime(2026, 10, 24)),
      -2,
    );
    expect(
      Dates.daysBetween(DateTime(2026, 10, 19, 23), DateTime(2026, 10, 20, 1)),
      1,
    );
  });

  test('Nederlandse notatie', () {
    expect(Dates.formatLong(DateTime(2026, 10, 19)), '19 oktober 2026');
    expect(Dates.formatShort(DateTime(2026, 10, 19)), contains('okt'));
  });
}
