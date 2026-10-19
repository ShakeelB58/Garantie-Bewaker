import '../../documents/domain/document.dart';
import '../../recognition/domain/parsed_receipt.dart';

/// Gegevens voor het scherm "Product toevoegen" (via de router als `extra`).
class NewProductArgs {
  const NewProductArgs({this.documents = const [], this.recognition});

  /// Al veilig opgeslagen documenten die bij het opslaan worden gekoppeld.
  final List<StagedDocument> documents;

  /// Automatisch herkende gegevens, of `null` als er niet is herkend.
  final ParsedReceipt? recognition;
}
