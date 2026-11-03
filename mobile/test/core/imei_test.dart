import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/utils/imei.dart';

void main() {
  test('geldig IMEI (bekend voorbeeldnummer)', () {
    expect(Imei.isValid('490154203237518'), isTrue);
    expect(Imei.isValid('49 015420 323751 8'), isTrue);
    expect(Imei.isValid('49-015420-323751-8'), isTrue);
  });

  test('typfout in het controlecijfer wordt herkend', () {
    expect(Imei.isValid('490154203237519'), isFalse);
    expect(Imei.looksLikeImei('490154203237519'), isTrue);
  });

  test('geen IMEI: te kort, te lang of met letters', () {
    expect(Imei.looksLikeImei('49015420323751'), isFalse);
    expect(Imei.looksLikeImei('4901542032375180'), isFalse);
    expect(Imei.looksLikeImei('C02XK1ABCD'), isFalse);
    expect(Imei.isValid('C02XK1ABCD'), isFalse);
  });
}
