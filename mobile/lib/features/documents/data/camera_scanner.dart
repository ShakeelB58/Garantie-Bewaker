import 'package:flutter/widgets.dart';

import 'document_picker.dart';

/// Resultaat van de scanner.
typedef ScanResult = ({PickedFile file, bool fromGallery});

/// Foto van een bon maken. De echte versie opent de camera in de app
/// ([InAppCameraScanner] in `scanner_screen.dart`); in tests wordt een
/// nepversie gebruikt.
abstract interface class CameraScanner {
  /// `null` als de gebruiker annuleert.
  Future<ScanResult?> scan(NavigatorState navigator);
}

/// Scanner die de camera-app van het systeem gebruikt via [DocumentPicker].
/// Voor tests en als terugval.
class PickerCameraScanner implements CameraScanner {
  PickerCameraScanner(this._picker);

  final DocumentPicker _picker;

  @override
  Future<ScanResult?> scan(NavigatorState navigator) async {
    final file = await _picker.pick(DocumentSource.camera);
    return file == null ? null : (file: file, fromGallery: false);
  }
}
