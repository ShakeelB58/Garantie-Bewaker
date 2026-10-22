import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../products/application/product_providers.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/widgets/category_icon.dart';
import '../application/dashboard_summary.dart';

/// Home: begroeting, tegels met aantallen en recente aankopen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static String greeting(DateTime now) {
    if (now.hour < 12) return 'Goedemorgen,';
    if (now.hour < 18) return 'Goedemiddag,';
    return 'Goedenavond,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(productsProvider),
          ),
          data: (summary) => summary.totalProducts == 0
              ? EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Nog geen producten',
                  message:
                      'Voeg je eerste aankoop toe en houd al je garanties en '
                      'documenten veilig op één plek. Alles blijft op je '
                      'eigen telefoon.',
                  actionLabel: 'Aankoop toevoegen',
                  onAction: () => context.push(AppRoutes.addPurchase),
                )
              : _DashboardContent(summary: summary, now: now),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary, required this.now});

  final DashboardSummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = summary.totalProducts;
    final reminders = summary.upcoming
        .where((item) => item.kind == UpcomingKind.reminder)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      DashboardScreen.greeting(now),
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    count == 1
                        ? 'Je hebt 1 product geregistreerd.'
                        : 'Je hebt $count producten geregistreerd.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('dashboard.reminders'),
              tooltip: 'Herinneringen',
              icon: const Icon(Icons.notifications_none),
              onPressed: () => context.push(AppRoutes.reminders),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  key: const Key('dashboard.productCount'),
                  icon: Icons.inventory_2_outlined,
                  value: '$count',
                  label: count == 1 ? 'Product' : 'Producten',
                  onTap: () => context.go(AppRoutes.products),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: _StatTile(
                  key: const Key('dashboard.reminderCount'),
                  icon: Icons.event_outlined,
                  value: '$reminders',
                  label: reminders == 1
                      ? 'Binnenkort een herinnering'
                      : 'Binnenkort herinneringen',
                  onTap: () => context.push(AppRoutes.reminders),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(
          title: 'Recent toegevoegd',
          action: TextButton(
            onPressed: () => context.go(AppRoutes.products),
            child: const Text('Toon alles'),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < summary.recent.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 76),
                _RecentRow(product: summary.recent[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Eén regel in "Recent toegevoegd": icoon, naam, winkel · datum.
class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      ?product.merchant,
      Dates.formatShort(product.purchaseDate),
    ].join(' · ');
    return MergeSemantics(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CategoryTile(category: product.category, size: 44),
        title: Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.productDetail(product.id)),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(height: AppSpacing.sm),
                  Text(value, style: theme.textTheme.headlineSmall),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
          ),
          // Flexible: bij heel grote tekst mag "Toon alles" afbreken.
          if (action != null)
            Flexible(
              child: Align(alignment: Alignment.centerRight, child: action),
            ),
        ],
      ),
    );
  }
}
