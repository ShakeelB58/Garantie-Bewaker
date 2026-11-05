import '../../../l10n/app_strings.dart';

/// Vaste categorieën. De [key] wordt opgeslagen en mag nooit veranderen.
enum ProductCategory {
  electronics('electronics'),
  phoneTablet('phone_tablet'),
  computer('computer'),
  household('household'),
  kitchen('kitchen'),
  furniture('furniture'),
  garden('garden_tools'),
  clothing('clothing'),
  sports('sports'),
  other('other');

  const ProductCategory(this.key);

  final String key;

  /// Naam in de taal van de app.
  String get label {
    final s = S.current;
    return switch (this) {
      electronics => s.catElectronics,
      phoneTablet => s.catPhoneTablet,
      computer => s.catComputer,
      household => s.catHousehold,
      kitchen => s.catKitchen,
      furniture => s.catFurniture,
      garden => s.catGarden,
      clothing => s.catClothing,
      sports => s.catSports,
      other => s.catOther,
    };
  }

  /// Onbekende waarden (bijv. uit een nieuwere app-versie) worden "Overig".
  static ProductCategory fromKey(String key) => ProductCategory.values
      .firstWhere((c) => c.key == key, orElse: () => ProductCategory.other);
}
