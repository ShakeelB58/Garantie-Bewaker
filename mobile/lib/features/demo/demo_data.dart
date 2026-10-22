import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../documents/application/document_service.dart';
import '../documents/data/document_picker.dart';
import '../documents/domain/document.dart';
import '../products/application/product_providers.dart';
import '../products/domain/product.dart';
import '../products/domain/product_category.dart';

/// Eén fictief voorbeeldproduct, met datums ten opzichte van vandaag.
///
/// Alle merken en winkels zijn verzonnen: deze gegevens komen op de
/// schermafbeeldingen in de App Store en Google Play.
class DemoProduct {
  const DemoProduct({
    required this.name,
    required this.brand,
    required this.category,
    required this.merchant,
    required this.priceMinor,
    required this.boughtDaysAgo,
    this.warrantyMonths,
    this.reminderInDays,
    this.documents = const [],
  });

  final String name;
  final String brand;
  final ProductCategory category;
  final String merchant;
  final int priceMinor;
  final int boughtDaysAgo;

  /// Door de "gebruiker" ingevulde garantie-einddatum, in maanden na aankoop.
  final int? warrantyMonths;

  /// Herinnering over dit aantal dagen, of `null` voor geen herinnering.
  final int? reminderInDays;

  final List<DocumentType> documents;
}

/// Fictieve voorbeeldgegevens, om de app te laten zien zonder echte bonnen.
abstract final class DemoData {
  static const products = [
    DemoProduct(
      name: 'Airfryer XL',
      brand: 'Kookwijs',
      category: ProductCategory.kitchen,
      merchant: 'Huis & Haard',
      priceMinor: 12999,
      boughtDaysAgo: 3,
      warrantyMonths: 24,
      reminderInDays: 12,
      documents: [DocumentType.receipt],
    ),
    DemoProduct(
      name: 'Smartphone Nova 9',
      brand: 'Lumo',
      category: ProductCategory.phoneTablet,
      merchant: 'Elektro Noord',
      priceMinor: 79900,
      boughtDaysAgo: 41,
      warrantyMonths: 24,
      reminderInDays: 34,
      documents: [DocumentType.invoice, DocumentType.warranty],
    ),
    DemoProduct(
      name: 'Hardloopschoenen',
      brand: 'Sprintr',
      category: ProductCategory.clothing,
      merchant: 'Sportzaak De Baan',
      priceMinor: 10995,
      boughtDaysAgo: 9,
      reminderInDays: 5,
      documents: [DocumentType.receipt],
    ),
    DemoProduct(
      name: 'Draadloze koptelefoon',
      brand: 'Sonora',
      category: ProductCategory.electronics,
      merchant: 'Elektro Noord',
      priceMinor: 14900,
      boughtDaysAgo: 150,
      warrantyMonths: 24,
      documents: [DocumentType.invoice],
    ),
    DemoProduct(
      name: 'Stoomstrijkijzer',
      brand: 'Vlotto',
      category: ProductCategory.household,
      merchant: 'Huis & Haard',
      priceMinor: 5999,
      boughtDaysAgo: 420,
      warrantyMonths: 24,
      reminderInDays: 280,
      documents: [DocumentType.receipt],
    ),
    DemoProduct(
      name: 'Laptop 14 inch',
      brand: 'Kern',
      category: ProductCategory.computer,
      merchant: 'Digitaal & Zo',
      priceMinor: 109900,
      boughtDaysAgo: 75,
      warrantyMonths: 24,
      documents: [DocumentType.invoice],
    ),
  ];

  /// Maakt de producten met datums ten opzichte van [now].
  ///
  /// [newId] levert de id's; de volgorde van aanmaken volgt de aankoopdatum,
  /// zodat "Recent toegevoegd" klopt.
  static List<Product> buildProducts({
    required DateTime now,
    required String Function() newId,
  }) {
    final today = Dates.dateOnly(now);
    return [
      for (final demo in products)
        () {
          final bought = today.subtract(Duration(days: demo.boughtDaysAgo));
          final created = now
              .subtract(Duration(days: demo.boughtDaysAgo))
              .toUtc();
          final reminder = demo.reminderInDays == null
              ? null
              : today.add(Duration(days: demo.reminderInDays!));
          return Product(
            id: newId(),
            name: demo.name,
            brand: demo.brand,
            category: demo.category,
            merchant: demo.merchant,
            purchaseDate: bought,
            purchasePriceMinor: demo.priceMinor,
            currency: 'EUR',
            warrantyEndDate: demo.warrantyMonths == null
                ? null
                : DateTime(
                    bought.year,
                    bought.month + demo.warrantyMonths!,
                    bought.day,
                  ),
            reminderEnabled: reminder != null,
            reminderDate: reminder,
            createdAt: created,
            updatedAt: created,
          );
        }(),
    ];
  }

  /// Een eenvoudige, fictieve PDF met de gegevens van het product.
  static Uint8List pdfFor(Product product, DocumentType type) {
    final lines = <String>[
      type.label.toUpperCase(),
      '',
      product.merchant ?? '',
      'Voorbeeldstraat 1, 1234 AB Voorbeeldstad',
      '',
      'Datum: ${Dates.formatShort(product.purchaseDate)}',
      '',
      '${product.brand ?? ''} ${product.name}'.trim(),
      'Bedrag: EUR ${Money.formatForInput(product.purchasePriceMinor ?? 0)}',
      '',
      'Voorbeelddocument van Bonvrij - geen echte aankoop.',
    ];
    return _simplePdf(lines);
  }

  /// Minimale geldige PDF met één pagina tekst (Helvetica).
  static Uint8List _simplePdf(List<String> lines) {
    String escape(String s) =>
        s.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');
    final content = StringBuffer('BT /F1 14 Tf 60 780 Td 20 TL\n');
    for (final line in lines) {
      content.write('(${escape(line)}) Tj T*\n');
    }
    content.write('ET');
    final stream = latin1.encode(content.toString());

    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
          '/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
          '/Encoding /WinAnsiEncoding >>',
    ];
    final out = BytesBuilder();
    final offsets = <int>[];
    void write(String s) => out.add(latin1.encode(s));

    write('%PDF-1.4\n');
    for (var i = 0; i < objects.length; i++) {
      offsets.add(out.length);
      write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
    }
    offsets.add(out.length);
    write('5 0 obj\n<< /Length ${stream.length} >>\nstream\n');
    out.add(stream);
    write('\nendstream\nendobj\n');

    final xref = out.length;
    write('xref\n0 ${offsets.length + 1}\n0000000000 65535 f \n');
    for (final offset in offsets) {
      write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    write(
      'trailer\n<< /Size ${offsets.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xref\n%%EOF\n',
    );
    return out.toBytes();
  }
}

/// Schrijft een tijdelijk bestand en geeft het pad terug. In tests vervangen.
typedef TempFileWriter = Future<String> Function(String name, Uint8List bytes);

final demoTempFileWriterProvider = Provider<TempFileWriter>((ref) {
  return (name, bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  };
});

final demoDataLoaderProvider = Provider<DemoDataLoader>(DemoDataLoader.new);

/// Vult de app met [DemoData]. Alleen bereikbaar in de testversie
/// (debug), zie het instellingenscherm.
class DemoDataLoader {
  DemoDataLoader(this._ref);

  final Ref _ref;

  /// Voegt de voorbeeldproducten met documenten toe. Geeft het aantal
  /// toegevoegde producten terug. Bestaande gegevens blijven staan.
  Future<int> load() async {
    final newId = _ref.read(idGeneratorProvider);
    final now = _ref.read(clockProvider)();
    final products = DemoData.buildProducts(now: now, newId: newId);
    final service = _ref.read(documentServiceProvider);
    final writeTemp = _ref.read(demoTempFileWriterProvider);
    final notifier = _ref.read(productsProvider.notifier);

    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      await notifier.save(product);
      for (final type in DemoData.products[i].documents) {
        final name = '${type.key}-${product.id}.pdf';
        final path = await writeTemp(name, DemoData.pdfFor(product, type));
        final staged = await service.stage(
          PickedFile(path: path, originalName: '${type.label}.pdf'),
          type: type,
        );
        await service.attach(staged, product.id);
      }
      _ref.invalidate(documentsForProductProvider(product.id));
    }
    _ref.invalidate(allDocumentsProvider);
    return products.length;
  }
}
