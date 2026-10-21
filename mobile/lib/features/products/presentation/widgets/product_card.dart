import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/dates.dart';
import '../../domain/product.dart';
import 'category_icon.dart';
import 'reminder_badge.dart';

/// Productkaart: categorie-icoon, naam, winkel, aankoopdatum en de
/// herinneringsstatus ("Over 12 dagen" of "Geen herinnering").
class ProductCard extends ConsumerWidget {
  const ProductCard({
    required this.product,
    required this.onTap,
    this.highlight,
    super.key,
  });

  final Product product;
  final VoidCallback onTap;

  /// Extra regel onder de kaartinhoud, bijv. "Herinnering op 12 nov. 2026".
  /// Vervangt de standaard herinneringsstatus.
  final String? highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = Dates.dateOnly(ref.watch(clockProvider)());

    return Card(
      clipBehavior: Clip.antiAlias,
      // Schermlezers lezen de kaart als één knop voor.
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              child: Row(
                children: [
                  CategoryTile(category: product.category),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.merchant != null)
                          Text(
                            product.merchant!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              Dates.formatShort(product.purchaseDate),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (highlight != null)
                              Text(
                                highlight!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              ReminderBadge(product: product, today: today),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
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
