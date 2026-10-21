import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../products/application/product_providers.dart';
import '../application/document_service.dart';
import '../domain/document.dart';
import 'document_widgets.dart';

/// Alle aankoopbewijzen van alle producten in één lijst.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  DocumentType? _type;

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(allDocumentsProvider);
    final products = ref.watch(productsProvider).value ?? const [];
    final names = {for (final p in products) p.id: p.name};

    return Scaffold(
      appBar: AppBar(title: const Text('Documenten')),
      body: documents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(allDocumentsProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.description_outlined,
              title: 'Nog geen documenten',
              message:
                  'Kassabonnen, facturen en garantiebewijzen die je bij een '
                  'product bewaart, verschijnen hier.',
            );
          }
          final usedTypes = DocumentType.values
              .where((t) => all.any((d) => d.type == t))
              .toList();
          final visible = _type == null
              ? all
              : all.where((d) => d.type == _type).toList();
          return Column(
            children: [
              if (usedTypes.length > 1)
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: const Text('Alle'),
                          selected: _type == null,
                          onSelected: (_) => setState(() => _type = null),
                        ),
                      ),
                      for (final type in usedTypes)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(type.label),
                            selected: _type == type,
                            onSelected: (selected) =>
                                setState(() => _type = selected ? type : null),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final document = visible[index];
                    final product = names[document.productId] ?? 'Product';
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: DocumentTile(
                        key: ValueKey(document.id),
                        title: product,
                        subtitle:
                            '${document.type.label} · '
                            '${Dates.formatShort(document.createdAt.toLocal())}'
                            ' · ${document.format.extension}',
                        format: document.format,
                        onTap: () =>
                            context.push(AppRoutes.document(document.id)),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
