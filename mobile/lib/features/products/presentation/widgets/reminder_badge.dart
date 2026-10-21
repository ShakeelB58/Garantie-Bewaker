import 'package:flutter/material.dart';

import '../../../../core/utils/dates.dart';
import '../../domain/product.dart';

/// Korte tekst over de herinnering van een product, bijv. "Over 12 dagen".
abstract final class ReminderText {
  static String? forProduct(Product product, DateTime today) {
    final date = product.activeReminderDate;
    if (date == null) return null;
    return relative(date, today);
  }

  static String relative(DateTime date, DateTime today) {
    final days = Dates.daysBetween(today, date);
    if (days < 0) return 'Herinnering geweest';
    if (days == 0) return 'Vandaag';
    if (days == 1) return 'Morgen';
    return 'Over $days dagen';
  }
}

/// Belletje met "Over 12 dagen", of grijs "Geen herinnering".
class ReminderBadge extends StatelessWidget {
  const ReminderBadge({required this.product, required this.today, super.key});

  final Product product;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = ReminderText.forProduct(product, today);
    final active = text != null && text != 'Herinnering geweest';
    final color = active
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (active) ...[
          Icon(Icons.notifications_none, size: 14, color: color),
          const SizedBox(width: 2),
        ],
        Flexible(
          child: Text(
            text ?? 'Geen herinnering',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
