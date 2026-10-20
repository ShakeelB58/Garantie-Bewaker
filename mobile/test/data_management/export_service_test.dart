import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/data_management/application/export_service.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';

import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/in_memory_product_repository.dart';

void main() {
  late InMemoryProductRepository products;
  late InMemoryDocumentRepository documents;
  late InMemoryDocumentFileStore fileStore;
  late ExportService service;

  setUp(() {
    products = InMemoryProductRepository();
    documents = InMemoryDocumentRepository();
    fileStore = InMemoryDocumentFileStore();
    service = ExportService(
      products: products,
      documents: documents,
      fileStore: fileStore,
      clock: () => testNow,
    );
  });

  Map<String, List<int>> unzip(List<int> bytes) => {
    for (final file in ZipDecoder().decodeBytes(bytes))
      if (file.isFile) file.name: file.content as List<int>,
  };

  test('ZIP met CSV, documenten en uitleg', () async {
    await products.save(
      makeProduct(
        name: 'Wasmachine WM-8000',
        purchaseDate: DateTime(2026, 1, 2),
      ),
    );
    await products.save(
      makeProduct(id: 'p2', name: 'Tv', purchaseDate: DateTime(2026, 5, 6)),
    );
    final factuur = makeDocument();
    final foto = makeDocument(
      id: 'd2',
      type: DocumentType.receipt,
      format: DocumentFormat.jpeg,
    );
    final tvBon = makeDocument(id: 'd3', productId: 'p2');
    for (final d in [factuur, foto, tvBon]) {
      await documents.insert(d);
    }
    fileStore
      ..addStored(factuur.filePath, pdfBytes)
      ..addStored(foto.filePath, jpegBytes)
      ..addStored(tvBon.filePath, pdfBytes);

    final export = await service.build();

    expect(export.fileName, 'garantiebewaker-export-2026-10-19.zip');
    expect(export.productCount, 2);
    expect(export.documentCount, 3);
    expect(export.missingDocuments, 0);

    final files = unzip(export.bytes);
    expect(
      files.keys,
      containsAll([
        'producten.csv',
        'LEESMIJ.txt',
        'documenten/001-wasmachine-wm-8000-factuur-1.pdf',
        'documenten/001-wasmachine-wm-8000-kassabon-2.jpg',
        'documenten/002-tv-factuur-1.pdf',
      ]),
    );
    expect(files['documenten/002-tv-factuur-1.pdf'], pdfBytes);

    final csv = utf8.decode(files['producten.csv']!);
    final lines = csv.substring(1).split('\r\n');
    // Oudste aankoop eerst, passend bij de nummers van de documenten.
    expect(lines[1], startsWith('Wasmachine WM-8000;'));
    expect(lines[1], endsWith(';2'));
    expect(lines[2], startsWith('Tv;'));
  });

  test('ontbrekend bestand wordt overgeslagen en geteld', () async {
    await products.save(makeProduct());
    await documents.insert(makeDocument());

    final export = await service.build();

    expect(export.documentCount, 0);
    expect(export.missingDocuments, 1);
    expect(unzip(export.bytes).keys, ['producten.csv', 'LEESMIJ.txt']);
  });

  test('bestandsnamen bevatten alleen veilige tekens', () {
    final doc = makeDocument(type: DocumentType.warranty);
    expect(
      ExportService.documentName(7, '../Café "Crème" / 2.0!', doc, 1),
      'documenten/007-cafe-creme-2-0-garantiebewijs-1.pdf',
    );
    expect(
      ExportService.documentName(1, '€€€', doc, 3),
      'documenten/001-product-garantiebewijs-3.pdf',
    );
    expect(
      ExportService.documentName(1, 'a' * 100, doc, 1),
      'documenten/001-${'a' * 40}-garantiebewijs-1.pdf',
    );
  });
}
