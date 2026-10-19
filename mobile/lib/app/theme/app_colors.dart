import 'package:flutter/painting.dart';

/// Kleurenpalet van GarantieBewaker.
///
/// Contrastverhoudingen (WCAG 2.x) zijn gecontroleerd in
/// `test/theme_contrast_test.dart`; minimaal 4,5:1 voor gewone tekst.
abstract final class AppColors {
  /// Donkerblauw voor primaire tekst. Contrast op wit: 14,6:1.
  static const navy = Color(0xFF0F2A44);

  /// Gedempt blauwgrijs voor secundaire tekst. Contrast op wit: 7,0:1.
  static const textMuted = Color(0xFF4A5B6E);

  /// Blauwgroen accent voor knoppen en actieve elementen. Contrast met wit: 5,2:1.
  static const teal = Color(0xFF0B7A75);

  /// Lichte variant van het accent, voor achtergronden van iconen en labels.
  static const tealContainer = Color(0xFFCDEFEC);

  /// Lichte achtergrond van schermen.
  static const background = Color(0xFFF5F7FA);

  /// Kaarten en vlakken.
  static const surface = Color(0xFFFFFFFF);

  /// Subtiele randen en scheidingslijnen.
  static const border = Color(0xFFE1E7EE);

  /// Waarschuwingen en destructieve acties.
  static const error = Color(0xFFB3261E);

  /// Onzeker herkende velden. Contrast op wit: 6,3:1.
  static const warning = Color(0xFF8A5300);
}
