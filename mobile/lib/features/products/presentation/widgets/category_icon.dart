import 'package:flutter/material.dart';

import '../../domain/product_category.dart';

extension ProductCategoryIcon on ProductCategory {
  IconData get icon => switch (this) {
    ProductCategory.electronics => Icons.tv_outlined,
    ProductCategory.phoneTablet => Icons.smartphone_outlined,
    ProductCategory.computer => Icons.laptop_outlined,
    ProductCategory.household => Icons.local_laundry_service_outlined,
    ProductCategory.kitchen => Icons.kitchen_outlined,
    ProductCategory.furniture => Icons.chair_outlined,
    ProductCategory.garden => Icons.handyman_outlined,
    ProductCategory.clothing => Icons.checkroom_outlined,
    ProductCategory.sports => Icons.directions_bike_outlined,
    ProductCategory.other => Icons.category_outlined,
  };
}
