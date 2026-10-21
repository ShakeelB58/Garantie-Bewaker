import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/user_message.dart';
import '../../../core/storage/storage_providers.dart';
import '../../products/application/product_providers.dart';
import '../data/document_file_store.dart';
import '../data/incoming_files.dart';
import '../data/document_picker.dart';
import '../data/document_repository.dart';
import '../domain/document.dart';
import '../domain/document_validation.dart';

/// Importeren, koppelen en verwijderen van aankoopbewijzen.
///
/// Volgorde bij importeren:
/// 1. bronbestand controleren (grootte, type op inhoud);
/// 2. kopiëren naar de app-private opslag ("staged");
/// 3. tijdelijk bronbestand opruimen;
/// 4. pas bij het opslaan van het product: koppelen in de database.
class DocumentService {
  DocumentService({
    required DocumentRepository repository,
    required DocumentFileStore fileStore,
    required String Function() newId,
    required DateTime Function() clock,
  }) : _repository = repository,
       _fileStore = fileStore,
       _newId = newId,
       _clock = clock;

  final DocumentRepository _repository;
  final DocumentFileStore _fileStore;
  final String Function() _newId;
  final DateTime Function() _clock;

  /// Controleert en kopieert een gekozen bestand naar de app-opslag.
  /// Gooit [AppException] met een Nederlandse melding bij een ongeldig bestand.
  Future<StagedDocument> stage(PickedFile picked, {DocumentType? type}) async {
    try {
      final SourceFileInfo info;
      try {
        info = await _fileStore.inspectSource(picked.path);
      } catch (e) {
        throw AppException('Het bestand kon niet worden gelezen.', cause: e);
      }

      final format = DocumentValidation.detectFormat(info.header);
      final error = DocumentValidation.validate(
        sizeBytes: info.sizeBytes,
        format: format,
      );
      if (error != null) throw AppException(error);
      final validFormat = format!;

      final id = _newId();
      final String relativePath;
      try {
        relativePath = await _fileStore.store(
          picked.path,
          id: id,
          format: validFormat,
        );
      } catch (e) {
        throw AppException(
          'Het document kon niet worden opgeslagen. '
          'Controleer of er genoeg opslagruimte vrij is.',
          cause: e,
        );
      }

      return StagedDocument(
        id: id,
        filePath: relativePath,
        format: validFormat,
        type: type ?? DocumentValidation.defaultTypeFor(validFormat),
        sizeBytes: info.sizeBytes,
        originalFilename: DocumentValidation.sanitizeFilename(
          picked.originalName,
        ),
      );
    } finally {
      // Tijdelijke kopieën (camera, kiezer) direct opruimen, ook bij fouten.
      await _quietly(() => _fileStore.deleteIfTemporary(picked.path));
    }
  }

  /// Koppelt een eerder opgeslagen bestand aan een product.
  Future<Document> attach(StagedDocument staged, String productId) async {
    final document = Document(
      id: staged.id,
      productId: productId,
      filePath: staged.filePath,
      type: staged.type,
      format: staged.format,
      originalFilename: staged.originalFilename,
      createdAt: _clock().toUtc(),
    );
    await _repository.insert(document);
    return document;
  }

  /// Gooit een niet-gekoppeld bestand weg (bijv. formulier geannuleerd).
  Future<void> discard(StagedDocument staged) =>
      _quietly(() => _fileStore.delete(staged.filePath));

  /// Verwijdert een document: eerst het record, daarna het bestand.
  Future<void> delete(Document document) async {
    await _repository.delete(document.id);
    await _quietly(() => _fileStore.delete(document.filePath));
  }

  Future<void> changeType(Document document, DocumentType type) =>
      _repository.updateType(document.id, type);

  /// Absoluut pad om een document te tonen.
  Future<String> absolutePath(Document document) =>
      _fileStore.resolve(document.filePath);

  /// Verwijdert de bestanden van documenten die al uit de database zijn
  /// verwijderd (bijv. via ON DELETE CASCADE bij het verwijderen van een
  /// product).
  Future<void> deleteFiles(Iterable<Document> documents) async {
    for (final document in documents) {
      await _quietly(() => _fileStore.delete(document.filePath));
    }
  }

  /// Ruimt bestanden op die nergens meer bij horen, bijv. als de app werd
  /// afgesloten terwijl een formulier nog open stond. Bestanden jonger dan
  /// [minAge] blijven staan, omdat ze mogelijk nog in gebruik zijn.
  Future<int> cleanupOrphans({
    Duration minAge = const Duration(hours: 1),
  }) async {
    final known = await _repository.allFilePaths();
    final stored = await _fileStore.listStored();
    final cutoff = _clock().subtract(minAge);
    var removed = 0;
    for (final entry in stored.entries) {
      if (known.contains(entry.key)) continue;
      if (entry.value.isAfter(cutoff)) continue;
      await _quietly(() => _fileStore.delete(entry.key));
      removed++;
    }
    return removed;
  }

  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      // Bewust zonder pad of bestandsnaam: die kunnen persoonlijk zijn.
      debugPrint('Opruimen van een document mislukt (${e.runtimeType})');
    }
  }
}

final documentFileStoreProvider = Provider<DocumentFileStore>((ref) {
  return LocalDocumentFileStore(
    // Application Support: app-privé, niet zichtbaar in de Bestanden-app.
    baseDirectory: getApplicationSupportDirectory,
    temporaryDirectories: () async {
      final documents = await getApplicationDocumentsDirectory();
      return [
        await getTemporaryDirectory(),
        await getApplicationCacheDirectory(),
        // iOS zet bestanden die via "Openen met" binnenkomen in Documents/Inbox.
        Directory(p.join(documents.path, 'Inbox')),
      ];
    },
  );
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return SqfliteDocumentRepository(ref.watch(appDatabaseProvider));
});

final documentPickerProvider = Provider<DocumentPicker>(
  (ref) => PlatformDocumentPicker(),
);

final documentServiceProvider = Provider<DocumentService>((ref) {
  return DocumentService(
    repository: ref.watch(documentRepositoryProvider),
    fileStore: ref.watch(documentFileStoreProvider),
    newId: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
  );
});

/// Documenten van één product. Na wijzigingen: `ref.invalidate(...)`.
final documentsForProductProvider =
    FutureProvider.family<List<Document>, String>((ref, productId) {
      return ref.watch(documentRepositoryProvider).getForProduct(productId);
    });

/// Alle documenten (tabblad Documenten). Laadt opnieuw als producten
/// veranderen; na het toevoegen of verwijderen van een document:
/// `ref.invalidate(allDocumentsProvider)`.
final allDocumentsProvider = FutureProvider<List<Document>>((ref) {
  ref.watch(productsProvider);
  return ref.watch(documentRepositoryProvider).getAll();
});

final documentByIdProvider = FutureProvider.family<Document?, String>((
  ref,
  id,
) {
  return ref.watch(documentRepositoryProvider).getById(id);
});

/// Bestanden die via "Openen met" of "Delen" binnenkomen.
final incomingFileSourceProvider = Provider<IncomingFileSource>((ref) {
  final source = OpenFileHandlerSource();
  ref.onDispose(source.dispose);
  return source;
});
