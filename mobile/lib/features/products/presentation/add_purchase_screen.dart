import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Scherm "Aankoop toevoegen" met de drie invoermogelijkheden.
///
/// FASE 1: de opties zijn zichtbaar maar nog niet werkend. Ze tonen een
/// duidelijke melding in plaats van te doen alsof er iets gebeurt.
/// - Handmatig invoeren: fase 2
/// - PDF of afbeelding importeren: fase 3 en 4
/// - Kassabon scannen: fase 3 en 4
class AddPurchaseScreen extends StatelessWidget {
  const AddPurchaseScreen({super.key});

  void _notYetAvailable(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Deze functie is nog in ontwikkeling.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Aankoop toevoegen')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Hoe wil je je aankoop toevoegen?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _OptionCard(
            icon: Icons.photo_camera_outlined,
            title: 'Kassabon scannen',
            description: 'Maak een foto van een papieren bon.',
            onTap: () => _notYetAvailable(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OptionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'PDF of afbeelding importeren',
            description: 'Kies een factuur uit je bestanden of e-mail.',
            onTap: () => _notYetAvailable(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OptionCard(
            icon: Icons.edit_outlined,
            title: 'Handmatig invoeren',
            description: 'Vul de gegevens zelf in.',
            onTap: () => _notYetAvailable(context),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.primary,
          child: Icon(icon),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
