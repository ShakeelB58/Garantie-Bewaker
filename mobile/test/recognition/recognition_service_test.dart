import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';
import 'package:garantiebewaker/features/recognition/application/recognition_service.dart';
import 'package:garantiebewaker/features/recognition/domain/parsed_receipt.dart';

import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/recognition_fakes.dart';

void main() {
  late FakeTextRecognizer recognizer;
  late FakePdfPageSource pdfPages;
  late TextExtractionService extraction;

  setUp(() {
    recognizer = FakeTextRecognizer();
    pdfPages = FakePdfPageSource();
    extraction = TextExtractionService(
      recognizer: recognizer,
      pdfPages: pdfPages,
    );
  });

  group('TextExtractionService', () {
    test('foto: OCR op het bestand', () async {
      recognizer.text = testbonText;
      final progress = <String>[];

      final text = await extraction.extract(
        '/app/documents/d1.jpg',
        DocumentFormat.jpeg,
        onProgress: (p) => progress.add(p.message),
      );

      expect(text, testbonText);
      expect(recognizer.recognizedFiles, ['/app/documents/d1.jpg']);
      expect(progress, ['Tekst herkennen…']);
    });

    test('digitale PDF: tekst rechtstreeks, geen OCR', () async {
      pdfPages.pageTexts = [testfactuurText];

      final text = await extraction.extract('/f.pdf', DocumentFormat.pdf);

      expect(text, testfactuurText);
      expect(pdfPages.rendered, 0);
      expect(recognizer.recognizedImages, 0);
    });

    test('gescande PDF: pagina zonder tekst wordt via OCR gelezen', () async {
      pdfPages.pageTexts = [testfactuurText, ''];
      recognizer.text = 'Garantiebewijs 2 jaar';
      final progress = <String>[];

      final text = await extraction.extract(
        '/f.pdf',
        DocumentFormat.pdf,
        onProgress: (p) => progress.add(p.message),
      );

      expect(text, '$testfactuurText\nGarantiebewijs 2 jaar');
      expect(pdfPages.rendered, 1);
      expect(recognizer.recognizedImages, 1);
      expect(progress, [
        'Tekst lezen… pagina 1 van 2',
        'Tekst lezen… pagina 2 van 2',
        'Tekst herkennen… pagina 2 van 2',
      ]);
    });

    test('grote PDF: hoogstens 10 pagina\'s', () async {
      pdfPages.pageTexts = List.filled(25, testfactuurText);
      await extraction.extract('/f.pdf', DocumentFormat.pdf);
      expect(pdfPages.lastMaxPages, TextExtractionService.maxPdfPages);
    });
  });

  group('RecognitionService', () {
    late InMemoryDocumentFileStore fileStore;
    late RecognitionService service;

    setUp(() {
      fileStore = InMemoryDocumentFileStore();
      service = RecognitionService(
        extraction: extraction,
        fileStore: fileStore,
        clock: () => testNow,
      );
    });

    const staged = StagedDocument(
      id: 'd1',
      filePath: 'documents/d1.pdf',
      format: DocumentFormat.pdf,
      type: DocumentType.invoice,
      sizeBytes: 100,
    );

    test('herkent velden uit een PDF-factuur', () async {
      pdfPages.pageTexts = [testfactuurText];

      final result = await service.recognize(staged);

      expect(result.merchant.value, 'Voorbeeldwinkel Elektronica');
      expect(result.purchaseDate.value, DateTime(2026, 10, 12));
      expect(result.totalMinor.value, 134895);
      expect(result.totalMinor.confidence, RecognitionConfidence.high);
      expect(result.productName.value, 'Wasmachine Voorbeeld WM-8000 8 kg');
    });

    test('fout bij OCR wordt doorgegeven', () async {
      recognizer.error = StateError('OCR kapot');
      const photo = StagedDocument(
        id: 'd2',
        filePath: 'documents/d2.jpg',
        format: DocumentFormat.jpeg,
        type: DocumentType.receipt,
        sizeBytes: 100,
      );
      await expectLater(service.recognize(photo), throwsStateError);
    });
  });
}
