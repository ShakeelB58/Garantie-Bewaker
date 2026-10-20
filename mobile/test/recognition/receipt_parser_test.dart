import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/recognition/domain/parsed_receipt.dart';
import 'package:garantiebewaker/features/recognition/domain/receipt_parser.dart';

/// Alle teksten hieronder zijn fictief.
void main() {
  const parser = ReceiptParser();
  final today = DateTime(2026, 10, 19);

  ParsedReceipt parse(String text) => parser.parse(text, today: today);

  const high = RecognitionConfidence.high;
  const medium = RecognitionConfidence.medium;
  const low = RecognitionConfidence.low;
  const unknown = RecognitionConfidence.unknown;

  group('volledige documenten', () {
    test('testfactuur (PDF) uit docs/testbestanden', () {
      final r = parse('''
Voorbeeldwinkel Elektronica B.V.
FICTIEF TESTDOCUMENT - geen echte winkel, geen echte persoonsgegevens
Teststraat 1
1234 AB Voorbeeldstad
KvK 00000000 BTW NL000000000B01
FACTUUR
Factuurnummer: F-2026-00123
Factuurdatum: 12-10-2026
Klant: Test Klant
Omschrijving Aantal Bedrag
Wasmachine Voorbeeld WM-8000 8 kg 1 EUR 1.299,00
Bezorging en installatie 1 EUR 49,95
Subtotaal excl. btw EUR 1.114,83
Btw 21% EUR 234,12
Totaal EUR 1.348,95
Betaald met pinbetaling op 12-10-2026.
Bewaar deze factuur als aankoopbewijs.''');

      expect(r.merchant.value, 'Voorbeeldwinkel Elektronica');
      expect(r.merchant.confidence, medium);
      expect(r.purchaseDate.value, DateTime(2026, 10, 12));
      expect(r.purchaseDate.confidence, high);
      expect(r.totalMinor.value, 134895);
      // Productregels tellen op tot het totaal.
      expect(r.totalMinor.confidence, high);
      expect(r.lineItems, const [
        ParsedLineItem(
          description: 'Wasmachine Voorbeeld WM-8000 8 kg',
          amountMinor: 129900,
        ),
        ParsedLineItem(
          description: 'Bezorging en installatie',
          amountMinor: 4995,
        ),
      ]);
      // Bezorging telt niet als product.
      expect(r.productCandidates, hasLength(1));
      expect(r.productName.value, 'Wasmachine Voorbeeld WM-8000 8 kg');
      expect(r.productName.confidence, medium);
      expect(r.vatMinor, 23412);
    });

    test('testbon (foto) uit docs/testbestanden', () {
      final r = parse('''
VOORBEELDMARKT
Fictieve testbon
Testlaan 5, Voorbeeldstad
Datum: 15-10-2026 14:32
Bon: 0042
--------------------------
Waterkoker WK-200 29,99
Theedoek 3,49
--------------------------
TOTAAL EUR 33,48
Btw 21% 5,81
Pin 33,48
Bedankt voor uw aankoop!''');

      expect(r.merchant.value, 'Voorbeeldmarkt');
      expect(r.merchant.confidence, medium);
      expect(r.purchaseDate.value, DateTime(2026, 10, 15));
      expect(r.purchaseDate.confidence, high);
      expect(r.totalMinor.value, 3348);
      // Totaal = pinbedrag.
      expect(r.totalMinor.confidence, high);
      expect(r.lineItems.map((i) => i.description), [
        'Waterkoker WK-200',
        'Theedoek',
      ]);
      expect(r.productName.value, 'Waterkoker WK-200');
      // Meerdere producten: de gebruiker moet kiezen.
      expect(r.productName.confidence, low);
      expect(r.vatMinor, 581);
    });

    test('supermarktbon met aantallen, korting en datum onderaan', () {
      final r = parse('''
Albert Heijn 1234
Hoofdstraat 10
1000 AA Amsterdam
Tel 020-1234567
AANTAL OMSCHRIJVING PRIJS BEDRAG
1 MELK HALFVOLLE 1,29
2 BANANEN 0,99 1,98
1 KOFFIEZETAPPARAAT 49,99
BONUS KOFFIE -5,00
SUBTOTAAL 48,26
TOTAAL 48,26
PINNEN 48,26
BTW OVER EUR
9% 3,27 0,29
21% 41,31 8,68
14:05 17-10-2026 1234 56 7890''');

      expect(r.merchant.value, 'Albert Heijn');
      expect(r.merchant.confidence, high);
      expect(r.purchaseDate.value, DateTime(2026, 10, 17));
      expect(r.purchaseDate.confidence, medium);
      expect(r.totalMinor.value, 4826);
      expect(r.totalMinor.confidence, high);
      expect(r.lineItems, const [
        ParsedLineItem(description: 'Melk halfvolle', amountMinor: 129),
        ParsedLineItem(description: 'Bananen', amountMinor: 198),
        ParsedLineItem(description: 'Koffiezetapparaat', amountMinor: 4999),
      ]);
    });

    test('elektronicazaak: garantiedatum wordt niet als aankoopdatum gezien',
        () {
      final r = parse('''
MediaMarkt Utrecht
Kassabon
Datum 03.09.2025
Samsung Galaxy S25 128GB 899,00
Beschermhoes 19,99
Te betalen 918,99
Maestro 918,99
Garantie tot 03.09.2027''');

      expect(r.merchant.value, 'MediaMarkt');
      expect(r.purchaseDate.value, DateTime(2025, 9, 3));
      expect(r.purchaseDate.confidence, high);
      expect(r.totalMinor.value, 91899);
      expect(r.totalMinor.confidence, high);
      expect(r.lineItems, hasLength(2));
    });

    test('webwinkelfactuur met uitgeschreven datums en "incl. btw"', () {
      final r = parse('''
Coolblue B.V.
Weena 664, 3012 CN Rotterdam
Factuur
Besteldatum: 7 oktober 2026
Factuurdatum: 8 oktober 2026
Vervaldatum: 22 oktober 2026
Product Aantal Prijs
Bosch Serie 6 vaatwasser 1 € 649,00
Verzendkosten € 0,00
Totaal incl. btw € 649,00
waarvan btw 21% € 112,64''');

      expect(r.merchant.value, 'Coolblue');
      expect(r.merchant.confidence, high);
      // Twee verschillende datums: eerste wordt voorgesteld, niet zeker.
      expect(r.purchaseDate.value, DateTime(2026, 10, 7));
      expect(r.purchaseDate.confidence, medium);
      expect(r.totalMinor.value, 64900);
      expect(r.totalMinor.confidence, high);
      expect(r.productName.value, 'Bosch Serie 6 vaatwasser');
      expect(r.productName.confidence, medium);
      expect(r.vatMinor, 11264);
    });

    test('zonder totaalregel: hoogste bedrag als gok', () {
      final r = parse('''
Fietsenmaker de Spaak
Reparatie band 15,00
Ventiel 2,50''');

      expect(r.merchant.value, 'Fietsenmaker de Spaak');
      expect(r.merchant.confidence, low);
      expect(r.purchaseDate.confidence, unknown);
      expect(r.purchaseDate.value, isNull);
      expect(r.totalMinor.value, 1500);
      expect(r.totalMinor.confidence, low);
    });

    test('datum in de toekomst wordt genegeerd', () {
      final r = parse('''
Winkel X
Datum: 01-01-2030
Totaal 10,00''');
      expect(r.purchaseDate.value, isNull);
      expect(r.purchaseDate.confidence, unknown);
      expect(r.totalMinor.value, 1000);
    });

    test('ISO-datum en bedragen met een punt', () {
      final r = parse('''
JUMBO
Datum 2026-10-10
Pindakaas 3.49
TOTAAL 3.49''');
      expect(r.merchant.value, 'Jumbo');
      expect(r.purchaseDate.value, DateTime(2026, 10, 10));
      expect(r.totalMinor.value, 349);
      expect(r.productName.value, 'Pindakaas');
    });

    test('tekst zonder bedrag of datum is geen aankoopbewijs', () {
      final r = parse('''
Nooduitgang
Niet roken
Brandblusser''');
      expect(r.hasAnything, isFalse);
      expect(r.merchant.value, isNull);
    });

    test('lege of onleesbare tekst', () {
      expect(parse('').hasAnything, isFalse);
      expect(parse('   \n  \n').hasAnything, isFalse);
      final r = parse('@@@ ### ~~~');
      expect(r.totalMinor.confidence, unknown);
      expect(r.merchant.confidence, unknown);
    });
  });

  group('bedragen', () {
    List<int> values(String line) =>
        ReceiptParser.amountsIn(line).map((a) => a.value).toList();

    test('Nederlandse notatie', () {
      expect(values('Totaal EUR 1.348,95'), [134895]);
      expect(values('Theedoek 3,49'), [349]);
      expect(values('2 BANANEN 0,99 1,98'), [99, 198]);
      expect(values('€649,00'), [64900]);
    });

    test('korting is negatief', () {
      expect(values('BONUS KOFFIE -5,00'), [-500]);
    });

    test('datums, tijden en codes zijn geen bedragen', () {
      expect(values('Datum 03.09.2025'), isEmpty);
      expect(values('14:32 17-10-2026'), isEmpty);
      expect(values('Bon: 0042'), isEmpty);
      expect(values('Btw 21%'), isEmpty);
    });
  });

  group('datums', () {
    test('verschillende notaties', () {
      expect(ReceiptParser.datesIn('12-10-2026', today), [DateTime(2026, 10, 12)]);
      expect(ReceiptParser.datesIn('12/10/26', today), [DateTime(2026, 10, 12)]);
      expect(ReceiptParser.datesIn('3.9.2025', today), [DateTime(2025, 9, 3)]);
      expect(ReceiptParser.datesIn('2026-10-12', today), [DateTime(2026, 10, 12)]);
      expect(
        ReceiptParser.datesIn('8 okt. 2026', today),
        [DateTime(2026, 10, 8)],
      );
      expect(
        ReceiptParser.datesIn('1 maart 2026', today),
        [DateTime(2026, 3, 1)],
      );
    });

    test('ongeldige en onwaarschijnlijke datums worden genegeerd', () {
      expect(ReceiptParser.datesIn('31-02-2026', today), isEmpty);
      expect(ReceiptParser.datesIn('12-13-2026', today), isEmpty);
      expect(ReceiptParser.datesIn('01-01-1999', today), isEmpty);
      expect(ReceiptParser.datesIn('20-10-2026', today), isEmpty);
    });

    test('vandaag mag', () {
      expect(ReceiptParser.datesIn('19-10-2026', today), [today]);
    });
  });

  test('RecognizedField: controle nodig bij lage of onbekende zekerheid', () {
    expect(const RecognizedField('x', high).needsAttention, isFalse);
    expect(const RecognizedField('x', medium).needsAttention, isFalse);
    expect(const RecognizedField('x', low).needsAttention, isTrue);
    expect(const RecognizedField<String>.unknown().needsAttention, isTrue);
  });
}
