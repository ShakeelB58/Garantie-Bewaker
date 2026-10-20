import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import 'parsed_receipt.dart';

/// Zet herkende tekst van een Nederlandse kassabon of factuur om naar
/// kandidaatvelden. Werkt met vaste regels; geen AI en geen netwerk.
///
/// Verwacht tekst met één regel per printregel (de OCR-laag zet woorden op
/// dezelfde hoogte al op één regel).
///
/// Uitgangspunten:
/// - Liever "onbekend" dan een verzonnen waarde.
/// - Datums in de toekomst of vóór 2000 worden genegeerd.
/// - Een garantietermijn wordt nooit afgeleid.
class ReceiptParser {
  const ReceiptParser();

  ParsedReceipt parse(String text, {required DateTime today}) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return ParsedReceipt.empty;

    final total = _findTotal(lines);
    final items = _findItems(lines, total.lineIndex);

    var totalConfidence = total.confidence;
    if (total.value != null &&
        totalConfidence == RecognitionConfidence.medium &&
        items.isNotEmpty &&
        items.fold<int>(0, (sum, i) => sum + i.amountMinor) == total.value) {
      // Productregels tellen exact op tot het totaal.
      totalConfidence = RecognitionConfidence.high;
    }

    final goods = items
        .where((i) => !_service.hasMatch(i.description))
        .toList();
    final productName = goods.isEmpty
        ? const RecognizedField<String>.unknown()
        : RecognizedField(
            goods.first.description,
            goods.length == 1
                ? RecognitionConfidence.medium
                : RecognitionConfidence.low,
          );

    final purchaseDate = _findDate(lines, Dates.dateOnly(today));

    // Geen bedrag en geen datum: dit is waarschijnlijk geen aankoopbewijs
    // (bijv. een foto van een muur of verpakking met wat losse tekst).
    // Dan ook geen winkelnaam gokken.
    if (total.value == null && items.isEmpty && purchaseDate.value == null) {
      return ParsedReceipt.empty;
    }

    return ParsedReceipt(
      merchant: _findMerchant(lines),
      purchaseDate: purchaseDate,
      totalMinor: total.value == null
          ? const RecognizedField<int>.unknown()
          : RecognizedField(total.value, totalConfidence),
      productName: productName,
      lineItems: items,
      productCandidates: goods,
      vatMinor: _findVat(lines),
    );
  }

  // ---------------------------------------------------------------------------
  // Bedragen

  /// `1.299,00`, `1299,00`, `29,99`, `3.49`; met optioneel minteken ervoor.
  static final _amount = RegExp(
    r'(?<![\d.,])(-\s?)?(\d{1,3}(?:\.\d{3})+,\d{2}|\d+,\d{2}|\d+\.\d{2})(?!\d|[.,]\d)',
  );

  /// Alle bedragen op een regel, met hun positie. Negatief = korting.
  static List<({int value, int start})> amountsIn(String line) {
    final result = <({int value, int start})>[];
    for (final match in _amount.allMatches(line)) {
      final value = Money.parseToMinor(match.group(2)!);
      if (value == null) continue;
      result.add((
        value: match.group(1) != null ? -value : value,
        start: match.start,
      ));
    }
    return result;
  }

  static List<int> _positiveAmounts(String line) => [
    for (final a in amountsIn(line))
      if (a.value > 0) a.value,
  ];

  // ---------------------------------------------------------------------------
  // Datums

  static const _months = {
    'jan': 1, 'feb': 2, 'mrt': 3, 'maa': 3, 'apr': 4, 'mei': 5, 'jun': 6, //
    'jul': 7, 'aug': 8, 'sep': 9, 'okt': 10, 'oct': 10, 'nov': 11, 'dec': 12,
  };
  static final _numericDate = RegExp(
    r'(?<!\d)(\d{1,2})[-/.](\d{1,2})[-/.](\d{4}|\d{2})(?!\d)',
  );
  static final _isoDate = RegExp(r'(?<!\d)(\d{4})-(\d{1,2})-(\d{1,2})(?!\d)');
  static final _textDate = RegExp(
    r'(?<![A-Za-z0-9])(\d{1,2})\s+(jan(?:uari)?|feb(?:ruari)?|mrt|maart|apr(?:il)?|mei|juni?|juli?|aug(?:ustus)?|sep(?:t(?:ember)?)?|okt(?:ober)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\.?\s+(\d{4})(?!\d)',
    caseSensitive: false,
  );
  static final _dateKeyword = RegExp(r'(datum|date|gekocht)', caseSensitive: false);

  /// Datums die niet de aankoopdatum zijn.
  static final _dateNegative = RegExp(
    r'(verval|uiterlijk|geldig tot|garantie tot|lever|retour|ruilen tot|houdbaar)',
    caseSensitive: false,
  );

  static DateTime? _makeDate(int year, int month, int day, DateTime today) {
    if (month < 1 || month > 12 || day < 1) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    if (year < 2000 || date.isAfter(today)) return null;
    return date;
  }

  static List<DateTime> datesIn(String line, DateTime today) {
    final result = <DateTime>[];
    for (final m in _isoDate.allMatches(line)) {
      final date = _makeDate(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        today,
      );
      if (date != null) result.add(date);
    }
    for (final m in _numericDate.allMatches(line)) {
      var year = int.parse(m.group(3)!);
      if (year < 100) year += 2000;
      final date = _makeDate(
        year,
        int.parse(m.group(2)!),
        int.parse(m.group(1)!),
        today,
      );
      if (date != null) result.add(date);
    }
    for (final m in _textDate.allMatches(line)) {
      final month = _months[m.group(2)!.toLowerCase().substring(0, 3)];
      if (month == null) continue;
      final date = _makeDate(
        int.parse(m.group(3)!),
        month,
        int.parse(m.group(1)!),
        today,
      );
      if (date != null) result.add(date);
    }
    return result;
  }

  RecognizedField<DateTime> _findDate(List<String> lines, DateTime today) {
    final keyed = <DateTime>[];
    final other = <DateTime>[];
    for (final line in lines) {
      final dates = datesIn(line, today);
      if (dates.isEmpty || _dateNegative.hasMatch(line)) continue;
      (_dateKeyword.hasMatch(line) ? keyed : other).addAll(dates);
    }
    if (keyed.isNotEmpty) {
      return RecognizedField(
        keyed.first,
        keyed.toSet().length == 1
            ? RecognitionConfidence.high
            : RecognitionConfidence.medium,
      );
    }
    if (other.isNotEmpty) {
      return RecognizedField(
        other.first,
        other.toSet().length == 1
            ? RecognitionConfidence.medium
            : RecognitionConfidence.low,
      );
    }
    return const RecognizedField.unknown();
  }

  // ---------------------------------------------------------------------------
  // Totaalbedrag

  static final _totalKeys = [
    (RegExp(r'\b(?:totaal te betalen|te betalen|eindtotaal|totaalbedrag)\b', caseSensitive: false), 3),
    (RegExp(r'\b(?:totaal|total)\b', caseSensitive: false), 2),
    (RegExp(r'\b(?:bedrag)\b', caseSensitive: false), 1),
  ];
  static final _totalNegative = RegExp(
    r'(sub\s?-?\s?totaal|subtotal|excl|korting|wisselgeld|retour|statiegeld|spaar|punten|aantal artikelen|totaal artikelen|art\.|omschrijving|aantal|prijs|voordeel|bespaard|besparing|saldo)',
    caseSensitive: false,
  );
  static final _vatWord = RegExp(r'\b(btw|vat)\b', caseSensitive: false);
  static final _incl = RegExp(r'incl', caseSensitive: false);
  static final _payment = RegExp(
    r'\b(pin|pinnen|betaald|contant|maestro|v ?pay|visa|mastercard|creditcard|ideal|betaling|bankpas)\b',
    caseSensitive: false,
  );

  static int _totalPriority(String line) {
    if (_totalNegative.hasMatch(line)) return 0;
    if (_vatWord.hasMatch(line) && !_incl.hasMatch(line)) return 0;
    for (final (pattern, priority) in _totalKeys) {
      if (pattern.hasMatch(line)) return priority;
    }
    return 0;
  }

  ({int? value, RecognitionConfidence confidence, int? lineIndex}) _findTotal(
    List<String> lines,
  ) {
    final candidates = <({int priority, int value, int index})>[];
    final payments = <int>[];
    final all = <int>[];
    int? firstTotalIndex;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final amounts = _positiveAmounts(line);
      all.addAll(amounts);
      final priority = _totalPriority(line);
      if (priority > 0) {
        int? value = amounts.isNotEmpty ? amounts.last : null;
        // "TOTAAL" met het bedrag op de volgende regel.
        if (value == null && priority >= 2 && i + 1 < lines.length) {
          final next = _positiveAmounts(lines[i + 1]);
          if (next.isNotEmpty && _totalPriority(lines[i + 1]) == 0) {
            value = next.last;
          }
        }
        if (value != null) {
          candidates.add((priority: priority, value: value, index: i));
          firstTotalIndex ??= i;
        }
      }
      if (_payment.hasMatch(line) && amounts.isNotEmpty) {
        payments.add(amounts.last);
      }
    }

    if (candidates.isNotEmpty) {
      var best = candidates.first;
      for (final c in candidates.skip(1)) {
        if (c.priority > best.priority ||
            (c.priority == best.priority && c.value > best.value)) {
          best = c;
        }
      }
      final agrees =
          payments.contains(best.value) ||
          (candidates.length > 1 &&
              candidates.every((c) => c.value == best.value));
      return (
        value: best.value,
        confidence: agrees
            ? RecognitionConfidence.high
            : RecognitionConfidence.medium,
        lineIndex: firstTotalIndex,
      );
    }
    if (payments.isNotEmpty) {
      return (
        value: payments.reduce((a, b) => a > b ? a : b),
        confidence: RecognitionConfidence.medium,
        lineIndex: null,
      );
    }
    if (all.isNotEmpty) {
      return (
        value: all.reduce((a, b) => a > b ? a : b),
        confidence: RecognitionConfidence.low,
        lineIndex: null,
      );
    }
    return (value: null, confidence: RecognitionConfidence.unknown, lineIndex: null);
  }

  // ---------------------------------------------------------------------------
  // Winkel

  static const _knownMerchants = [
    'Albert Heijn', 'Jumbo', 'Lidl', 'Aldi', 'Plus', 'Dirk', 'Coop', 'Spar', //
    'HEMA', 'Action', 'Kruidvat', 'Etos', 'Blokker', 'Xenos', 'MediaMarkt',
    'Media Markt', 'Coolblue', 'bol.com', 'BCC', 'Expert', 'Gamma', 'Praxis',
    'Karwei', 'Hornbach', 'IKEA', 'Leen Bakker', 'Kwantum', 'Intratuin',
    'Decathlon', 'Intertoys', 'Bart Smit', 'Wehkamp', 'Zalando',
    'Alternate', 'Megekko', 'Amazon', 'Primark', 'H&M', 'Zeeman', 'Wibra',
    'Bijenkorf', 'Big Bazar', 'Trekpleister', 'Gall & Gall', 'Jysk', 'Fonq',
    'Beter Bed', 'Electro World', 'Euronics',
  ];
  static const _canonical = {'media markt': 'MediaMarkt'};

  static final _merchantSkip = RegExp(
    r'(factuur|kassabon|\bbon\b|datum|\btel\b|telefoon|www\.|http|@|btw|kvk|iban|klant|order|bestel|kassa|filiaal|welkom|bedankt|fictie|^\d)',
    caseSensitive: false,
  );
  static final _street = RegExp(
    r'\b[\w-]+(straat|laan|weg|plein|gracht|kade|singel|dijk|steeg|hof|park|markt)\s+\d+',
    caseSensitive: false,
  );
  static final _postcode = RegExp(r'\b\d{4}\s?[A-Z]{2}\b');
  static final _legalSuffix = RegExp(
    r'\s*\b(b\.?\s?v\.?|v\.?o\.?f\.?|n\.?v\.?)\s*$',
    caseSensitive: false,
  );
  static final _letter = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');

  RecognizedField<String> _findMerchant(List<String> lines) {
    for (final line in lines.take(6)) {
      for (final name in _knownMerchants) {
        final pattern = RegExp(
          '(?<![A-Za-z])${RegExp.escape(name)}(?![A-Za-z])',
          caseSensitive: false,
        );
        // Ook als een logo als losse letter ervoor wordt gelezen ("OKRUIDVAT").
        final withLogo =
            name.length >= 5 &&
            RegExp(
              '^[^A-Za-z]{0,3}[A-Za-z]{1,2}${RegExp.escape(name)}(?![A-Za-z])',
              caseSensitive: false,
            ).hasMatch(line);
        if (pattern.hasMatch(line) || withLogo) {
          return RecognizedField(
            _canonical[name.toLowerCase()] ?? name,
            RecognitionConfidence.high,
          );
        }
      }
    }
    for (final line in lines.take(5)) {
      final letters = _letter.allMatches(line).length;
      if (letters < 3 || letters / line.length < 0.5) continue;
      if (amountsIn(line).isNotEmpty ||
          _merchantSkip.hasMatch(line) ||
          _street.hasMatch(line) ||
          _postcode.hasMatch(line)) {
        continue;
      }
      var name = line.replaceAll(_legalSuffix, '').trim();
      name = name.replaceAll(RegExp(r'^[\s\-:]+|[\s\-:]+$'), '');
      // Losse letter of symbool van een logo ervoor ("O Bakkerij Jansen").
      name = name.replaceFirst(
        RegExp(r'^(?:[^\sA-Za-z0-9]+|[A-Za-z0-9])\s+(?=\S{3})'),
        '',
      );
      if (name.isEmpty) continue;
      final confident = _isUpperCase(line) || _legalSuffix.hasMatch(line);
      if (_isUpperCase(name)) {
        name = name.split(' ').map(_capitalize).join(' ');
      }
      return RecognizedField(
        name,
        confident ? RecognitionConfidence.medium : RecognitionConfidence.low,
      );
    }
    return const RecognizedField.unknown();
  }

  // ---------------------------------------------------------------------------
  // Productregels

  static final _itemSkip = RegExp(
    r'(totaal|total|te betalen|btw|\bvat\b|\bpin\b|betaald|contant|wisselgeld|korting|subtotaal|datum|factuur|\btel\b|kvk|iban|omschrijving|aantal\b.*bedrag|bedrag$|bonnummer|kassa|statiegeld retour|spaar|zegels|maestro|visa|mastercard|\bbon\b|voordeel|bespaard|besparing|saldo|punten|klantenkaart|klantenpas|terminal|transactie|autorisatie|wisselgeld)',
    caseSensitive: false,
  );
  /// Einde van de productregels (alleen als er een bedrag bij staat, zodat
  /// een kolomkop als "Prijs Totaal" niet telt).
  static final _itemsEnd = RegExp(
    r'(sub\s?-?\s?totaal|subtotal|\btotaal\b|\btotal\b|te betalen|aantal artikelen|totaal artikelen|aantal producten)',
    caseSensitive: false,
  );
  static final _itemsEndAlways = RegExp(
    r'(aantal artikelen|totaal artikelen|aantal producten)',
    caseSensitive: false,
  );

  static final _service = RegExp(
    r'(bezorg|verzend|installatie|servicekosten|statiegeld|tasje|\btas\b|verpakking|administratie)',
    caseSensitive: false,
  );

  /// Regel met een aantal of stuksprijs, bijv. "2 x 8,49" of "8,49 per stuk".
  static final _quantityLine = RegExp(
    r'(^\s*\d+([.,]\d+)?\s*(x|×|st\.?|stuks?|kg)(?![A-Za-z])|\bper\s*(stuk|st|kg|stuks)\b|\s(à|@)\s?\d)',
    caseSensitive: false,
  );
  static final _quantityPhrase = RegExp(
    r'(\b\d+([.,]\d+)?\s*(x|×|st\.?|stuks?)(?![A-Za-z])|\bper\s*(stuk|st|kg|stuks)\b|\s(à|@)\s*$)',
    caseSensitive: false,
  );

  /// Productnaam zonder valuta, aantallen en artikelcodes.
  static String _cleanDescription(String text) => text
      .trim()
      .replaceAll(RegExp(r'(EUR|€)\s*$', caseSensitive: false), '')
      .trim()
      .replaceAll(_quantityPhrase, ' ')
      .trim()
      .replaceAll(RegExp(r'^\d{4,}\s+'), '')
      .replaceAll(RegExp(r'\s+\d{1,3}$'), '')
      .replaceAll(RegExp(r'^\d{1,3}\s+(?=[A-Za-z])'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s\-:]+|[\s\-:]+$'), '');

  /// Minstens 3 letters en vooral letters (geen artikelcode of prijsregel).
  static bool _looksLikeName(String text) {
    final letters = _letter.allMatches(text).length;
    final chars = text.replaceAll(RegExp(r'\s'), '').length;
    return letters >= 3 && chars > 0 && letters / chars >= 0.5;
  }

  static String _niceCase(String text) => _isUpperCase(text)
      ? text[0] + text.substring(1).toLowerCase()
      : text;

  List<ParsedLineItem> _findItems(List<String> lines, int? stopIndex) {
    // Productregels staan boven het (sub)totaal. Alles daaronder is
    // betaal-, spaar- of voordeelinformatie, ook als het echte totaal pas
    // helemaal onderaan de bon staat.
    var end = stopIndex ?? lines.length;
    for (var i = 0; i < end; i++) {
      final line = lines[i];
      if (_itemsEnd.hasMatch(line) &&
          (amountsIn(line).isNotEmpty || _itemsEndAlways.hasMatch(line))) {
        end = i;
        break;
      }
    }
    final items = <ParsedLineItem>[];
    // Naam op een eigen regel, met aantal en prijs op de regel eronder.
    String? pendingName;
    for (final line in lines.take(end)) {
      if (_itemSkip.hasMatch(line)) {
        pendingName = null;
        continue;
      }
      final amounts = amountsIn(line);
      if (amounts.isEmpty) {
        final name = _cleanDescription(line);
        pendingName = _looksLikeName(name) ? name : null;
        continue;
      }
      final value = amounts.last.value;
      final description = _cleanDescription(
        line.substring(0, amounts.first.start),
      );
      if (!_looksLikeName(description)) {
        // Regel met alleen aantal en prijs ("2 x 8,49 per stuk 16,98"):
        // hoort bij de naam erboven. De stuksprijs is de prijs van het product.
        if (pendingName != null && _quantityLine.hasMatch(line) && value > 0) {
          final unit = amounts.first.value;
          items.add(
            ParsedLineItem(
              description: _niceCase(pendingName),
              amountMinor: unit > 0 ? unit : value,
            ),
          );
        }
        pendingName = null;
        if (items.length == 50) break;
        continue;
      }
      pendingName = null;
      if (value <= 0) continue;
      items.add(
        ParsedLineItem(description: _niceCase(description), amountMinor: value),
      );
      if (items.length == 50) break;
    }
    return items;
  }

  // ---------------------------------------------------------------------------
  // Btw (alleen informatief)

  int? _findVat(List<String> lines) {
    var total = 0;
    var found = false;
    for (final line in lines) {
      if (!_vatWord.hasMatch(line) || !line.contains('%')) continue;
      if (RegExp(r'excl|incl', caseSensitive: false).hasMatch(line)) continue;
      final amounts = _positiveAmounts(line);
      if (amounts.isNotEmpty) {
        total += amounts.last;
        found = true;
      }
    }
    return found ? total : null;
  }

  // ---------------------------------------------------------------------------

  static bool _isUpperCase(String s) =>
      s == s.toUpperCase() && s != s.toLowerCase();

  static String _capitalize(String word) => word.isEmpty
      ? word
      : word[0].toUpperCase() + word.substring(1).toLowerCase();
}
