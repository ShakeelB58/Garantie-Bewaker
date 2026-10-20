import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../domain/text_layout.dart';

/// Toegang tot één PDF-pagina tijdens het verwerken.
abstract interface class PdfPageAccess {
  /// Tekstlaag van de pagina (leeg bij een scan zonder tekst).
  Future<String> text();

  /// De pagina als JPEG, om er OCR op te doen.
  Future<Uint8List> renderJpeg();
}

/// Loopt pagina voor pagina door een PDF, zodat nooit alle pagina's
/// tegelijk in het geheugen staan.
abstract interface class PdfPageSource {
  Future<void> forEachPage(
    String path,
    Future<void> Function(PdfPageAccess page, int index, int pageCount)
    action, {
    int maxPages,
  });
}

/// Ongeveer 144 dpi, met een maximum aan pixels per zijde.
const _renderScale = 2.0;
const _maxRenderSide = 2200.0;

/// [PdfPageSource] op basis van pdfrx (PDFium).
class PdfrxPageSource implements PdfPageSource {
  @override
  Future<void> forEachPage(
    String path,
    Future<void> Function(PdfPageAccess page, int index, int pageCount)
    action, {
    int maxPages = 10,
  }) async {
    final document = await PdfDocument.openFile(path);
    try {
      final count = math.min(document.pages.length, maxPages);
      for (var i = 0; i < count; i++) {
        await action(_PdfrxPage(document.pages[i]), i, count);
      }
    } finally {
      await document.dispose();
    }
  }
}

class _PdfrxPage implements PdfPageAccess {
  _PdfrxPage(this._page);

  final PdfPage _page;

  @override
  Future<String> text() async {
    final text = await _page.loadStructuredText();
    final full = text.fullText;
    // Tekens op dezelfde hoogte samenvoegen tot regels. Als de posities
    // niet overeenkomen met de tekst, de tekst zoals PDFium hem geeft.
    if (text.charRects.length != full.length) return full;
    final height = _page.height;
    final boxes = <TextBox>[
      for (var i = 0; i < full.length; i++)
        if (full[i].trim().isNotEmpty)
          TextBox(
            text: full[i],
            left: text.charRects[i].left,
            // PDF-coördinaten: y loopt omhoog. Omzetten naar y omlaag.
            top: height - text.charRects[i].top,
            right: text.charRects[i].right,
            bottom: height - text.charRects[i].bottom,
          ),
    ];
    final assembled = TextLayout.assemble(boxes, characterLevel: true);
    return assembled.isEmpty ? full : assembled;
  }

  @override
  Future<Uint8List> renderJpeg() async {
    final longest = math.max(_page.width, _page.height);
    final scale = math.min(_renderScale, _maxRenderSide / longest);
    final width = (_page.width * scale).round();
    final height = (_page.height * scale).round();

    final image = await _page.render(
      width: width,
      height: height,
      fullWidth: width.toDouble(),
      fullHeight: height.toDouble(),
      backgroundColor: 0xFFFFFFFF,
    );
    if (image == null) {
      throw StateError('Pagina kon niet worden weergegeven');
    }
    final Uint8List pixels;
    try {
      pixels = Uint8List.fromList(image.pixels);
    } finally {
      image.dispose();
    }
    return _encodeBgraAsJpeg(width, height, pixels);
  }
}

/// Codeert ruwe BGRA-pixels als JPEG, buiten de UI-thread.
/// Bewust een losse functie: de closure mag geen PDF-objecten meenemen
/// naar de andere isolate.
Future<Uint8List> _encodeBgraAsJpeg(int width, int height, Uint8List pixels) {
  return Isolate.run(
    () => img.encodeJpg(
      img.Image.fromBytes(
        width: width,
        height: height,
        bytes: pixels.buffer,
        numChannels: 4,
        order: img.ChannelOrder.bgra,
      ),
      quality: 90,
    ),
  );
}
