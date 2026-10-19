import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:garantiebewaker/features/documents/data/document_file_store.dart';
import 'package:garantiebewaker/features/documents/data/document_picker.dart';
import 'package:garantiebewaker/features/documents/data/document_repository.dart';
import 'package:garantiebewaker/features/documents/data/incoming_files.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';
import 'package:garantiebewaker/features/documents/domain/document_validation.dart';

import 'fixtures.dart';

/// Minimale inhoud die als PDF wordt herkend (geanonimiseerd testbestand).
final pdfBytes = Uint8List.fromList(
  utf8.encode('%PDF-1.7\n% testfactuur zonder persoonsgegevens\n%%EOF\n'),
);

/// Begin van een JPEG-bestand.
final jpegBytes = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, //
  ...List.filled(64, 0),
]);

/// Tekstbestand: geen ondersteund formaat.
final textBytes = Uint8List.fromList(utf8.encode('dit is geen document'));

Document makeDocument({
  String id = 'd1',
  String productId = 'p1',
  DocumentType type = DocumentType.invoice,
  DocumentFormat format = DocumentFormat.pdf,
  String? originalFilename = 'factuur.pdf',
}) => Document(
  id: id,
  productId: productId,
  filePath: 'documents/$id.${format.extension}',
  type: type,
  format: format,
  originalFilename: originalFilename,
  createdAt: DateTime.utc(2026, 10, 1, 12),
);

class InMemoryDocumentRepository implements DocumentRepository {
  InMemoryDocumentRepository([List<Document> initial = const []]) {
    for (final document in initial) {
      _documents[document.id] = document;
    }
  }

  final Map<String, Document> _documents = {};

  List<Document> get all => _documents.values.toList();

  /// Bootst ON DELETE CASCADE na.
  void removeForProduct(String productId) =>
      _documents.removeWhere((_, d) => d.productId == productId);

  @override
  Future<List<Document>> getForProduct(String productId) async =>
      _documents.values.where((d) => d.productId == productId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<Document?> getById(String id) async => _documents[id];

  @override
  Future<Set<String>> allFilePaths() async =>
      _documents.values.map((d) => d.filePath).toSet();

  @override
  Future<void> insert(Document document) async {
    _documents[document.id] = document;
  }

  @override
  Future<void> updateType(String id, DocumentType type) async {
    final document = _documents[id];
    if (document != null) _documents[id] = document.copyWith(type: type);
  }

  @override
  Future<void> delete(String id) async {
    _documents.remove(id);
  }
}

/// Bestandsopslag in het geheugen. Bronbestanden ("buiten de app") en
/// opgeslagen documenten ("in de app") worden apart bijgehouden.
class InMemoryDocumentFileStore implements DocumentFileStore {
  /// Bronbestanden die de kiezer kan teruggeven, op pad.
  final Map<String, Uint8List> sources = {};

  /// Bronbestanden die in de tijdelijke map staan (mogen worden opgeruimd).
  final Set<String> temporarySources = {};

  /// Opgeslagen documenten, op relatief pad.
  final Map<String, Uint8List> stored = {};
  final Map<String, DateTime> storedAt = {};

  DateTime now = testNow;

  void addSource(String path, Uint8List bytes, {bool temporary = true}) {
    sources[path] = bytes;
    if (temporary) temporarySources.add(path);
  }

  void addStored(String relativePath, Uint8List bytes, {DateTime? at}) {
    stored[relativePath] = bytes;
    storedAt[relativePath] = at ?? now;
  }

  @override
  Future<SourceFileInfo> inspectSource(String sourcePath) async {
    final bytes = sources[sourcePath];
    if (bytes == null) {
      throw FileSystemException('Niet gevonden', sourcePath);
    }
    final headerLength = bytes.length < DocumentValidation.headerLength
        ? bytes.length
        : DocumentValidation.headerLength;
    return SourceFileInfo(
      sizeBytes: bytes.length,
      header: Uint8List.sublistView(bytes, 0, headerLength),
    );
  }

  @override
  Future<String> store(
    String sourcePath, {
    required String id,
    required DocumentFormat format,
  }) async {
    final relative = 'documents/$id.${format.extension}';
    stored[relative] = sources[sourcePath]!;
    storedAt[relative] = now;
    return relative;
  }

  @override
  Future<String> resolve(String relativePath) async {
    if (!LocalDocumentFileStore.isValidRelativePath(relativePath)) {
      throw ArgumentError.value(relativePath);
    }
    return '/niet-bestaand/$relativePath';
  }

  @override
  Future<void> delete(String relativePath) async {
    stored.remove(relativePath);
    storedAt.remove(relativePath);
  }

  @override
  Future<Map<String, DateTime>> listStored() async => Map.of(storedAt);

  @override
  Future<void> deleteIfTemporary(String sourcePath) async {
    if (temporarySources.remove(sourcePath)) sources.remove(sourcePath);
  }
}

/// Kiezer die vooraf ingestelde resultaten teruggeeft.
class FakeDocumentPicker implements DocumentPicker {
  final List<PickedFile?> results = [];
  final List<DocumentSource> requests = [];
  Object? error;

  @override
  Future<PickedFile?> pick(DocumentSource source) async {
    requests.add(source);
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
    return results.isEmpty ? null : results.removeAt(0);
  }
}

/// Nabootsing van "Openen met" / "Delen" vanuit een andere app.
class FakeIncomingFileSource implements IncomingFileSource {
  final StreamController<IncomingFile> controller =
      StreamController<IncomingFile>.broadcast();
  int releaseCount = 0;

  void send(IncomingFile file) => controller.add(file);

  @override
  Stream<IncomingFile> get files => controller.stream;

  @override
  Future<void> release() async {
    releaseCount++;
  }

  @override
  void dispose() => controller.close();
}
