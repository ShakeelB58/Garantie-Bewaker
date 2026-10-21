import 'document.dart';

/// Controle van geïmporteerde bestanden: type (op inhoud) en grootte.
abstract final class DocumentValidation {
  /// Maximaal 25 MB per document.
  static const maxSizeBytes = 25 * 1024 * 1024;

  /// Aantal bytes dat nodig is om het formaat te herkennen.
  static const headerLength = 1024;

  /// Herkent het formaat aan de eerste bytes ("magic numbers").
  /// De bestandsnaam of extensie wordt bewust niet vertrouwd.
  static DocumentFormat? detectFormat(List<int> header) {
    if (_startsWith(header, const [0xFF, 0xD8, 0xFF])) {
      return DocumentFormat.jpeg;
    }
    if (_startsWith(header, const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    ])) {
      return DocumentFormat.png;
    }
    if (_isHeic(header)) return DocumentFormat.heic;
    // PDF: "%PDF-" mag volgens de specificatie binnen de eerste 1024 bytes staan.
    if (_indexOf(header, const [0x25, 0x50, 0x44, 0x46, 0x2D]) >= 0) {
      return DocumentFormat.pdf;
    }
    return null;
  }

  /// Nederlandse foutmelding, of `null` als het bestand bruikbaar is.
  static String? validate({
    required int sizeBytes,
    required DocumentFormat? format,
  }) {
    if (sizeBytes <= 0) {
      return 'Dit bestand is leeg en kan niet worden gebruikt.';
    }
    if (sizeBytes > maxSizeBytes) {
      return 'Dit bestand is te groot (maximaal 25 MB).';
    }
    if (format == null) {
      return 'Dit bestandstype wordt niet ondersteund. '
          'Kies een PDF, JPG, PNG of HEIC.';
    }
    return null;
  }

  /// Maakt een bestandsnaam veilig om te bewaren en te tonen:
  /// geen mappen, geen stuurtekens, maximaal 120 tekens.
  static String? sanitizeFilename(String? name) {
    if (name == null) return null;
    var cleaned = name.split(RegExp(r'[/\\]')).last;
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') return null;
    if (cleaned.length > 120) cleaned = cleaned.substring(0, 120);
    return cleaned;
  }

  /// Standaardtype op basis van het formaat: PDF's zijn meestal facturen,
  /// foto's meestal kassabonnen. De gebruiker kan dit later wijzigen.
  static DocumentType defaultTypeFor(DocumentFormat format) =>
      format == DocumentFormat.pdf
      ? DocumentType.invoice
      : DocumentType.receipt;

  static bool _startsWith(List<int> data, List<int> prefix) {
    if (data.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (data[i] != prefix[i]) return false;
    }
    return true;
  }

  static int _indexOf(List<int> data, List<int> pattern) {
    final limit = data.length < headerLength ? data.length : headerLength;
    for (var i = 0; i + pattern.length <= limit; i++) {
      var match = true;
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  static bool _isHeic(List<int> data) {
    // ISO-BMFF: bytes 4..7 = "ftyp", bytes 8..11 = merk.
    if (data.length < 12) return false;
    final ftyp = String.fromCharCodes(data.sublist(4, 8));
    if (ftyp != 'ftyp') return false;
    final brand = String.fromCharCodes(data.sublist(8, 12));
    return const {
      'heic',
      'heix',
      'hevc',
      'hevx',
      'heim',
      'heis',
      'mif1',
      'msf1',
    }.contains(brand);
  }
}
