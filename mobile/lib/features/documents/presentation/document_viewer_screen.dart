import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/errors/user_message.dart';
import '../../../core/widgets/error_view.dart';
import '../application/document_service.dart';
import '../domain/document.dart';
import '../../../l10n/app_strings.dart';

/// Absoluut pad van een opgeslagen document.
final _documentPathProvider = FutureProvider.family<String, Document>((
  ref,
  document,
) {
  return ref.watch(documentServiceProvider).absolutePath(document);
});

/// Toont een opgeslagen PDF of afbeelding.
class DocumentViewerScreen extends ConsumerWidget {
  const DocumentViewerScreen({required this.documentId, super.key});

  final String documentId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) async {
    final container = ProviderScope.containerOf(context);
    final service = ref.read(documentServiceProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // Bij grote tekst kan het hele venster scrollen.
        scrollable: true,
        title: Text(S.current.deleteDocumentQuestion),
        content: Text(
          S.current.deleteDocumentBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.current.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.current.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.delete(document);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(userMessageFor(error))));
      return;
    }
    container
      ..invalidate(documentsForProductProvider(document.productId))
      ..invalidate(allDocumentsProvider)
      ..invalidate(documentByIdProvider(document.id));
    if (context.mounted) context.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(S.current.documentDeleted)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentByIdProvider(documentId));
    final document = documentAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(document?.type.label ?? S.current.document),
        actions: [
          if (document != null)
            IconButton(
              tooltip: S.current.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, document),
            ),
        ],
      ),
      body: documentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(error: error),
        data: (document) => document == null
            ? Center(child: Text(S.current.documentGone))
            : _DocumentContent(document: document),
      ),
    );
  }
}

class _DocumentContent extends ConsumerWidget {
  const _DocumentContent({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(_documentPathProvider(document));
    return path.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(error: error),
      data: (path) {
        if (!File(path).existsSync()) {
          return ErrorView(
            error: AppException(
              S.current.documentFileMissing,
            ),
          );
        }
        if (document.format == DocumentFormat.pdf) {
          return Semantics(
            label: S.current.pdfPinchHint,
            child: PdfViewer.file(path),
          );
        }
        return InteractiveViewer(
          maxScale: 6,
          child: Center(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              semanticLabel: S.current.receiptPhotoLabel,
              errorBuilder: (context, error, stackTrace) => ErrorView(
                error: AppException(S.current.imageCannotShow),
              ),
            ),
          ),
        );
      },
    );
  }
}
