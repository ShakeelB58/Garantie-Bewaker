import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/user_message.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/error_view.dart';
import '../../documents/presentation/product_documents_section.dart';
import '../application/product_providers.dart';
import '../domain/product.dart';
import 'widgets/category_icon.dart';

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
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          if (product != null) ...[
            IconButton(
              tooltip: 'Bewerken',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(AppRoutes.editProduct(product.id)),
            ),
            IconButton(
              tooltip: 'Verwijderen',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, product),
            ),
          ],
        ],
      ),
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
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.primary,
              child: Icon(product.category.icon, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: theme.textTheme.headlineSmall),
                  if (product.brand != null)
                    Text(
                      product.brand!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Column(
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
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Column(
            children: [
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
        const SizedBox(height: AppSpacing.md),
        Text(
          'GarantieBewaker controleert niet of je recht hebt op garantie. '
          'De datums hierboven heb je zelf ingevuld.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ProductDocumentsSection(productId: product.id),
      ],
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
