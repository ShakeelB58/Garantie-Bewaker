/// Hulpfuncties voor IMEI-nummers van telefoons.
///
/// Een IMEI heeft 15 cijfers; het laatste is een controlecijfer (Luhn).
/// Zo kunnen typfouten worden opgemerkt. De app stuurt het nummer nergens heen.
abstract final class Imei {
  /// Alleen de cijfers, zonder spaties, streepjes of schuine strepen.
  static String digitsOf(String value) =>
      value.replaceAll(RegExp(r'[\s\-/.]'), '');

  /// Ziet de invoer eruit als een IMEI (precies 15 cijfers)?
  static bool looksLikeImei(String value) =>
      RegExp(r'^\d{15}$').hasMatch(digitsOf(value));

  /// Klopt het controlecijfer van een IMEI van 15 cijfers?
  static bool isValid(String value) {
    final digits = digitsOf(value);
    if (!RegExp(r'^\d{15}$').hasMatch(digits)) return false;
    var sum = 0;
    for (var i = 0; i < digits.length; i++) {
      var d = digits.codeUnitAt(i) - 48;
      // Vanaf links: elk tweede cijfer verdubbelen.
      if (i.isOdd) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
    }
    return sum % 10 == 0;
  }
}
