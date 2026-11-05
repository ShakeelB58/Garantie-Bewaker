import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/recognition/domain/parsed_receipt.dart';
import 'package:garantiebewaker/features/recognition/domain/receipt_parser.dart';

/// Engelse bonnen en facturen. Alle teksten hieronder zijn fictief.
void main() {
  const parser = ReceiptParser();
  final today = DateTime(2026, 10, 19);
  ParsedReceipt parse(String text) => parser.parse(text, today: today);

  test('Britse kassabon in ponden', () {
    final r = parse('''
NORTHGATE ELECTRICAL
12 High Street
Sampletown AB1 2CD
Tel 01234 567890
VAT No GB000000000
Date: 14/10/2026 15:42
Wireless Headphones 149.00
Carrier bag 0.10
SUBTOTAL 149.10
TOTAL £149.10
Card payment £149.10
VAT 20% 24.85
Thank you for shopping with us
''');
    expect(r.merchant.value, 'Northgate Electrical');
    expect(r.purchaseDate.value, DateTime(2026, 10, 14));
    expect(r.purchaseDate.confidence, RecognitionConfidence.high);
    expect(r.totalMinor.value, 14910);
    expect(r.totalMinor.confidence, RecognitionConfidence.high);
    expect(r.currency, 'GBP');
    expect(r.productName.value, 'Wireless Headphones');
    expect(r.productCandidates, hasLength(1));
    expect(r.vatMinor, 2485);
  });

  test('Amerikaanse factuur in dollars met maand eerst', () {
    final r = parse('''
Sample Gadgets Inc.
500 Main St
Springfield, IL 62701
INVOICE
Invoice date: 10/05/2026
Order no: 12345
Laptop 14 inch 1 1,099.00
Shipping 0.00
Subtotal 1,099.00
Sales tax 87.92
Total amount due \$1,186.92
Paid by Visa \$1,186.92
''');
    expect(r.merchant.value, 'Sample Gadgets');
    // Dollars: 10/05/2026 is 5 oktober (maand eerst).
    expect(r.purchaseDate.value, DateTime(2026, 10, 5));
    expect(r.totalMinor.value, 118692);
    expect(r.totalMinor.confidence, RecognitionConfidence.high);
    expect(r.currency, 'USD');
    expect(r.productName.value, 'Laptop 14 inch');
  });

  test('datums met maandnamen in het Engels', () {
    expect(ReceiptParser.datesIn('Date: 3 October 2026', today), [
      DateTime(2026, 10, 3),
    ]);
    expect(ReceiptParser.datesIn('Purchased October 3, 2026', today), [
      DateTime(2026, 10, 3),
    ]);
    expect(ReceiptParser.datesIn('Order date 3rd Oct 2026', today), [
      DateTime(2026, 10, 3),
    ]);
    expect(ReceiptParser.datesIn('12-Sep-2026', today), [
      DateTime(2026, 9, 12),
    ]);
  });

  test('dag of maand eerst', () {
    // Dag groter dan 12: altijd duidelijk.
    expect(ReceiptParser.datesIn('25/09/2026', today), [DateTime(2026, 9, 25)]);
    expect(ReceiptParser.datesIn('09/25/2026', today, monthFirst: true), [
      DateTime(2026, 9, 25),
    ]);
    expect(ReceiptParser.datesIn('09/25/2026', today), [DateTime(2026, 9, 25)]);
    // Twijfel: Europees, behalve bij een bon in dollars.
    expect(ReceiptParser.datesIn('05/10/2026', today), [DateTime(2026, 10, 5)]);
    expect(ReceiptParser.datesIn('05/10/2026', today, monthFirst: true), [
      DateTime(2026, 5, 10),
    ]);
  });

  test('Engelse bedragen', () {
    expect(ReceiptParser.amountsIn('TOTAL £1,299.00').single.value, 129900);
    expect(ReceiptParser.amountsIn('Item 12.99').single.value, 1299);
    expect(ReceiptParser.amountsIn('Discount -5.00').single.value, -500);
  });

  test('verzenddatum en "return by" zijn geen aankoopdatum', () {
    final r = parse('''
Example Store
Return by 30/11/2026
Delivered 16/10/2026
Purchased 12/10/2026
Kettle 39.99
Total 39.99
''');
    expect(r.purchaseDate.value, DateTime(2026, 10, 12));
  });

  test('valuta herkennen', () {
    expect(ReceiptParser.detectCurrency(['Total €12,50']), 'EUR');
    expect(ReceiptParser.detectCurrency(['TOTAL £12.50']), 'GBP');
    expect(ReceiptParser.detectCurrency(['Total \$12.50 USD']), 'USD');
    expect(ReceiptParser.detectCurrency(['Total CHF 12.50']), 'CHF');
    expect(ReceiptParser.detectCurrency(['Totaal 12,50']), 'EUR');
  });

  test('Nederlandse bon blijft hetzelfde werken', () {
    final r = parse('''
ELEKTRO NOORD
Voorbeeldstraat 1
1234 AB Voorbeeldstad
19-10-2026 14:32
Draadloze koptelefoon 149,00
TOTAAL EUR 149,00
PIN 149,00
''');
    expect(r.merchant.value, 'Elektro Noord');
    expect(r.purchaseDate.value, DateTime(2026, 10, 19));
    expect(r.totalMinor.value, 14900);
    expect(r.currency, 'EUR');
  });
}
