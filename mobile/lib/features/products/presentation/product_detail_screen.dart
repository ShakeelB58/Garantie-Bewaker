import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../l10n/app_strings.dart';

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
        title: Text(S.current.deleteProductQuestion),
        content: Text(S.current.deleteProductBody(product.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.current.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.current.delete),
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
      ..showSnackBar(SnackBar(content: Text(S.current.productDeleted)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));
    final product = productAsync.value;

    return Scaffold(
      appBar: AppBar(title: Text(S.current.productDetails)),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(productsProvider),
        ),
        data: (product) => product == null
            ? Center(child: Text(S.current.productGone))
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
                child: _ActionButtons(
                  edit: OutlinedButton.icon(
                    key: const Key('product.edit'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 48),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(S.current.edit),
                    onPressed: () =>
                        context.push(AppRoutes.editProduct(product.id)),
                  ),
                  delete: FilledButton.icon(
                    key: const Key('product.delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size(64, 48),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(S.current.delete),
                    onPressed: () => _delete(context, ref, product),
                  ),
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
                          Text(product.name, style: theme.textTheme.titleLarge),
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
                          ? S.current.noWarrantyDate
                          : S.current.warrantyUntil(
                              Dates.formatShort(product.warrantyEndDate!),
                            ),
                      active: product.warrantyEndDate != null,
                    ),
                    _Pill(
                      icon: Icons.notifications_none,
                      text: reminderText == null
                          ? S.current.noReminder
                          : S.current.reminderPill(reminderText),
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
              title: Text(
                S.current.details,
                style: theme.textTheme.titleMedium,
              ),
              children: [
                _DetailRow(
                  label: S.current.category,
                  value: product.category.label,
                ),
                _DetailRow(
                  label: S.current.modelNumber,
                  value: product.modelNumber ?? S.current.notFilledIn,
                  copyKey: product.modelNumber == null
                      ? null
                      : const Key('product.copyModel'),
                ),
                _DetailRow(
                  label: S.current.serialNumber,
                  value: product.serialNumber ?? S.current.notFilledIn,
                  copyKey: product.serialNumber == null
                      ? null
                      : const Key('product.copySerial'),
                ),
                _DetailRow(
                  label: S.current.merchant,
                  value: product.merchant ?? S.current.notFilledIn,
                ),
                _DetailRow(
                  label: S.current.purchaseDate,
                  value: Dates.formatLong(product.purchaseDate),
                ),
                _DetailRow(
                  label: S.current.purchasePrice,
                  value: product.purchasePriceMinor == null
                      ? S.current.notFilledIn
                      : Money.format(
                          product.purchasePriceMinor!,
                          product.currency,
                        ),
                ),
                _DetailRow(
                  label: S.current.warrantyEndSelf,
                  value: product.warrantyEndDate == null
                      ? S.current.notFilledIn
                      : Dates.formatLong(product.warrantyEndDate!),
                ),
                _DetailRow(
                  label: S.current.reminder,
                  value: product.activeReminderDate == null
                      ? S.current.off
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
          S.current.warrantyDisclaimer,
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
        color: active
            ? theme.colorScheme.primaryContainer
            : AppColors.background,
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
    this.copyKey,
  });

  final String label;
  final String value;
  final bool isLast;

  /// Als gezet: een kopieerknop naast de waarde (bijv. voor het serienummer).
  final Key? copyKey;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(S.current.copied(label))));
  }

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
              if (copyKey != null)
                IconButton(
                  key: copyKey,
                  tooltip: S.current.copyLabel(label),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () => _copy(context),
                ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

/// Bewerken en Verwijderen naast elkaar, of onder elkaar bij grote tekst
/// (anders past "Verwijderen" niet op een halve schermbreedte).
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.edit, required this.delete});

  final Widget edit;
  final Widget delete;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(10) > 13;
    if (largeText) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          edit,
          const SizedBox(height: AppSpacing.sm),
          delete,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: edit),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(child: delete),
      ],
    );
  }
}
