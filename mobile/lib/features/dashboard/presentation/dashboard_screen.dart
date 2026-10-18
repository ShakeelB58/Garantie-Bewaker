import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/empty_state.dart';

/// Dashboard.
///
/// FASE 1: toont alleen de lege toestand. Productaantallen, naderende
/// herinneringen en recente aankopen volgen in fase 2, zodra de lokale
/// database bestaat.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GarantieBewaker')),
      body: EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Nog geen aankopen',
        message:
            'Bewaar je kassabonnen en facturen op één plek. '
            'Alles blijft op je eigen telefoon.',
        actionLabel: 'Aankoop toevoegen',
        onAction: () => context.push(AppRoutes.addPurchase),
      ),
    );
  }
}
