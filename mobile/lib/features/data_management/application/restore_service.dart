import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../documents/data/document_file_store.dart';
import '../../documents/data/document_repository.dart';
import '../../documents/domain/document.dart';
import '../../documents/domain/document_validation.dart';
import '../../products/data/product_repository.dart';
import '../domain/backup_manifest.dart';

/// Een gelezen en gecontroleerde reservekopie, klaar om terug te zetten.
class RestorePlan {
  const RestorePlan({
    required this.toRestore,
    required this.skipped,
    required this.files,
  });

  /// Producten die nog niet in de app staan.
  final List<BackupProduct> toRestore;

  /// Aantal producten dat al in de app staat (zelfde id).
  final int skipped;

  /// Inhoud van de documenten, op naam in de ZIP.
  final Map<String, Uint8List> files;

  int get productCount => toRestore.length + skipped;

  int get documentCount =>
      toRestore.fold(0, (sum, item) => sum + item.documents.length);

  bool get hasNothingNew => toRestore.isEmpty;
}

class RestoreResult {
  const RestoreResult({required this.products, required this.documents});

  final int products;
  final int documents;
}

/// Zet een export van Bonvrij terug.
///
/// 1. [inspect] leest de ZIP en controleert álles (gegevens én bestanden)
///    voordat er iets wordt opgeslagen.
/// 2. [restore] zet per product de documenten en gegevens terug. Mislukt
///    een product halverwege, dan wordt dat product weer opgeruimd; eerder
///    teruggezette producten blijven staan en worden bij een nieuwe poging
///    overgeslagen (geen dubbelen).
class RestoreService {
  RestoreService({
    required ProductRepository products,
    required DocumentRepository documents,
    required DocumentFileStore fileStore,
    required String Function() newId,
  }) : _products = products,
       _documents = documents,
       _fileStore = fileStore,
       _newId = newId;

  final ProductRepository _products;
  final DocumentRepository _documents;
  final DocumentFileStore _fileStore;
  final String Function() _newId;

  /// Maximale grootte van het backupbestand zelf (niet de documenten).
  static const _maxManifestBytes = 20 * 1024 * 1024;

  Future<RestorePlan> inspect(Uint8List zipBytes) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw const BackupFormatException(BackupProblem.notABackup);
    }

    final entries = <String, ArchiveFile>{
      for (final file in archive.files)
        if (file.isFile) file.name: file,
    };
    final manifestFile = entries[BackupManifest.fileName];
    if (manifestFile == null) {
      // Een export van vóór het backupbestand herkennen we aan de CSV.
      final looksLikeOldExport = entries.keys.any(
        (name) => name == 'producten.csv' || name == 'products.csv',
      );
      throw BackupFormatException(
        looksLikeOldExport ? BackupProblem.oldExport : BackupProblem.notABackup,
      );
    }
    if (manifestFile.size > _maxManifestBytes) {
      throw const BackupFormatException(BackupProblem.damaged);
    }

    final String json;
    try {
      json = utf8.decode(manifestFile.readBytes() ?? const []);
    } catch (_) {
      throw const BackupFormatException(BackupProblem.damaged);
    }
    final items = BackupManifest.decode(json);

    final existing = {for (final p in await _products.getAll()) p.id};
    final toRestore = <BackupProduct>[];
    var skipped = 0;
    final files = <String, Uint8List>{};

    for (final item in items) {
      if (existing.contains(item.product.id)) {
        skipped++;
        continue;
      }
      for (final doc in item.documents) {
        final entry = entries[doc.archivePath];
        if (entry == null || entry.size > DocumentValidation.maxSizeBytes) {
          throw const BackupFormatException(BackupProblem.damaged);
        }
        final Uint8List bytes;
        try {
          bytes = entry.readBytes() ?? Uint8List(0);
        } catch (_) {
          throw const BackupFormatException(BackupProblem.damaged);
        }
        // Het type wordt opnieuw aan de inhoud gecontroleerd; de gegevens
        // in het backupbestand worden niet blind vertrouwd.
        final format = DocumentValidation.detectFormat(
          bytes.length > DocumentValidation.headerLength
              ? Uint8List.sublistView(bytes, 0, DocumentValidation.headerLength)
              : bytes,
        );
        if (bytes.isEmpty ||
            bytes.length > DocumentValidation.maxSizeBytes ||
            format != doc.document.format) {
          throw const BackupFormatException(BackupProblem.damaged);
        }
        files[doc.archivePath] = bytes;
      }
      toRestore.add(item);
    }

    return RestorePlan(toRestore: toRestore, skipped: skipped, files: files);
  }

  Future<RestoreResult> restore(RestorePlan plan) async {
    final existingDocuments = {for (final d in await _documents.getAll()) d.id};
    var products = 0;
    var documents = 0;

    for (final item in plan.toRestore) {
      final storedPaths = <String>[];
      var productSaved = false;
      try {
        final restored = <Document>[];
        for (final doc in item.documents) {
          // Zelfde id als het kan; anders (al in gebruik) een nieuwe.
          final id = existingDocuments.contains(doc.document.id)
              ? _newId()
              : doc.document.id;
          final path = await _fileStore.storeBytes(
            plan.files[doc.archivePath]!,
            id: id,
            format: doc.document.format,
          );
          storedPaths.add(path);
          restored.add(
            Document(
              id: id,
              productId: item.product.id,
              filePath: path,
              type: doc.document.type,
              format: doc.document.format,
              originalFilename: DocumentValidation.sanitizeFilename(
                doc.document.originalFilename,
              ),
              createdAt: doc.document.createdAt,
            ),
          );
        }
        await _products.save(item.product);
        productSaved = true;
        for (final document in restored) {
          await _documents.insert(document);
          existingDocuments.add(document.id);
        }
        products++;
        documents += restored.length;
      } catch (_) {
        // Dit product helemaal opruimen, zodat er niets half blijft staan.
        if (productSaved) {
          try {
            await _products.delete(item.product.id);
          } catch (_) {}
        }
        for (final path in storedPaths) {
          try {
            await _fileStore.delete(path);
          } catch (_) {}
        }
        rethrow;
      }
    }
    return RestoreResult(products: products, documents: documents);
  }
}
