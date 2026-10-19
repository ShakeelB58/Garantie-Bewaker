import 'dart:typed_data';

import 'package:text_sight/text_sight.dart';

import '../../../core/errors/user_message.dart';
import '../domain/text_layout.dart';

/// Tekstherkenning (OCR) op het toestel.
abstract interface class TextRecognizer {
  /// Tekst uit een afbeeldingsbestand, één regel per printregel.
  Future<String> recognizeFile(String path);

  /// Tekst uit gecodeerde afbeeldingsbytes (JPEG/PNG).
  Future<String> recognizeBytes(Uint8List encodedImage);
}

/// Apple Vision (iOS) en Google ML Kit (Android) via `text_sight`.
/// Alles draait op het toestel; er wordt niets naar een server gestuurd.
class TextSightRecognizer implements TextRecognizer {
  bool _modelChecked = false;

  Future<void> _ensureModel() async {
    if (_modelChecked) return;
    // Op Android downloadt ML Kit het model bij het eerste gebruik.
    final state = await TextSightModel.ensureReady();
    if (state is ModelUnavailable) {
      throw const AppException(
        'Tekstherkenning is nog niet beschikbaar op deze telefoon. '
        'Controleer de internetverbinding en probeer het later opnieuw, '
        'of vul de gegevens zelf in.',
      );
    }
    _modelChecked = true;
  }

  @override
  Future<String> recognizeFile(String path) async {
    await _ensureModel();
    return _toText(await TextSight.recognizePath(path));
  }

  @override
  Future<String> recognizeBytes(Uint8List encodedImage) async {
    await _ensureModel();
    return _toText(await TextSight.recognizeImage(encodedImage));
  }

  static String _toText(TextSightCapture capture) {
    // Coördinaten zijn genormaliseerd [0, 1] met de oorsprong linksboven.
    final boxes = [
      for (final line in capture.lines)
        TextBox(
          text: line.text,
          left: line.boundingBox.left,
          top: line.boundingBox.top,
          right: line.boundingBox.right,
          bottom: line.boundingBox.bottom,
        ),
    ];
    return TextLayout.assemble(boxes);
  }
}
