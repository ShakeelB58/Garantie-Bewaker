import 'dart:convert';
import 'dart:typed_data';

import 'package:garantiebewaker/features/recognition/data/pdf_pages.dart';
import 'package:garantiebewaker/features/recognition/data/text_recognizer.dart';

/// OCR die vooraf ingestelde tekst teruggeeft.
class FakeTextRecognizer implements TextRecognizer {
  /// Tekst voor [recognizeFile] en [recognizeBytes].
  String text = '';

  /// Als ingesteld, gooit de volgende herkenning deze fout.
  Object? error;

  final List<String> recognizedFiles = [];
  int recognizedImages = 0;

  @override
  Future<String> recognizeFile(String path) async {
    recognizedFiles.add(path);
    return _result();
  }

  @override
  Future<String> recognizeBytes(Uint8List encodedImage) async {
    recognizedImages++;
    return _result();
  }

  String _result() {
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
    return text;
  }
}

/// PDF met vooraf ingestelde pagina's. Een lege tekst = gescande pagina.
class FakePdfPageSource implements PdfPageSource {
  FakePdfPageSource([this.pageTexts = const []]);

  List<String> pageTexts;
  int? lastMaxPages;
  int rendered = 0;

  @override
  Future<void> forEachPage(
    String path,
    Future<void> Function(PdfPageAccess page, int index, int pageCount)
    action, {
    int maxPages = 10,
  }) async {
    lastMaxPages = maxPages;
    final count = pageTexts.length < maxPages ? pageTexts.length : maxPages;
    for (var i = 0; i < count; i++) {
      await action(_FakePage(this, pageTexts[i]), i, count);
    }
  }
}

class _FakePage implements PdfPageAccess {
  _FakePage(this._source, this._text);

  final FakePdfPageSource _source;
  final String _text;

  @override
  Future<String> text() async => _text;

  @override
  Future<Uint8List> renderJpeg() async {
    _source.rendered++;
    return Uint8List.fromList(utf8.encode('jpeg'));
  }
}

/// Tekst zoals OCR die van testbon-supermarkt.jpg zou geven.
const testbonText = '''
VOORBEELDMARKT
Fictieve testbon
Testlaan 5, Voorbeeldstad
Datum: 15-10-2026 14:32
Bon: 0042
Waterkoker WK-200 29,99
Theedoek 3,49
TOTAAL EUR 33,48
Btw 21% 5,81
Pin 33,48''';

/// Tekst zoals uit testfactuur-elektronica.pdf.
const testfactuurText = '''
Voorbeeldwinkel Elektronica B.V.
Teststraat 1
1234 AB Voorbeeldstad
FACTUUR
Factuurdatum: 12-10-2026
Omschrijving Aantal Bedrag
Wasmachine Voorbeeld WM-8000 8 kg 1 EUR 1.299,00
Bezorging en installatie 1 EUR 49,95
Subtotaal excl. btw EUR 1.114,83
Btw 21% EUR 234,12
Totaal EUR 1.348,95''';
