import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';
import 'package:garantiebewaker/features/documents/domain/document_validation.dart';

import '../helpers/document_fakes.dart';

void main() {
  group('detectFormat', () {
    test('PDF', () {
      expect(DocumentValidation.detectFormat(pdfBytes), DocumentFormat.pdf);
    });

    test('PDF met voorloopbytes binnen 1024 bytes', () {
      final bytes = [...List.filled(100, 0x20), ...pdfBytes];
      expect(DocumentValidation.detectFormat(bytes), DocumentFormat.pdf);
    });

    test('JPEG', () {
      expect(DocumentValidation.detectFormat(jpegBytes), DocumentFormat.jpeg);
    });

    test('PNG', () {
      final png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0];
      expect(DocumentValidation.detectFormat(png), DocumentFormat.png);
    });

    test('HEIC', () {
      final heic = [0, 0, 0, 0x18, ...ascii.encode('ftypheic'), 0, 0, 0, 0];
      expect(DocumentValidation.detectFormat(heic), DocumentFormat.heic);
    });

    test('MP4 is geen HEIC', () {
      final mp4 = [0, 0, 0, 0x18, ...ascii.encode('ftypisom'), 0, 0, 0, 0];
      expect(DocumentValidation.detectFormat(mp4), isNull);
    });

    test('tekst, leeg en te kort worden niet herkend', () {
      expect(DocumentValidation.detectFormat(textBytes), isNull);
      expect(DocumentValidation.detectFormat(const []), isNull);
      expect(DocumentValidation.detectFormat(const [0xFF, 0xD8]), isNull);
    });

    test('een .pdf-naam met andere inhoud wordt niet vertrouwd', () {
      // Alleen de inhoud telt: tekst blijft tekst.
      expect(DocumentValidation.detectFormat(utf8.encode('PDF-1.7')), isNull);
    });
  });

  group('validate', () {
    test('geldig bestand', () {
      expect(
        DocumentValidation.validate(
          sizeBytes: 1000,
          format: DocumentFormat.pdf,
        ),
        isNull,
      );
    });

    test('leeg bestand', () {
      expect(
        DocumentValidation.validate(sizeBytes: 0, format: DocumentFormat.pdf),
        contains('leeg'),
      );
    });

    test('precies 25 MB mag, één byte meer niet', () {
      expect(
        DocumentValidation.validate(
          sizeBytes: DocumentValidation.maxSizeBytes,
          format: DocumentFormat.pdf,
        ),
        isNull,
      );
      expect(
        DocumentValidation.validate(
          sizeBytes: DocumentValidation.maxSizeBytes + 1,
          format: DocumentFormat.pdf,
        ),
        contains('te groot'),
      );
    });

    test('onbekend type', () {
      expect(
        DocumentValidation.validate(sizeBytes: 10, format: null),
        contains('niet ondersteund'),
      );
    });
  });

  group('sanitizeFilename', () {
    test('verwijdert mappen en stuurtekens', () {
      expect(DocumentValidation.sanitizeFilename('../../etc/passwd'), 'passwd');
      expect(
        DocumentValidation.sanitizeFilename(r'C:\Users\x\factuur.pdf'),
        'factuur.pdf',
      );
      expect(DocumentValidation.sanitizeFilename('bon\n1.jpg'), 'bon1.jpg');
    });

    test('lege of ongeldige namen worden null', () {
      expect(DocumentValidation.sanitizeFilename(null), isNull);
      expect(DocumentValidation.sanitizeFilename('   '), isNull);
      expect(DocumentValidation.sanitizeFilename('..'), isNull);
    });

    test('lange namen worden ingekort', () {
      expect(DocumentValidation.sanitizeFilename('a' * 300)!.length, 120);
    });
  });

  test('standaardtype: PDF is factuur, foto is kassabon', () {
    expect(
      DocumentValidation.defaultTypeFor(DocumentFormat.pdf),
      DocumentType.invoice,
    );
    expect(
      DocumentValidation.defaultTypeFor(DocumentFormat.jpeg),
      DocumentType.receipt,
    );
  });
}
