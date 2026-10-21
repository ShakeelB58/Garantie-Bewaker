import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/user_message.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/error_view.dart';
import '../../documents/presentation/product_documents_section.dart';
import '../application/product_providers.dart';
import '../domain/product.dart';
import 'widgets/category_icon.dart';
import 'widgets/reminder_badge.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // Bij grote tekst kan het hele venster scrollen.
        scrollable: true,
        title: const Text('Product verwijderen?'),
        content: Text(
          '"${product.name}" wordt definitief van deze telefoon verwijderd, '
          'inclusief alle aankoopbewijzen en herinneringen. Dit kan niet '
          'ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(productsProvider.notifier).delete(product.id);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(userMessageFor(error))));
      return;
    }
    if (context.mounted) context.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Product verwijderd.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));
    final product = productAsync.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Productdetails')),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(productsProvider),
        ),
        data: (product) => product == null
            ? const Center(child: Text('Dit product bestaat niet meer.'))
            : _ProductDetails(product: product),
      ),
      bottomNavigationBar: product == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('product.edit'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(64, 48),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Bewerken'),
                        onPressed: () =>
                            context.push(AppRoutes.editProduct(product.id)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('product.delete'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Verwijderen'),
                        onPressed: () => _delete(context, ref, product),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProductDetails extends ConsumerWidget {
  const _ProductDetails({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = Dates.dateOnly(ref.watch(clockProvider)());
    final subtitle = [
      if (product.brand != null) product.brand!,
      if (product.merchant != null) product.merchant!,
    ].join(' · ');
    final purchase = [
      Dates.formatShort(product.purchaseDate),
      if (product.purchasePriceMinor != null)
        Money.format(product.purchasePriceMinor!, product.currency),
    ].join(' · ');
    final reminderText = ReminderText.forProduct(product, today);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CategoryTile(category: product.category, size: 64),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.titleLarge,
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            purchase,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _Pill(
                      icon: Icons.verified_outlined,
                      text: product.warrantyEndDate == null
                          ? 'Geen garantiedatum'
                          : 'Garantie tot '
                                '${Dates.formatShort(product.warrantyEndDate!)}',
                      active: product.warrantyEndDate != null,
                    ),
                    _Pill(
                      icon: Icons.notifications_none,
                      text: reminderText == null
                          ? 'Geen herinnering'
                          : 'Herinnering: ${reminderText.toLowerCase()}',
                      active: product.activeReminderDate != null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Theme(
            // Geen extra lijnen rond het uitklapblok.
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Text('Gegevens', style: theme.textTheme.titleMedium),
              children: [
                _DetailRow(label: 'Categorie', value: product.category.label),
                _DetailRow(
                  label: 'Winkel of verkoper',
                  value: product.merchant ?? 'Niet ingevuld',
                ),
                _DetailRow(
                  label: 'Aankoopdatum',
                  value: Dates.formatLong(product.purchaseDate),
                ),
                _DetailRow(
                  label: 'Aankoopprijs',
                  value: product.purchasePriceMinor == null
                      ? 'Niet ingevuld'
                      : Money.format(
                          product.purchasePriceMinor!,
                          product.currency,
                        ),
                ),
                _DetailRow(
                  label: 'Garantie-einddatum (zelf ingevuld)',
                  value: product.warrantyEndDate == null
                      ? 'Niet ingevuld'
                      : Dates.formatLong(product.warrantyEndDate!),
                ),
                _DetailRow(
                  label: 'Herinnering',
                  value: product.activeReminderDate == null
                      ? 'Uit'
                      : Dates.formatLong(product.activeReminderDate!),
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ProductDocumentsSection(productId: product.id),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Bonvrij controleert niet of je recht hebt op garantie. '
          'De datums hierboven heb je zelf ingevuld.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.active});

  final IconData icon;
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? theme.colorScheme.primaryContainer : AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: active ? AppColors.navy : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
