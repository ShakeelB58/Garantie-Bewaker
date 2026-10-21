import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/user_message.dart';
import '../application/document_service.dart';
import '../data/document_file_store.dart';
import '../data/document_picker.dart';
import '../domain/document.dart';
import 'photo_review_screen.dart';

extension DocumentSourceLabel on DocumentSource {
  String get label => switch (this) {
    DocumentSource.camera => 'Foto maken',
    DocumentSource.gallery => 'Kiezen uit foto\'s',
    DocumentSource.files => 'Kiezen uit bestanden (PDF of afbeelding)',
  };

  IconData get icon => switch (this) {
    DocumentSource.camera => Icons.photo_camera_outlined,
    DocumentSource.gallery => Icons.photo_library_outlined,
    DocumentSource.files => Icons.folder_open_outlined,
  };
}

/// Laat de gebruiker een bron kiezen. `null` bij annuleren.
Future<DocumentSource?> showDocumentSourceSheet(
  BuildContext context, {
  List<DocumentSource> sources = DocumentSource.values,
}) {
  return showModalBottomSheet<DocumentSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final source in sources)
              ListTile(
                leading: Icon(source.icon),
                title: Text(source.label),
                onTap: () => Navigator.of(context).pop(source),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Volledige stroom: kiezen of fotograferen → (bij de camera) foto
/// controleren of opnieuw maken → controleren en veilig opslaan.
///
/// Geeft `null` terug als de gebruiker annuleert of als er een fout is.
/// Fouten worden als melding getoond.
Future<StagedDocument?> acquireDocument(
  BuildContext context,
  WidgetRef ref,
  DocumentSource source, {
  DocumentType? type,
}) async {
  // Alles vooraf ophalen: na een `await` kan het scherm al gesloten zijn.
  final picker = ref.read(documentPickerProvider);
  final service = ref.read(documentServiceProvider);
  final fileStore = ref.read(documentFileStoreProvider);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  void showError(Object error) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(userMessageFor(error))));
  }

  final PickedFile? chosen;
  try {
    chosen = await _pickWithReview(picker, fileStore, navigator, source);
  } catch (error) {
    showError(error);
    return null;
  }
  if (chosen == null) return null;
  if (!navigator.mounted) {
    await fileStore.deleteIfTemporary(chosen.path);
    return null;
  }

  // Voortgang tonen tijdens controleren en kopiëren.
  navigator.push<void>(
    DialogRoute<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => const _ProgressDialog(message: 'Document opslaan…'),
    ),
  );
  try {
    return await service.stage(chosen, type: type);
  } catch (error) {
    showError(error);
    return null;
  } finally {
    if (navigator.mounted) navigator.pop();
  }
}

/// Kiest een bestand; bij de camera mag de gebruiker de foto eerst
/// controleren en opnieuw maken. `null` bij annuleren.
Future<PickedFile?> _pickWithReview(
  DocumentPicker picker,
  DocumentFileStore fileStore,
  NavigatorState navigator,
  DocumentSource source,
) async {
  while (true) {
    final picked = await picker.pick(source);
    if (picked == null || source != DocumentSource.camera) return picked;

    final decision = await navigator.push<PhotoReviewDecision>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoReviewScreen(imagePath: picked.path),
      ),
    );
    if (decision == PhotoReviewDecision.use) return picked;

    // Opnieuw of geannuleerd: de afgekeurde foto meteen weggooien.
    await fileStore.deleteIfTemporary(picked.path);
    if (decision != PhotoReviewDecision.retake) return null;
  }
}

class _ProgressDialog extends StatelessWidget {
  const _ProgressDialog({required this.message});

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
