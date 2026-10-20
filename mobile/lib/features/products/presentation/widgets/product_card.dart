import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/money.dart';
import '../../domain/product.dart';
import 'category_icon.dart';

/// Rustige productkaart: naam, winkel, aankoopdatum, prijs en eventueel
/// een extra regel (bijv. een naderende datum).
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onTap,
    this.highlight,
    super.key,
  });

  final Product product;
  final VoidCallback onTap;

  /// Extra regel onder de kaartinhoud, bijv. "Herinnering op 12 nov. 2026".
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = [
      if (product.merchant != null) product.merchant!,
      Dates.formatShort(product.purchaseDate),
    ];
    final reminder = product.activeReminderDate;
    final extraLine =
        highlight ??
        (reminder != null
            ? 'Herinnering op ${Dates.formatShort(reminder)}'
            : null);

    return Card(
      clipBehavior: Clip.antiAlias,
      // Schermlezers lezen de kaart als één knop voor.
      child: MergeSemantics(
        child: Semantics(
          button: onTap != null,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.primary,
                    child: Icon(product.category.icon),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitleParts.join(' · '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (extraLine != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  extraLine,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (product.purchasePriceMinor != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      Money.format(
                        product.purchasePriceMinor!,
                        product.currency,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
