import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Laat de gebruiker kiezen waar een export wordt bewaard.
abstract interface class ExportSaver {
  /// `false` als de gebruiker annuleert.
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}

/// Opent het bewaarvenster van het systeem (iOS: "Bewaar in Bestanden",
/// Android: de bestandskiezer). De app schrijft zelf niets naar gedeelde
/// opslag.
class SystemExportSaver implements ExportSaver {
  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      dialogTitle: 'Export bewaren',
    );
    return uri != null;
  }
}
