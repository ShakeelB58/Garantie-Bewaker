/// Vaste categorieën. De [key] wordt opgeslagen en mag nooit veranderen.
enum ProductCategory {
  electronics('electronics', 'Elektronica'),
  phoneTablet('phone_tablet', 'Telefoon en tablet'),
  computer('computer', 'Computer'),
  household('household', 'Huishoudelijk'),
  kitchen('kitchen', 'Keuken'),
  furniture('furniture', 'Meubels en wonen'),
  garden('garden_tools', 'Tuin en gereedschap'),
  clothing('clothing', 'Kleding en schoenen'),
  sports('sports', 'Sport en vrije tijd'),
  other('other', 'Overig');

  const ProductCategory(this.key, this.label);

  final String key;
  final String label;

  /// Onbekende waarden (bijv. uit een nieuwere app-versie) worden "Overig".
  static ProductCategory fromKey(String key) => ProductCategory.values
      .firstWhere((c) => c.key == key, orElse: () => ProductCategory.other);
}
