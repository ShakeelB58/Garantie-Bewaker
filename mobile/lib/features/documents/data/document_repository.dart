import '../../../core/storage/app_database.dart';
import '../domain/document.dart';

/// Opslag van documentgegevens (niet de bestanden zelf).
abstract interface class DocumentRepository {
  /// Documenten van een product, oudste eerst.
  Future<List<Document>> getForProduct(String productId);

  Future<Document?> getById(String id);

  /// Relatieve paden van alle documenten (voor het opruimen van wezen).
  Future<Set<String>> allFilePaths();

  Future<void> insert(Document document);

  Future<void> updateType(String id, DocumentType type);

  Future<void> delete(String id);
}

class SqfliteDocumentRepository implements DocumentRepository {
  SqfliteDocumentRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<Document>> getForProduct(String productId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'documents',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Document?> getById(String id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Set<String>> allFilePaths() async {
    final db = await _appDatabase.database;
    final rows = await db.query('documents', columns: ['file_path']);
    return {for (final row in rows) row['file_path']! as String};
  }

  @override
  Future<void> insert(Document document) async {
    final db = await _appDatabase.database;
    await db.insert('documents', {
      'id': document.id,
      'product_id': document.productId,
      'file_path': document.filePath,
      'document_type': document.type.key,
      'original_filename': document.originalFilename,
      'mime_type': document.format.mimeType,
      'created_at': document.createdAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> updateType(String id, DocumentType type) async {
    final db = await _appDatabase.database;
    await db.update(
      'documents',
      {'document_type': type.key},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _appDatabase.database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Document _fromRow(Map<String, Object?> row) => Document(
    id: row['id']! as String,
    productId: row['product_id']! as String,
    filePath: row['file_path']! as String,
    type: DocumentType.fromKey(row['document_type']! as String),
    format:
        DocumentFormat.fromMimeType(row['mime_type']! as String) ??
        DocumentFormat.pdf,
    originalFilename: row['original_filename'] as String?,
    createdAt: DateTime.parse(row['created_at']! as String),
  );
}
