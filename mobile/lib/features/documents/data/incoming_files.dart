import 'dart:async';
import 'dart:io';

import 'package:open_file_handler/open_file_handler.dart';

import '../../../core/errors/user_message.dart';

/// Een bestand dat vanuit een andere app naar Bonvrij is gestuurd.
class IncomingFile {
  const IncomingFile({required this.path, this.name, this.originalPath});

  /// Lokale kopie die de app mag lezen.
  final String path;

  final String? name;

  /// Pad van het bestand dat het systeem aanleverde, als dat een lokaal
  /// bestand is (op iOS bijv. in `Documents/Inbox`). Wordt na het importeren
  /// opgeruimd als het in een tijdelijke map van de app staat.
  final String? originalPath;
}

/// Bestanden die via "Openen met" of "Delen" binnenkomen.
abstract interface class IncomingFileSource {
  /// Zowel bij een koude start als terwijl de app al draait.
  Stream<IncomingFile> get files;

  /// Geeft systeemrechten op het bestand vrij (iOS). Aanroepen na verwerking.
  Future<void> release();

  void dispose();
}

class OpenFileHandlerSource implements IncomingFileSource {
  final OpenFileHandler _handler = OpenFileHandler();
  StreamSubscription<dynamic>? _subscription;
  late final StreamController<IncomingFile> _controller =
      StreamController<IncomingFile>.broadcast(onListen: _start);

  @override
  Stream<IncomingFile> get files => _controller.stream;

  void _start() {
    _subscription ??= _handler.listen(
      (file) {
        final path = file.path;
        if (path == null) {
          _controller.addError(
            const AppException('Het gedeelde bestand kon niet worden geopend.'),
          );
          return;
        }
        final uri = Uri.tryParse(file.uri);
        _controller.add(
          IncomingFile(
            path: path,
            name: file.name,
            originalPath: uri != null && uri.scheme == 'file'
                ? uri.toFilePath()
                : null,
          ),
        );
      },
      onError: (Object error) => _controller.addError(
        AppException(
          'Het gedeelde bestand kon niet worden geopend.',
          cause: error,
        ),
      ),
    );
  }

  @override
  Future<void> release() async {
    if (Platform.isIOS) await _handler.releaseIosURIs();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
