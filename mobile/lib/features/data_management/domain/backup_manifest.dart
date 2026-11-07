import 'dart:convert';

import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../documents/domain/document.dart';
import '../../products/domain/product.dart';
import '../../products/domain/product_category.dart';

/// Waarom een reservekopie niet gelezen kon worden.
enum BackupProblem {
  /// Geen ZIP of geen `bonvrij-backup.json`.
  notABackup,

  /// Een export van vóór versie 1.2 (alleen CSV, geen backupbestand).
  oldExport,

  /// Gemaakt met een nieuwere versie van de app.
  newerVersion,

  /// Het bestand is kapot, onvolledig of aangepast.
  damaged,
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.problem);

  final BackupProblem problem;

  @override
  String toString() => 'BackupFormatException($problem)';
}

/// Eén document in de reservekopie: de gegevens plus de naam van het
/// bestand in de ZIP.
class BackupDocument {
  const BackupDocument({required this.document, required this.archivePath});

  /// [Document.filePath] is hier leeg; de app kiest bij terugzetten zelf
  /// een nieuw, veilig pad.
  final Document document;
  final String archivePath;
}

class BackupProduct {
  const BackupProduct({required this.product, required this.documents});

  final Product product;
  final List<BackupDocument> documents;
}

/// Machineleesbare inhoud van een export (`bonvrij-backup.json`), zodat de
/// app alles exact kan terugzetten. De CSV is voor mensen; dit is voor de
/// app.
abstract final class BackupManifest {
  static const fileName = 'bonvrij-backup.json';
  static const format = 'bonvrij-backup';

  /// Verhoog dit alleen als oudere apps het nieuwe formaat niet meer
  /// kunnen lezen.
  static const version = 1;

  static final _id = RegExp(r'^[A-Za-z0-9-]{1,64}$');
  static const _maxText = 200;

  static String encode(List<BackupProduct> products, DateTime exportedAt) {
    final data = {
      'format': format,
      'version': version,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'products': [
        for (final item in products)
          {
            'id': item.product.id,
            'name': item.product.name,
            'brand': item.product.brand,
            'category': item.product.category.key,
            'merchant': item.product.merchant,
            'modelNumber': item.product.modelNumber,
            'serialNumber': item.product.serialNumber,
            'purchaseDate': Dates.toIsoDate(item.product.purchaseDate),
            'purchasePriceMinor': item.product.purchasePriceMinor,
            'currency': item.product.currency,
            'warrantyEndDate': item.product.warrantyEndDate == null
                ? null
                : Dates.toIsoDate(item.product.warrantyEndDate!),
            'reminderEnabled': item.product.reminderEnabled,
            'reminderDate': item.product.reminderDate == null
                ? null
                : Dates.toIsoDate(item.product.reminderDate!),
            'createdAt': item.product.createdAt.toUtc().toIso8601String(),
            'updatedAt': item.product.updatedAt.toUtc().toIso8601String(),
            'documents': [
              for (final doc in item.documents)
                {
                  'id': doc.document.id,
                  'type': doc.document.type.key,
                  'mimeType': doc.document.format.mimeType,
                  'originalFilename': doc.document.originalFilename,
                  'createdAt': doc.document.createdAt.toUtc().toIso8601String(),
                  'file': doc.archivePath,
                },
            ],
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Leest en controleert de inhoud streng. Elke afwijking geeft
  /// [BackupFormatException]; er wordt nooit iets half gelezen.
  static List<BackupProduct> decode(String json) {
    final Object? data;
    try {
      data = jsonDecode(json);
    } on FormatException {
      throw const BackupFormatException(BackupProblem.damaged);
    }
    if (data is! Map<String, Object?> || data['format'] != format) {
      throw const BackupFormatException(BackupProblem.notABackup);
    }
    final fileVersion = data['version'];
    if (fileVersion is! int) {
      throw const BackupFormatException(BackupProblem.damaged);
    }
    if (fileVersion > version) {
      throw const BackupFormatException(BackupProblem.newerVersion);
    }
    final products = data['products'];
    if (products is! List) {
      throw const BackupFormatException(BackupProblem.damaged);
    }
    final ids = <String>{};
    final documentIds = <String>{};
    return [
      for (final raw in products)
        _product(_map(raw), ids: ids, documentIds: documentIds),
    ];
  }

  static BackupProduct _product(
    Map<String, Object?> m, {
    required Set<String> ids,
    required Set<String> documentIds,
  }) {
    final id = _requiredId(m['id']);
    if (!ids.add(id)) throw const BackupFormatException(BackupProblem.damaged);
    final currency = _requiredText(m['currency']);
    if (!Money.supportedCurrencies.contains(currency)) {
      throw const BackupFormatException(BackupProblem.damaged);
    }
    final price = m['purchasePriceMinor'];
    if (price != null && (price is! int || price < 0)) {
      throw const BackupFormatException(BackupProblem.damaged);
    }
    final reminderEnabled = m['reminderEnabled'];
    if (reminderEnabled is! bool) {
      throw const BackupFormatException(BackupProblem.damaged);
    }
    final docs = m['documents'];
    if (docs is! List) throw const BackupFormatException(BackupProblem.damaged);

    final product = Product(
      id: id,
      name: _requiredText(m['name']),
      brand: _optionalText(m['brand']),
      category: ProductCategory.fromKey(_requiredText(m['category'])),
      merchant: _optionalText(m['merchant']),
      modelNumber: _optionalText(m['modelNumber']),
      serialNumber: _optionalText(m['serialNumber']),
      purchaseDate: _date(m['purchaseDate'])!,
      purchasePriceMinor: price as int?,
      currency: currency,
      warrantyEndDate: _date(m['warrantyEndDate'], required: false),
      reminderEnabled: reminderEnabled,
      reminderDate: _date(m['reminderDate'], required: false),
      createdAt: _timestamp(m['createdAt']),
      updatedAt: _timestamp(m['updatedAt']),
    );
    return BackupProduct(
      product: product,
      documents: [
        for (final raw in docs)
          _document(_map(raw), productId: id, documentIds: documentIds),
      ],
    );
  }

  static BackupDocument _document(
    Map<String, Object?> m, {
    required String productId,
    required Set<String> documentIds,
  }) {
    final id = _requiredId(m['id']);
    if (!documentIds.add(id)) {
      throw const BackupFormatException(BackupProblem.damaged);
    }
    final format = DocumentFormat.fromMimeType(_requiredText(m['mimeType']));
    if (format == null) throw const BackupFormatException(BackupProblem.damaged);
    final file = _requiredText(m['file']);
    return BackupDocument(
      archivePath: file,
      document: Document(
        id: id,
        productId: productId,
        filePath: '',
        type: DocumentType.fromKey(_requiredText(m['type'])),
        format: format,
        originalFilename: _optionalText(m['originalFilename']),
        createdAt: _timestamp(m['createdAt']),
      ),
    );
  }

  static Map<String, Object?> _map(Object? raw) {
    if (raw is Map<String, Object?>) return raw;
    throw const BackupFormatException(BackupProblem.damaged);
  }

  static String _requiredId(Object? value) {
    if (value is String && _id.hasMatch(value)) return value;
    throw const BackupFormatException(BackupProblem.damaged);
  }

  static String _requiredText(Object? value) {
    final text = _optionalText(value);
    if (text == null) throw const BackupFormatException(BackupProblem.damaged);
    return text;
  }

  static String? _optionalText(Object? value) {
    if (value == null) return null;
    if (value is! String || value.length > _maxText) {
      throw const BackupFormatException(BackupProblem.damaged);
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _date(Object? value, {bool required = true}) {
    if (value == null && !required) return null;
    if (value is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      try {
        return Dates.parseIsoDate(value);
      } on FormatException {
        // valt door naar de fout hieronder
      }
    }
    throw const BackupFormatException(BackupProblem.damaged);
  }

  static DateTime _timestamp(Object? value) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) throw const BackupFormatException(BackupProblem.damaged);
    return parsed.toUtc();
  }
}
