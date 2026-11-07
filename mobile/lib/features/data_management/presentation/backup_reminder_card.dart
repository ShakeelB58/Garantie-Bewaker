import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../application/backup_status.dart';
import 'backup_actions.dart';
import '../../../l10n/app_strings.dart';

/// Kaart op Home die één keer per maand vraagt om een reservekopie te
/// maken. Verdwijnt na een export of na "Later" (voor een maand).
class BackupReminderCard extends ConsumerWidget {
  const BackupReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(backupReminderDueProvider)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Card(
        key: const Key('dashboard.backupReminder'),
        color: AppColors.tealContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      S.current.backupReminderTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(S.current.backupReminderBody),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                children: [
                  TextButton(
                    key: const Key('backupReminder.later'),
                    onPressed: () =>
                        ref.read(backupSnoozeProvider.notifier).snooze(),
                    child: Text(S.current.later),
                  ),
                  FilledButton(
                    key: const Key('backupReminder.now'),
                    onPressed: () => runExport(context, ref),
                    child: Text(S.current.backupNow),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
