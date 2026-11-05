import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/user_message.dart';
import '../../data_management/application/data_management_providers.dart';
import '../../demo/demo_data.dart';
import '../../reminders/application/reminder_service.dart';
import '../application/settings_providers.dart';
import '../../../l10n/app_strings.dart';

/// Instellingen en privacy.
///
/// Herinneringen, privacy, export, alles verwijderen en app-informatie.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lead = ref.watch(reminderLeadProvider);
    final enabled = ref.watch(notificationsEnabledProvider);
    return Scaffold(
      appBar: AppBar(title: Text(S.current.navSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          _SectionHeader(S.current.reminders),
          ListTile(
            key: const Key('settings.reminderLead'),
            leading: const Icon(Icons.event_outlined),
            title: Text(S.current.defaultReminder),
            subtitle: Text(
              lead.value?.description ?? ReminderLead.standard.description,
            ),
            onTap: () => _chooseLead(context, ref, lead.value),
          ),
          ListTile(
            key: const Key('settings.notifications'),
            leading: const Icon(Icons.notifications_outlined),
            title: Text(S.current.notifications),
            subtitle: Text(switch (enabled) {
              AsyncData(value: true) => S.current.on,
              AsyncData(value: false) => S.current.notificationsOffTap,
              _ => S.current.checking,
            }),
            onTap: enabled.value == true
                ? null
                : () => _requestPermission(context, ref),
          ),
          ListTile(
            key: const Key('settings.testNotification'),
            leading: const Icon(Icons.notification_add_outlined),
            title: Text(S.current.sendTestNotification),
            subtitle: Text(S.current.sendTestNotificationSubtitle),
            onTap: () => _sendTest(context, ref),
          ),
          _SectionHeader(S.current.privacyAndData),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(S.current.privacy),
            subtitle: Text(S.current.privacySubtitle),
            onTap: () => _showPrivacy(context),
          ),
          ListTile(
            key: const Key('settings.export'),
            leading: const Icon(Icons.file_download_outlined),
            title: Text(S.current.exportData),
            subtitle: Text(S.current.exportDataSubtitle),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            key: const Key('settings.deleteAll'),
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: Text(
              S.current.deleteAllLocal,
              style: const TextStyle(color: AppColors.error),
            ),
            subtitle: Text(S.current.deleteAllLocalSubtitle),
            onTap: () => _confirmDeleteAll(context, ref),
          ),
          _SectionHeader(S.current.about),
          ListTile(
            key: const Key('settings.about'),
            leading: const Icon(Icons.info_outline),
            title: Text(S.current.aboutBonvrij),
            subtitle: Text(
              S.current.version(ref.watch(appVersionProvider).value ?? '…'),
            ),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Bonvrij',
              applicationVersion: ref.read(appVersionProvider).value,
              applicationLegalese: S.current.aboutLegalese,
            ),
          ),
          // Alleen in de testversie (debug); nooit in de App Store-versie.
          if (ref.watch(demoDataOptionVisibleProvider)) ...[
            _SectionHeader(S.current.testVersion),
            ListTile(
              key: const Key('settings.demoData'),
              leading: const Icon(Icons.science_outlined),
              title: Text(S.current.loadDemoData),
              subtitle: Text(S.current.loadDemoDataSubtitle),
              onTap: () => _loadDemoData(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _chooseLead(
    BuildContext context,
    WidgetRef ref,
    ReminderLead? current,
  ) async {
    final chosen = await showDialog<ReminderLead>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(S.current.defaultReminder),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(S.current.defaultReminderExplanation),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final lead in ReminderLead.values)
            SimpleDialogOption(
              key: Key('settings.lead.${lead.days}'),
              onPressed: () => Navigator.of(context).pop(lead),
              child: Row(
                children: [
                  Expanded(child: Text(lead.description)),
                  if (lead == current)
                    Icon(
                      Icons.check,
                      semanticLabel: S.current.chosen,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    try {
      await ref.read(reminderLeadProvider.notifier).set(chosen);
    } catch (_) {
      if (context.mounted) {
        _message(context, S.current.preferenceNotSaved);
      }
    }
  }

  Future<bool> _requestPermission(BuildContext context, WidgetRef ref) async {
    bool granted;
    try {
      granted = await ref
          .read(reminderNotificationsProvider)
          .requestPermission();
    } catch (_) {
      granted = false;
    }
    ref.invalidate(notificationsEnabledProvider);
    if (!granted && context.mounted) {
      _message(context, S.current.notificationsOffSettings);
    }
    return granted;
  }

  Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
    if (!await _requestPermission(context, ref)) return;
    try {
      await ref.read(reminderNotificationsProvider).scheduleTest();
      if (context.mounted) {
        _message(context, S.current.testNotificationScheduled);
      }
    } catch (_) {
      if (context.mounted) {
        _message(context, S.current.testNotificationFailed);
      }
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // Bij grote tekst kan het hele venster scrollen.
        scrollable: true,
        title: Text(S.current.exportData),
        content: Text(S.current.exportExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.current.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.current.export),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    navigator.push<void>(
      DialogRoute<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _BusyDialog(S.current.creatingExport),
      ),
    );
    String message;
    try {
      final export = await ref.read(exportServiceProvider).build();
      if (navigator.mounted) navigator.pop();
      final saved = await ref
          .read(exportSaverProvider)
          .save(
            fileName: export.fileName,
            bytes: export.bytes,
            mimeType: 'application/zip',
          );
      if (!saved) return;
      message = S.current.exportSaved(
        export.productCount,
        export.documentCount,
      );
      if (export.missingDocuments > 0) {
        message += S.current.exportMissing(export.missingDocuments);
      }
    } catch (error) {
      debugPrint('Exporteren mislukt (${error.runtimeType})');
      if (navigator.mounted && navigator.canPop()) {
        // Alleen het voortgangsvenster sluiten als dat nog open is.
        navigator.popUntil((route) => route is! DialogRoute);
      }
      message = error is AppException
          ? error.userMessage
          : S.current.exportFailed;
    }
    if (context.mounted) _message(context, message);
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAllDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await wipeAllData(ref);
      if (!context.mounted) return;
      _message(context, S.current.allDataDeleted);
      context.go(AppRoutes.dashboard);
    } catch (error) {
      debugPrint('Alles verwijderen mislukt (${error.runtimeType})');
      if (context.mounted) {
        _message(context, S.current.notEverythingDeleted);
      }
    }
  }

  Future<void> _loadDemoData(BuildContext context, WidgetRef ref) async {
    try {
      final count = await ref.read(demoDataLoaderProvider).load();
      if (context.mounted) {
        _message(context, S.current.demoDataAdded(count));
      }
    } catch (error) {
      debugPrint('Voorbeeldgegevens laden mislukt (${error.runtimeType})');
      if (context.mounted) {
        _message(context, S.current.demoDataFailed);
      }
    }
  }

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _showPrivacy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        // Bij grote tekst kan het hele venster scrollen.
        scrollable: true,
        title: Text(S.current.privacy),
        content: Text(S.current.privacyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.current.close),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BusyDialog extends StatelessWidget {
  const _BusyDialog(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        // Bij grote tekst kan het hele venster scrollen.
        scrollable: true,
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

/// Bevestiging met een vinkje, zodat niemand per ongeluk alles verwijdert.
class _DeleteAllDialog extends StatefulWidget {
  const _DeleteAllDialog();

  @override
  State<_DeleteAllDialog> createState() => _DeleteAllDialogState();
}

class _DeleteAllDialogState extends State<_DeleteAllDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Bij grote tekst kan het hele venster scrollen.
      scrollable: true,
      title: Text(S.current.deleteAllQuestion),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.current.deleteAllBody),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            key: const Key('deleteAll.understood'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _understood,
            onChanged: (value) => setState(() => _understood = value ?? false),
            title: Text(S.current.deleteAllUnderstood),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(S.current.cancel),
        ),
        FilledButton(
          key: const Key('deleteAll.confirm'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: _understood ? () => Navigator.of(context).pop(true) : null,
          child: Text(S.current.deleteAllConfirm),
        ),
      ],
    );
  }
}
