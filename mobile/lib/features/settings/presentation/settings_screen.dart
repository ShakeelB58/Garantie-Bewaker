import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/user_message.dart';
import '../../data_management/application/data_management_providers.dart';
import '../../reminders/application/reminder_service.dart';
import '../application/settings_providers.dart';

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
      appBar: AppBar(title: const Text('Instellingen')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          const _SectionHeader('Herinneringen'),
          ListTile(
            key: const Key('settings.reminderLead'),
            leading: const Icon(Icons.event_outlined),
            title: const Text('Standaardherinnering'),
            subtitle: Text(
              lead.value?.description ?? ReminderLead.standard.description,
            ),
            onTap: () => _chooseLead(context, ref, lead.value),
          ),
          ListTile(
            key: const Key('settings.notifications'),
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Meldingen'),
            subtitle: Text(switch (enabled) {
              AsyncData(value: true) => 'Aan',
              AsyncData(value: false) => 'Uit. Tik om meldingen toe te staan.',
              _ => 'Controleren…',
            }),
            onTap: enabled.value == true
                ? null
                : () => _requestPermission(context, ref),
          ),
          ListTile(
            key: const Key('settings.testNotification'),
            leading: const Icon(Icons.notification_add_outlined),
            title: const Text('Testmelding versturen'),
            subtitle: const Text(
              'Controleer of meldingen op je telefoon werken',
            ),
            onTap: () => _sendTest(context, ref),
          ),
          const _SectionHeader('Privacy en gegevens'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacy'),
            subtitle: const Text('Hoe GarantieBewaker met je gegevens omgaat'),
            onTap: () => _showPrivacy(context),
          ),
          ListTile(
            key: const Key('settings.export'),
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Gegevens exporteren'),
            subtitle: const Text(
              'Producten (CSV) en aankoopbewijzen in één ZIP-bestand',
            ),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            key: const Key('settings.deleteAll'),
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text(
              'Alle lokale gegevens verwijderen',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: const Text(
              'Producten, aankoopbewijzen, herinneringen en voorkeuren',
            ),
            onTap: () => _confirmDeleteAll(context, ref),
          ),
          const _SectionHeader('Over'),
          ListTile(
            key: const Key('settings.about'),
            leading: const Icon(Icons.info_outline),
            title: const Text('Over GarantieBewaker'),
            subtitle: Text(
              'Versie ${ref.watch(appVersionProvider).value ?? '…'}',
            ),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'GarantieBewaker',
              applicationVersion: ref.read(appVersionProvider).value,
              applicationLegalese:
                  'GarantieBewaker geeft geen juridisch advies. Door jou '
                  'ingestelde datums zijn herinneringen, geen vastgestelde '
                  'garantietermijnen.',
            ),
          ),
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
        title: const Text('Standaardherinnering'),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Wordt voorgesteld als je bij een product een herinnering '
              'aanzet. Je kunt de datum daar altijd zelf aanpassen.',
            ),
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
                      semanticLabel: 'Gekozen',
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
        _message(context, 'De voorkeur kon niet worden opgeslagen.');
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
      _message(
        context,
        'Meldingen staan uit. Zet ze aan in de instellingen van je telefoon, '
        'bij GarantieBewaker.',
      );
    }
    return granted;
  }

  Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
    if (!await _requestPermission(context, ref)) return;
    try {
      await ref.read(reminderNotificationsProvider).scheduleTest();
      if (context.mounted) {
        _message(
          context,
          'Over ongeveer een minuut krijg je een testmelding. Je kunt de app '
          'gewoon sluiten.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        _message(context, 'De testmelding kon niet worden ingepland.');
      }
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // Bij grote tekst kan het hele venster scrollen.
        scrollable: true,
        title: const Text('Gegevens exporteren'),
        content: const Text(
          'Je krijgt één ZIP-bestand met al je producten (als CSV, te openen '
          'in Excel of Numbers) en al je aankoopbewijzen.\n\n'
          'Het bestand bevat je aankoopgegevens. Bewaar het op een veilige '
          'plek en deel het alleen met mensen die je vertrouwt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exporteren'),
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
        builder: (_) => const _BusyDialog('Export maken…'),
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
      message =
          'Export bewaard: ${_count(export.productCount, 'product', 'producten')} '
          'en ${_count(export.documentCount, 'document', 'documenten')}.';
      if (export.missingDocuments > 0) {
        message +=
            ' ${_count(export.missingDocuments, 'document', 'documenten')} '
            'kon${export.missingDocuments == 1 ? '' : 'den'} niet worden '
            'gelezen.';
      }
    } catch (error) {
      debugPrint('Exporteren mislukt (${error.runtimeType})');
      if (navigator.mounted && navigator.canPop()) {
        // Alleen het voortgangsvenster sluiten als dat nog open is.
        navigator.popUntil((route) => route is! DialogRoute);
      }
      message = error is AppException
          ? error.userMessage
          : 'De export is niet gelukt. Probeer het opnieuw.';
    }
    if (context.mounted) _message(context, message);
  }

  static String _count(int n, String one, String many) =>
      '$n ${n == 1 ? one : many}';

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAllDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await wipeAllData(ref);
      if (!context.mounted) return;
      _message(context, 'Alle gegevens zijn verwijderd.');
      context.go(AppRoutes.dashboard);
    } catch (error) {
      debugPrint('Alles verwijderen mislukt (${error.runtimeType})');
      if (context.mounted) {
        _message(
          context,
          'Niet alles kon worden verwijderd. Probeer het opnieuw.',
        );
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
        title: const Text('Privacy'),
        content: const Text(
          '• Je aankopen en aankoopbewijzen worden alleen op deze telefoon '
          'opgeslagen.\n'
          '• Er is geen account nodig en er wordt niets naar een server '
          'gestuurd.\n'
          '• De app krijgt geen toegang tot je mailbox. Je deelt zelf een '
          'factuur met de app.\n'
          '• Tekstherkenning gebeurt op je telefoon, niet in de cloud.\n'
          '• Meldingen worden door je telefoon zelf getoond, zonder '
          'server. Op het vergrendelscherm van Android wordt de '
          'productnaam verborgen.\n'
          '• GarantieBewaker heeft zelf geen back-upfunctie. Verwijder je '
          'de app, dan verdwijnen ook de gegevens die erin zijn opgeslagen. '
          'Met "Gegevens exporteren" maak je zelf een kopie.\n'
          '• Met "Alle lokale gegevens verwijderen" wis je alles in één '
          'keer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sluiten'),
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
      title: const Text('Alle gegevens verwijderen?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dit verwijdert van deze telefoon:\n'
            '• alle producten\n'
            '• alle aankoopbewijzen (foto\'s en PDF\'s)\n'
            '• alle herinneringen en geplande meldingen\n'
            '• je voorkeuren\n\n'
            'Er is geen back-up of server: dit kan niet ongedaan worden '
            'gemaakt. Maak eerst een export als je iets wilt bewaren.',
          ),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            key: const Key('deleteAll.understood'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _understood,
            onChanged: (value) => setState(() => _understood = value ?? false),
            title: const Text('Ik begrijp dat dit niet terug te halen is'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuleren'),
        ),
        FilledButton(
          key: const Key('deleteAll.confirm'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: _understood ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Alles verwijderen'),
        ),
      ],
    );
  }
}
