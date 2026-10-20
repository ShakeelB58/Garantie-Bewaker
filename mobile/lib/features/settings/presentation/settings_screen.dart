import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../reminders/application/reminder_service.dart';
import '../application/settings_providers.dart';

/// Instellingen en privacy.
///
/// Export en gegevensverwijdering volgen in fase 5b.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _laterAvailable = 'Beschikbaar in een volgende versie';

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
              AsyncData(value: false) =>
                'Uit. Tik om meldingen toe te staan.',
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
            subtitle: const Text('Controleer of meldingen op je telefoon werken'),
            onTap: () => _sendTest(context, ref),
          ),
          const _SectionHeader('Privacy en gegevens'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacy'),
            subtitle: const Text('Hoe GarantieBewaker met je gegevens omgaat'),
            onTap: () => _showPrivacy(context),
          ),
          const ListTile(
            enabled: false,
            leading: Icon(Icons.file_download_outlined),
            title: Text('Gegevens exporteren'),
            subtitle: Text(_laterAvailable),
          ),
          const ListTile(
            enabled: false,
            leading: Icon(Icons.delete_outline),
            title: Text('Alle lokale gegevens verwijderen'),
            subtitle: Text(_laterAvailable),
          ),
          const _SectionHeader('Over'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Over GarantieBewaker'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'GarantieBewaker',
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

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _showPrivacy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy'),
        content: const SingleChildScrollView(
          child: Text(
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
            '• GarantieBewaker heeft zelf nog geen back-upfunctie. Verwijder '
            'je de app, dan verdwijnen ook de gegevens die erin zijn '
            'opgeslagen.',
          ),
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
