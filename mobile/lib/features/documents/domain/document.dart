/// Soort aankoopbewijs. De [key] wordt opgeslagen en mag nooit veranderen.
enum DocumentType {
  receipt('receipt', 'Kassabon'),
  invoice('invoice', 'Factuur'),
  warranty('warranty', 'Garantiebewijs'),
  other('other', 'Overig');

  const DocumentType(this.key, this.label);

  final String key;
  final String label;

  static DocumentType fromKey(String key) => DocumentType.values.firstWhere(
    (t) => t.key == key,
    orElse: () => DocumentType.other,
  );
}

/// Ondersteunde bestandsformaten, herkend aan de inhoud (niet aan de naam).
enum DocumentFormat {
  pdf('application/pdf', 'pdf'),
  jpeg('image/jpeg', 'jpg'),
  png('image/png', 'png'),
  heic('image/heic', 'heic');

  const DocumentFormat(this.mimeType, this.extension);

  final String mimeType;
  final String extension;

  bool get isImage => this != DocumentFormat.pdf;

  static DocumentFormat? fromMimeType(String mimeType) {
    for (final format in DocumentFormat.values) {
      if (format.mimeType == mimeType) return format;
    }
    return null;
  }
}

/// Een aankoopbewijs dat bij een product is opgeslagen.
class Document {
  const Document({
    required this.id,
    required this.productId,
    required this.filePath,
    required this.type,
    required this.format,
    required this.createdAt,
    this.originalFilename,
  });

  final String id;
  final String productId;

  /// Pad relatief aan de app-private documentmap, bijv. `documents/<id>.pdf`.
  /// Nooit een absoluut pad: dat verandert op iOS na updates.
  final String filePath;

  final DocumentType type;
  final DocumentFormat format;
  final String? originalFilename;

  /// Tijdstip in UTC.
  final DateTime createdAt;

  Document copyWith({DocumentType? type}) => Document(
    id: id,
    productId: productId,
    filePath: filePath,
    type: type ?? this.type,
    format: format,
    createdAt: createdAt,
    originalFilename: originalFilename,
  );

  @override
  bool operator ==(Object other) =>
      other is Document &&
      other.id == id &&
      other.productId == productId &&
      other.filePath == filePath &&
      other.type == type &&
      other.format == format &&
      other.originalFilename == originalFilename &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    filePath,
    type,
    format,
    originalFilename,
    createdAt,
  );

  @override
  String toString() => 'Document($id, $filePath)';
}

/// Een bestand dat al veilig in de app-opslag staat, maar nog niet aan een
/// product is gekoppeld (bijv. tijdens het invullen van het formulier).
class StagedDocument {
  const StagedDocument({
    required this.id,
    required this.filePath,
    required this.format,
    required this.type,
    required this.sizeBytes,
    this.originalFilename,
  });

  final String id;
  final String filePath;
  final DocumentFormat format;
  final DocumentType type;
  final int sizeBytes;
  final String? originalFilename;
}
