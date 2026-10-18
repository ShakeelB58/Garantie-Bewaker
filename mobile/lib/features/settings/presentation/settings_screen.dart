import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Instellingen en privacy.
///
/// FASE 1: de privacyinformatie werkt. Herinneringsvoorkeuren, export en
/// gegevensverwijdering zijn zichtbaar maar uitgeschakeld (fase 5).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _laterAvailable = 'Beschikbaar in een volgende versie';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instellingen')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          const _SectionHeader('Herinneringen'),
          const ListTile(
            enabled: false,
            leading: Icon(Icons.notifications_outlined),
            title: Text('Standaardherinnering'),
            subtitle: Text(_laterAvailable),
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
