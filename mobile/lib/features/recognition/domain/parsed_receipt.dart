/// Hoe zeker de herkenning van een veld is.
///
/// Dit zijn **indicatieve** labels op basis van vaste regels, geen berekende
/// of statistisch gevalideerde kansen.
enum RecognitionConfidence {
  /// Gevonden bij een duidelijk kenmerk en bevestigd door een tweede bron
  /// (bijv. totaal = pinbedrag).
  high,

  /// Gevonden bij een duidelijk kenmerk, maar niet bevestigd.
  medium,

  /// Een gok op basis van de opbouw van het document.
  low,

  /// Niet gevonden.
  unknown,
}

/// Een herkende waarde met de zekerheid ervan.
class RecognizedField<T> {
  const RecognizedField(this.value, this.confidence);

  const RecognizedField.unknown()
    : value = null,
      confidence = RecognitionConfidence.unknown;

  final T? value;
  final RecognitionConfidence confidence;

  bool get isFound => value != null;

  /// Moet de gebruiker dit veld extra goed controleren?
  bool get needsAttention =>
      confidence == RecognitionConfidence.low ||
      confidence == RecognitionConfidence.unknown;

  @override
  String toString() => 'RecognizedField($value, ${confidence.name})';
}

/// Eén productregel op een bon of factuur.
class ParsedLineItem {
  const ParsedLineItem({required this.description, required this.amountMinor});

  final String description;

  /// Regelbedrag in centen (kan bij meerdere stuks hoger zijn dan de
  /// stukprijs).
  final int amountMinor;

  @override
  bool operator ==(Object other) =>
      other is ParsedLineItem &&
      other.description == description &&
      other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(description, amountMinor);

  @override
  String toString() => 'ParsedLineItem($description, $amountMinor)';
}

/// Resultaat van het verwerken van herkende tekst. Niets hiervan wordt
/// opgeslagen zonder controle door de gebruiker.
class ParsedReceipt {
  const ParsedReceipt({
    required this.merchant,
    required this.purchaseDate,
    required this.totalMinor,
    required this.productName,
    required this.lineItems,
    this.productCandidates = const [],
    this.currency = 'EUR',
    this.vatMinor,
  });

  static const empty = ParsedReceipt(
    merchant: RecognizedField.unknown(),
    purchaseDate: RecognizedField.unknown(),
    totalMinor: RecognizedField.unknown(),
    productName: RecognizedField.unknown(),
    lineItems: [],
  );

  final RecognizedField<String> merchant;

  /// Kalenderdatum (zonder tijd).
  final RecognizedField<DateTime> purchaseDate;

  /// Totaalbedrag van het hele document, in centen.
  final RecognizedField<int> totalMinor;

  /// Voorstel voor de productnaam (eerste productregel die geen
  /// bezorg- of servicekosten is).
  final RecognizedField<String> productName;

  final List<ParsedLineItem> lineItems;

  /// Productregels zonder bezorg- of servicekosten: de keuzes voor de
  /// gebruiker als er meerdere producten op één bon staan.
  final List<ParsedLineItem> productCandidates;

  final String currency;

  /// Btw-bedrag, alleen ter informatie.
  final int? vatMinor;

  bool get hasAnything =>
      merchant.isFound ||
      purchaseDate.isFound ||
      totalMinor.isFound ||
      lineItems.isNotEmpty;
}
