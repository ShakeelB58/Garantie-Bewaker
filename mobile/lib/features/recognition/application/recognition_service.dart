import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../documents/application/document_service.dart';
import '../../documents/data/document_file_store.dart';
import '../../documents/domain/document.dart';
import '../data/pdf_pages.dart';
import '../data/text_recognizer.dart';
import '../domain/parsed_receipt.dart';
import '../domain/receipt_parser.dart';

/// Voortgang tijdens het herkennen.
class RecognitionProgress {
  const RecognitionProgress({
    required this.page,
    required this.pageCount,
    required this.usingOcr,
  });

  final int page;
  final int pageCount;

  /// `true` als de pagina als afbeelding wordt gelezen (scan of foto).
  final bool usingOcr;

  String get message {
    final what = usingOcr ? 'Tekst herkennen' : 'Tekst lezen';
    return pageCount > 1 ? '$what… pagina $page van $pageCount' : '$what…';
  }
}

/// Haalt tekst uit een document: rechtstreeks uit de PDF waar dat kan,
/// anders via OCR op het toestel.
class TextExtractionService {
  TextExtractionService({
    required TextRecognizer recognizer,
    required PdfPageSource pdfPages,
  }) : _recognizer = recognizer,
       _pdfPages = pdfPages;

  final TextRecognizer _recognizer;
  final PdfPageSource _pdfPages;

  /// Minder letters dan dit op een PDF-pagina = waarschijnlijk een scan.
  static const minLettersForTextLayer = 20;

  /// Grote PDF's: alleen de eerste pagina's (bonnen en facturen zijn kort).
  static const maxPdfPages = 10;

  Future<String> extract(
    String absolutePath,
    DocumentFormat format, {
    ValueChanged<RecognitionProgress>? onProgress,
  }) async {
    if (format.isImage) {
      onProgress?.call(
        const RecognitionProgress(page: 1, pageCount: 1, usingOcr: true),
      );
      return _recognizer.recognizeFile(absolutePath);
    }

    final pages = <String>[];
    await _pdfPages.forEachPage(absolutePath, maxPages: maxPdfPages, (
      page,
      index,
      count,
    ) async {
      onProgress?.call(
        RecognitionProgress(page: index + 1, pageCount: count, usingOcr: false),
      );
      var text = await page.text();
      if (_letterCount(text) < minLettersForTextLayer) {
        // Geen (bruikbare) tekstlaag: pagina als afbeelding lezen.
        onProgress?.call(
          RecognitionProgress(
            page: index + 1,
            pageCount: count,
            usingOcr: true,
          ),
        );
        text = await _recognizer.recognizeBytes(await page.renderJpeg());
      }
      pages.add(text);
    });
    return pages.join('\n');
  }

  static int _letterCount(String text) =>
      RegExp(r'[A-Za-zÀ-ÿ]').allMatches(text).length;
}

/// Herkent gegevens in een zojuist opgeslagen document.
///
/// De ruwe tekst wordt niet bewaard: alleen het resultaat gaat naar het
/// controleformulier, en wordt pas na bevestiging door de gebruiker
/// opgeslagen.
class RecognitionService {
  RecognitionService({
    required TextExtractionService extraction,
    required DocumentFileStore fileStore,
    required DateTime Function() clock,
    ReceiptParser parser = const ReceiptParser(),
  }) : _extraction = extraction,
       _fileStore = fileStore,
       _clock = clock,
       _parser = parser;

  final TextExtractionService _extraction;
  final DocumentFileStore _fileStore;
  final DateTime Function() _clock;
  final ReceiptParser _parser;

  /// Gooit een fout als herkennen niet lukt; de aanroeper valt dan terug
  /// op handmatig invoeren.
  Future<ParsedReceipt> recognize(
    StagedDocument document, {
    ValueChanged<RecognitionProgress>? onProgress,
  }) async {
    final path = await _fileStore.resolve(document.filePath);
    final text = await _extraction.extract(
      path,
      document.format,
      onProgress: onProgress,
    );
    return _parser.parse(text, today: _clock());
  }
}

final textRecognizerProvider = Provider<TextRecognizer>(
  (ref) => TextSightRecognizer(),
);

final pdfPageSourceProvider = Provider<PdfPageSource>(
  (ref) => PdfrxPageSource(),
);

final recognitionServiceProvider = Provider<RecognitionService>((ref) {
  return RecognitionService(
    extraction: TextExtractionService(
      recognizer: ref.watch(textRecognizerProvider),
      pdfPages: ref.watch(pdfPageSourceProvider),
    ),
    fileStore: ref.watch(documentFileStoreProvider),
    clock: ref.watch(clockProvider),
  );
});
