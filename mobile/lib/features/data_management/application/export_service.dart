import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../core/utils/dates.dart';
import '../../documents/data/document_file_store.dart';
import '../../documents/data/document_repository.dart';
import '../../documents/domain/document.dart';
import '../../products/data/product_repository.dart';
import '../domain/products_csv.dart';

/// Een export die klaarstaat om te bewaren.
class ExportFile {
  const ExportFile({
    required this.fileName,
    required this.bytes,
    required this.productCount,
    required this.documentCount,
    required this.missingDocuments,
  });

  final String fileName;
  final Uint8List bytes;
  final int productCount;
  final int documentCount;

  /// Documenten waarvan het bestand niet (meer) gelezen kon worden.
  final int missingDocuments;
}

/// Maakt een ZIP-bestand met alle gegevens:
/// - `producten.csv` (te openen in Excel of Numbers)
/// - `documenten/` met alle aankoopbewijzen
/// - `LEESMIJ.txt`
///
/// Het bestand wordt in het geheugen opgebouwd en nergens tussentijds
/// opgeslagen; de gebruiker kiest zelf waar het komt.
class ExportService {
  ExportService({
    required ProductRepository products,
    required DocumentRepository documents,
    required DocumentFileStore fileStore,
    required DateTime Function() clock,
  }) : _products = products,
       _documents = documents,
       _fileStore = fileStore,
       _clock = clock;

  final ProductRepository _products;
  final DocumentRepository _documents;
  final DocumentFileStore _fileStore;
  final DateTime Function() _clock;

  Future<ExportFile> build() async {
    final products = (await _products.getAll())
      ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    final archive = Archive();
    final counts = <String, int>{};
    var documentCount = 0;
    var missing = 0;

    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      final documents = await _documents.getForProduct(product.id);
      counts[product.id] = documents.length;
      for (var j = 0; j < documents.length; j++) {
        final document = documents[j];
        final Uint8List bytes;
        try {
          bytes = await _fileStore.readBytes(document.filePath);
        } catch (_) {
          missing++;
          continue;
        }
        // Afbeeldingen en PDF's zijn al gecomprimeerd.
        archive.addFile(
          ArchiveFile.noCompress(
            documentName(i + 1, product.name, document, j + 1),
            bytes.length,
            bytes,
          ),
        );
        documentCount++;
      }
    }

    archive
      ..addFile(
        ArchiveFile.string(
          'producten.csv',
          ProductsCsv.build(products, counts),
        ),
      )
      ..addFile(ArchiveFile.string('LEESMIJ.txt', _readme()));

    return ExportFile(
      fileName: 'garantiebewaker-export-${Dates.toIsoDate(_clock())}.zip',
      bytes: ZipEncoder().encodeBytes(archive),
      productCount: products.length,
      documentCount: documentCount,
      missingDocuments: missing,
    );
  }

  /// Bijv. `documenten/003-wasmachine-factuur-1.pdf`. Alleen veilige tekens,
  /// zodat de naam op elk systeem werkt.
  static String documentName(
    int productNumber,
    String productName,
    Document document,
    int documentNumber,
  ) {
    var slug = productName
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâäã]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôöõ]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.length > 40) {
      slug = slug.substring(0, 40).replaceAll(RegExp(r'-+$'), '');
    }
    if (slug.isEmpty) slug = 'product';
    final number = productNumber.toString().padLeft(3, '0');
    final type = document.type.label.toLowerCase();
    return 'documenten/$number-$slug-$type-$documentNumber.'
        '${document.format.extension}';
  }

  String _readme() =>
      'Export van GarantieBewaker\r\n'
      'Gemaakt op ${Dates.formatLong(_clock())}.\r\n'
      '\r\n'
      'producten.csv\r\n'
      '  Al je producten. Open dit bestand met Excel, Numbers of Google '
      'Spreadsheets.\r\n'
      '\r\n'
      'documenten/\r\n'
      '  Je aankoopbewijzen. Het nummer vooraan de bestandsnaam hoort bij de '
      'volgorde in producten.csv (product 1 is de eerste regel).\r\n'
      '\r\n'
      'Let op: dit bestand bevat je aankoopgegevens. Bewaar het op een '
      'veilige plek en deel het alleen met mensen die je vertrouwt.\r\n'
      '\r\n'
      'Garantie-einddatums en herinneringen zijn door jou ingevuld. '
      'GarantieBewaker berekent geen garantietermijnen en geeft geen '
      'juridisch advies.\r\n';
}
