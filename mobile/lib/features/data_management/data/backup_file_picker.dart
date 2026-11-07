import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/user_message.dart';
import '../../../l10n/app_strings.dart';

/// Laat de gebruiker een reservekopie (ZIP) kiezen, bijv. uit iCloud Drive,
/// Google Drive of Downloads.
abstract interface class BackupFilePicker {
  /// Inhoud van het gekozen bestand, of `null` als de gebruiker annuleert.
  Future<Uint8List?> pick();
}

class SystemBackupFilePicker implements BackupFilePicker {
  @override
  Future<Uint8List?> pick() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      final path = file?.path;
      if (file == null || path == null) return null;
      return File(path).readAsBytes();
    } on PlatformException catch (e) {
      throw AppException(S.current.fileOpenFailed, cause: e);
    }
  }
}
