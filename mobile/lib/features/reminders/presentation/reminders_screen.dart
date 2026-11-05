import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/error_view.dart';
import '../../products/application/product_providers.dart';
import '../../products/presentation/widgets/category_icon.dart';
import '../../products/presentation/widgets/reminder_badge.dart';
import '../application/reminder_service.dart';
import '../../../l10n/app_strings.dart';

/// Hoofdschakelaar voor meldingen en de lijst met komende herinneringen.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    if (on) {
      bool granted;
      try {
        granted = await ref
            .read(reminderNotificationsProvider)
            .requestPermission();
      } catch (_) {
        granted = false;
      }
      ref.invalidate(notificationsEnabledProvider);
      if (!granted) {
        messenger.showSnackBar(
          SnackBar(content: Text(S.current.notificationsOffPhone)),
        );
      }
    }
    await ref.read(remindersEnabledProvider.notifier).set(on);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enabled = ref.watch(remindersEnabledProvider);
    final products = ref.watch(productsProvider);
    final today = Dates.dateOnly(ref.watch(clockProvider)());

    return Scaffold(
      appBar: AppBar(title: Text(S.current.reminders)),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(productsProvider),
        ),
        data: (products) {
          final upcoming =
              products
                  .where(
                    (p) =>
                        p.activeReminderDate != null &&
                        !p.activeReminderDate!.isBefore(today),
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      a.activeReminderDate!.compareTo(b.activeReminderDate!),
                );
          final on = enabled.value ?? true;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Card(
                child: SwitchListTile(
                  key: const Key('reminders.enabled'),
                  title: Text(S.current.enableReminders),
                  subtitle: Text(S.current.enableRemindersHelper),
                  value: on,
                  onChanged: enabled.isLoading
                      ? null
                      : (value) => _toggle(context, ref, value),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                header: true,
                child: Text(
                  S.current.upcomingReminders,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!on)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    S.current.remindersOff,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (upcoming.isEmpty)
                Text(
                  S.current.noUpcomingReminders,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (final product in upcoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: MergeSemantics(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 4,
                            vertical: AppSpacing.xs,
                          ),
                          leading: CategoryTile(category: product.category),
                          title: Text(product.name),
                          subtitle: Text(
                            '${ReminderText.relative(product.activeReminderDate!, today)}\n'
                            '${Dates.formatLong(product.activeReminderDate!)}',
                          ),
                          isThreeLine: true,
                          trailing: Icon(
                            on
                                ? Icons.notifications_active_outlined
                                : Icons.notifications_off_outlined,
                            color: on
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          onTap: () =>
                              context.push(AppRoutes.productDetail(product.id)),
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
