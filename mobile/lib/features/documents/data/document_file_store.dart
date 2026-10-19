import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../domain/document.dart';
import '../domain/document_validation.dart';

/// Informatie over een bronbestand dat geïmporteerd gaat worden.
class SourceFileInfo {
  const SourceFileInfo({required this.sizeBytes, required this.header});

  final int sizeBytes;

  /// De eerste [DocumentValidation.headerLength] bytes.
  final Uint8List header;
}

/// Bestandsopslag voor aankoopbewijzen, gescheiden van de productlogica.
abstract interface class DocumentFileStore {
  /// Grootte en eerste bytes van een bronbestand (buiten de app-opslag).
  Future<SourceFileInfo> inspectSource(String sourcePath);

  /// Kopieert [sourcePath] naar de app-private opslag.
  /// Geeft het relatieve pad terug, bijv. `documents/<id>.pdf`.
  Future<String> store(
    String sourcePath, {
    required String id,
    required DocumentFormat format,
  });

  /// Absoluut pad om een opgeslagen document te openen.
  /// Gooit [ArgumentError] bij een ongeldig of onveilig pad.
  Future<String> resolve(String relativePath);

  /// Verwijdert een opgeslagen document. Een ontbrekend bestand is geen fout.
  Future<void> delete(String relativePath);

  /// Alle opgeslagen documenten met hun laatste wijzigingstijd.
  Future<Map<String, DateTime>> listStored();

  /// Verwijdert een tijdelijk bronbestand (bijv. een camerafoto in de cache),
  /// maar alleen als het in de tijdelijke map van de app staat. Originelen
  /// van de gebruiker worden nooit aangeraakt.
  Future<void> deleteIfTemporary(String sourcePath);
}

/// [DocumentFileStore] op het bestandssysteem van het toestel.
class LocalDocumentFileStore implements DocumentFileStore {
  LocalDocumentFileStore({
    required Future<Directory> Function() baseDirectory,
    required Future<Directory> Function() temporaryDirectory,
  }) : _baseDirectory = baseDirectory,
       _temporaryDirectory = temporaryDirectory;

  static const folder = 'documents';

  /// Alleen paden die de app zelf heeft gemaakt zijn toegestaan.
  /// Voorkomt path traversal (`../`) en absolute paden.
  static final _validPath = RegExp(
    r'^documents/[A-Za-z0-9-]{1,64}\.(pdf|jpg|png|heic)$',
  );

  final Future<Directory> Function() _baseDirectory;
  final Future<Directory> Function() _temporaryDirectory;

  static bool isValidRelativePath(String relativePath) =>
      _validPath.hasMatch(relativePath);

  @override
  Future<SourceFileInfo> inspectSource(String sourcePath) async {
    final file = File(sourcePath);
    final size = await file.length();
    final handle = await file.open();
    try {
      final header = await handle.read(DocumentValidation.headerLength);
      return SourceFileInfo(sizeBytes: size, header: header);
    } finally {
      await handle.close();
    }
  }

  @override
  Future<String> store(
    String sourcePath, {
    required String id,
    required DocumentFormat format,
  }) async {
    final relative = '$folder/$id.${format.extension}';
    if (!isValidRelativePath(relative)) {
      throw ArgumentError.value(id, 'id', 'Ongeldig document-id');
    }
    final base = await _baseDirectory();
    final dir = Directory(p.join(base.path, folder));
    await dir.create(recursive: true);

    final target = File(p.join(base.path, relative));
    // Eerst naar een tijdelijke naam kopiëren en daarna hernoemen, zodat er
    // nooit een half gekopieerd document achterblijft onder de echte naam.
    final partial = File('${target.path}.part');
    try {
      await File(sourcePath).copy(partial.path);
      await partial.rename(target.path);
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
    return relative;
  }

  @override
  Future<String> resolve(String relativePath) async {
    if (!isValidRelativePath(relativePath)) {
      throw ArgumentError.value(relativePath, 'relativePath', 'Ongeldig pad');
    }
    final base = await _baseDirectory();
    return p.join(base.path, relativePath);
  }

  @override
  Future<void> delete(String relativePath) async {
    final file = File(await resolve(relativePath));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<Map<String, DateTime>> listStored() async {
    final base = await _baseDirectory();
    final dir = Directory(p.join(base.path, folder));
    if (!await dir.exists()) return {};
    final result = <String, DateTime>{};
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final relative = '$folder/${p.basename(entity.path)}';
      if (isValidRelativePath(relative)) {
        result[relative] = await entity.lastModified();
      }
    }
    return result;
  }

  @override
  Future<void> deleteIfTemporary(String sourcePath) async {
    final temp = await _temporaryDirectory();
    final normalized = p.normalize(p.absolute(sourcePath));
    if (!p.isWithin(p.normalize(temp.path), normalized)) return;
    final file = File(normalized);
    if (await file.exists()) await file.delete();
  }
}
