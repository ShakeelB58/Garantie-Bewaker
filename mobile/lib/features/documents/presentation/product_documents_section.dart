import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/user_message.dart';
import '../application/document_service.dart';
import '../domain/document.dart';
import 'document_capture.dart';
import 'document_widgets.dart';

/// Aankoopbewijzen op het detailscherm van een product.
class ProductDocumentsSection extends ConsumerWidget {
  const ProductDocumentsSection({required this.productId, super.key});

  final String productId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    // De container blijft bruikbaar, ook als dit scherm intussen sluit.
    final container = ProviderScope.containerOf(context);
    final source = await showDocumentSourceSheet(context);
    if (source == null || !context.mounted) return;

    final service = ref.read(documentServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final staged = await acquireDocument(context, ref, source);
    if (staged == null) return;
    try {
      await service.attach(staged, productId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Document toegevoegd.')),
      );
    } catch (error) {
      await service.discard(staged);
      messenger.showSnackBar(SnackBar(content: Text(userMessageFor(error))));
    }
    container.invalidate(documentsForProductProvider(productId));
  }

  Future<void> _changeType(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) async {
    final container = ProviderScope.containerOf(context);
    final service = ref.read(documentServiceProvider);
    final type = await showDocumentTypeDialog(context, document.type);
    if (type == null || type == document.type) return;
    await service.changeType(document, type);
    container
      ..invalidate(documentsForProductProvider(productId))
      ..invalidate(documentByIdProvider(document.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final documents = ref.watch(documentsForProductProvider(productId));

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text('Aankoopbewijzen', style: theme.textTheme.titleMedium),
          ),
          documents.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(userMessageFor(error)),
            ),
            data: (documents) => documents.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'Nog geen documenten. Voeg een kassabon, factuur of '
                      'garantiebewijs toe.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (final document in documents)
                        DocumentTile.forDocument(
                          document,
                          key: ValueKey(document.id),
                          onTap: () =>
                              context.push(AppRoutes.document(document.id)),
                          trailing: IconButton(
                            tooltip: 'Soort wijzigen',
                            icon: const Icon(Icons.label_outline),
                            onPressed: () =>
                                _changeType(context, ref, document),
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('documents.add'),
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Document toevoegen'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
