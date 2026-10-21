import 'package:flutter/material.dart';

/// Zwevende knop om een aankoop toe te voegen.
///
/// Bij heel grote tekst (toegankelijkheidsinstellingen) groeit het label
/// maximaal tot 150%, zodat de knop binnen het scherm blijft. Is het scherm
/// daarvoor te smal, dan wordt het een ronde knop met alleen een plusteken;
/// schermlezers lezen dan de tooltip voor.
class AddFab extends StatelessWidget {
  const AddFab({
    required this.heroTag,
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// Elke knop een eigen tag: meerdere tabbladen staan tegelijk in de boom.
  final String heroTag;
  final String label;
  final VoidCallback onPressed;

  static const maxTextScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final width = MediaQuery.sizeOf(context).width;
    // Geschatte breedte van de knop met label (icoon, marges, tekst).
    final labelScale = scale.clamp(1.0, maxTextScale);
    final estimated = 80 + label.length * 9.5 * labelScale;
    if (estimated > width - 32) {
      return FloatingActionButton(
        heroTag: heroTag,
        tooltip: label,
        onPressed: onPressed,
        child: const Icon(Icons.add),
      );
    }
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(label),
      ),
    );
  }
}
