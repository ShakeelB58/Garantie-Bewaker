import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../documents/data/document_picker.dart';
import '../../documents/domain/document.dart';
import '../../documents/presentation/document_capture.dart';
import '../../recognition/application/recognition_service.dart';
import '../../recognition/presentation/recognize_document.dart';
import 'new_product_args.dart';

/// Scherm "Aankoop toevoegen" met de drie invoermogelijkheden.
///
/// Scannen en importeren slaan het document veilig op, herkennen daarna de
/// gegevens op het toestel en openen het formulier met die gegevens als
/// voorstel. Lukt herkennen niet, dan vult de gebruiker alles zelf in.
class AddPurchaseScreen extends ConsumerWidget {
  const AddPurchaseScreen({super.key});

  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final staged = await acquireDocument(
      context,
      ref,
      DocumentSource.camera,
      type: DocumentType.receipt,
    );
    if (staged != null && context.mounted)
      await _openForm(context, ref, staged);
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final source = await showDocumentSourceSheet(
      context,
      sources: const [DocumentSource.files, DocumentSource.gallery],
    );
    if (source == null || !context.mounted) return;
    final staged = await acquireDocument(context, ref, source);
    if (staged != null && context.mounted)
      await _openForm(context, ref, staged);
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    StagedDocument staged,
  ) async {
    final recognition = await recognizeWithProgress(
      navigator: Navigator.of(context, rootNavigator: true),
      messenger: ScaffoldMessenger.maybeOf(context),
      service: ref.read(recognitionServiceProvider),
      document: staged,
    );
    if (!context.mounted) return;
    context.pushReplacement(
      AppRoutes.newProduct,
      extra: NewProductArgs(documents: [staged], recognition: recognition),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onTap: () => _scan(context, ref),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OptionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'PDF of afbeelding importeren',
            description:
                'Kies een factuur uit je bestanden, downloads of foto\'s.',
            onTap: () => _import(context, ref),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OptionCard(
            icon: Icons.edit_outlined,
            title: 'Handmatig invoeren',
            description: 'Vul de gegevens zelf in.',
            onTap: () => context.pushReplacement(AppRoutes.newProduct),
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
