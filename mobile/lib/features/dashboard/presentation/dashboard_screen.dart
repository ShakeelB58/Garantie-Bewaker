import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../products/application/product_providers.dart';
import '../../products/presentation/widgets/product_card.dart';
import '../application/dashboard_summary.dart';

/// Dashboard: aantal producten, naderende datums en recente aankopen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('GarantieBewaker')),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(productsProvider),
        ),
        data: (summary) => summary.totalProducts == 0
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Nog geen aankopen',
                message:
                    'Bewaar je kassabonnen en facturen op één plek. '
                    'Alles blijft op je eigen telefoon.',
                actionLabel: 'Aankoop toevoegen',
                onAction: () => context.push(AppRoutes.addPurchase),
              )
            : _DashboardContent(summary: summary),
      ),
      floatingActionButton: summary.value?.totalProducts == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.addPurchase),
              icon: const Icon(Icons.add),
              label: const Text('Aankoop toevoegen'),
            ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary});

  final DashboardSummary summary;

  String _upcomingText(UpcomingItem item) {
    final date = Dates.formatShort(item.date);
    return switch (item.kind) {
      UpcomingKind.reminder => 'Herinnering op $date',
      UpcomingKind.warrantyEnd => 'Door jou ingevulde garantie-einddatum: $date',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = summary.totalProducts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        96,
      ),
      children: [
        Card(
          child: InkWell(
            onTap: () => context.go(AppRoutes.products),
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count',
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          count == 1
                              ? 'geregistreerd product'
                              : 'geregistreerde producten',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(
          title: 'Binnenkort',
          subtitle:
              'Ingestelde datums in de komende '
              '${DashboardSummary.upcomingWindowDays} dagen',
        ),
        if (summary.upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Geen datums in de komende '
              '${DashboardSummary.upcomingWindowDays} dagen.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final item in summary.upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ProductCard(
                product: item.product,
                highlight: _upcomingText(item),
                onTap: () =>
                    context.push(AppRoutes.productDetail(item.product.id)),
              ),
            ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionHeader(title: 'Recent toegevoegd'),
        for (final product in summary.recent)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ProductCard(
              product: product,
              onTap: () => context.push(AppRoutes.productDetail(product.id)),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
