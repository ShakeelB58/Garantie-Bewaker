import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/user_message.dart';

/// Een bestand dat de gebruiker heeft gekozen of gefotografeerd.
class PickedFile {
  const PickedFile({required this.path, this.originalName});

  final String path;
  final String? originalName;
}

/// Bronnen voor een nieuw document.
enum DocumentSource { camera, gallery, files }

/// Camera, fotobibliotheek en bestandskiezer achter één interface,
/// zodat schermen zonder echte camera te testen zijn.
abstract interface class DocumentPicker {
  /// `null` als de gebruiker annuleert.
  Future<PickedFile?> pick(DocumentSource source);
}

class PlatformDocumentPicker implements DocumentPicker {
  PlatformDocumentPicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  /// Extensies in de bestandskiezer. Het echte type wordt daarna aan de
  /// inhoud gecontroleerd.
  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'heic'];

  @override
  Future<PickedFile?> pick(DocumentSource source) async {
    try {
      switch (source) {
        case DocumentSource.camera:
        case DocumentSource.gallery:
          final image = await _imagePicker.pickImage(
            source: source == DocumentSource.camera
                ? ImageSource.camera
                : ImageSource.gallery,
            // Leesbaar voor tekstherkenning, maar niet onnodig groot.
            maxWidth: 2500,
            maxHeight: 2500,
            imageQuality: 85,
            requestFullMetadata: false,
          );
          if (image == null) return null;
          return PickedFile(path: image.path, originalName: image.name);
        case DocumentSource.files:
          final file = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: allowedExtensions,
          );
          final path = file?.path;
          if (file == null || path == null) return null;
          return PickedFile(path: path, originalName: file.name);
      }
    } on PlatformException catch (e) {
      throw AppException(_messageFor(e, source), cause: e);
    }
  }

  static String _messageFor(PlatformException e, DocumentSource source) {
    if (e.code == 'camera_access_denied') {
      return 'GarantieBewaker heeft geen toegang tot de camera. '
          'Je kunt dit aanzetten in de instellingen van je telefoon.';
    }
    if (e.code == 'photo_access_denied') {
      return 'GarantieBewaker heeft geen toegang tot je foto\'s. '
          'Je kunt dit aanzetten in de instellingen van je telefoon.';
    }
    if (e.code == 'no_available_camera') {
      return 'Er is geen camera beschikbaar op dit toestel.';
    }
    return switch (source) {
      DocumentSource.camera => 'De camera kon niet worden geopend.',
      DocumentSource.gallery => 'De fotobibliotheek kon niet worden geopend.',
      DocumentSource.files => 'Het bestand kon niet worden geopend.',
    };
  }
}
