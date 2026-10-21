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
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final textScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: maxTextScale);
    // Breedte van het label meten zoals het getekend wordt.
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style:
            theme.floatingActionButtonTheme.extendedTextStyle ??
            theme.textTheme.labelLarge,
      ),
      textScaler: textScaler,
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    // Icoon, tussenruimte en binnenmarges van een uitgebreide knop.
    final estimated = painter.width + 72;
    painter.dispose();
    // 16 marge aan beide kanten van het scherm.
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
