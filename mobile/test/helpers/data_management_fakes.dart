import 'dart:typed_data';

import 'package:garantiebewaker/features/data_management/data/backup_file_picker.dart';
import 'package:garantiebewaker/features/data_management/data/export_saver.dart';

/// Bewaart de export in het geheugen in plaats van een bewaarvenster.
class FakeExportSaver implements ExportSaver {
  /// `false` = de gebruiker annuleert.
  bool accept = true;

  String? fileName;
  Uint8List? bytes;
  String? mimeType;

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (!accept) return false;
    this.fileName = fileName;
    this.bytes = bytes;
    this.mimeType = mimeType;
    return true;
  }
}

/// Geeft een vooraf ingestelde reservekopie terug (of `null` = annuleren).
class FakeBackupFilePicker implements BackupFilePicker {
  Uint8List? bytes;
  int picks = 0;

  @override
  Future<Uint8List?> pick() async {
    picks++;
    return bytes;
  }
}
