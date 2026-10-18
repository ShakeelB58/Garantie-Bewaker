import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/empty_state.dart';

/// Productoverzicht.
///
/// FASE 1: alleen de lege toestand. Lijst, zoeken, filteren en sorteren
/// volgen in fase 2.
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Producten')),
      body: const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Geen producten',
        message: 'Producten die je toevoegt, verschijnen hier.',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addPurchase),
        icon: const Icon(Icons.add),
        label: const Text('Toevoegen'),
      ),
    );
  }
}
