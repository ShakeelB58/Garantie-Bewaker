import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'app_strings.dart';

/// Taal van de app: Nederlands als de telefoon op Nederlands staat,
/// anders Engels.
///
/// De keuze wordt bij het starten gemaakt ([apply]) en geldt voor de hele
/// app: schermen, meldingen, export en datum- en bedragnotatie.
abstract final class AppLocale {
  /// Talen die Material (datumkiezer e.d.) moet kennen.
  static const supported = [
    Locale('nl', 'NL'),
    Locale('nl', 'BE'),
    Locale('en', 'GB'),
    Locale('en', 'US'),
    Locale('en', 'IE'),
    Locale('en', 'AU'),
    Locale('en', 'CA'),
  ];

  static Locale _current = const Locale('nl', 'NL');

  /// De gekozen taal en regio, bijv. `nl_NL` of `en_GB`.
  static Locale get current => _current;

  static bool get isDutch => _current.languageCode == 'nl';

  /// Kiest de taal op basis van de taal van de telefoon.
  static Locale resolve(Locale device) {
    if (device.languageCode == 'nl') {
      return Locale('nl', device.countryCode == 'BE' ? 'BE' : 'NL');
    }
    if (device.languageCode == 'en') {
      final match = supported.where(
        (l) => l.languageCode == 'en' && l.countryCode == device.countryCode,
      );
      if (match.isNotEmpty) return match.first;
    }
    // Andere talen (of Engels zonder bekende regio): Brits Engels, met
    // Europese datumnotatie (dag-maand-jaar).
    return const Locale('en', 'GB');
  }

  /// Zet de taal van de app. Roep [initializeDateFormatting] vooraf aan.
  static void apply(Locale device) {
    _current = resolve(device);
    S.current = isDutch ? S.nl : S.en;
    Intl.defaultLocale = _intlName(_current);
  }

  static String _intlName(Locale locale) => locale.languageCode == 'nl'
      ? 'nl'
      : '${locale.languageCode}_${locale.countryCode}';
}
