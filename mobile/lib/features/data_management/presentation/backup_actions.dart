import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/user_message.dart';
import '../../documents/application/document_service.dart';
import '../../products/application/product_providers.dart';
import '../../reminders/application/reminder_service.dart';
import '../application/backup_status.dart';
import '../application/data_management_providers.dart';
import '../application/restore_service.dart';
import '../domain/backup_manifest.dart';
import '../../../l10n/app_strings.dart';

/// Maakt een export (reservekopie) en laat de gebruiker kiezen waar die
/// wordt bewaard. Gebruikt in Instellingen en op Home.
Future<void> runExport(BuildContext context, WidgetRef ref) async {
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
          key: const Key('export.confirm'),
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
      builder: (_) => BusyDialog(S.current.creatingExport),
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
    await ref.read(lastBackupProvider.notifier).markDone();
    message = S.current.exportSaved(export.productCount, export.documentCount);
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
  if (context.mounted) showMessage(context, message);
}

/// Laat de gebruiker een reservekopie kiezen, toont wat erin zit en zet
/// het na bevestiging terug. Geeft `true` als er iets is teruggezet.
Future<bool> runRestore(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  void say(String text) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  final navigator = Navigator.of(context);
  void closeBusy() {
    if (navigator.mounted && navigator.canPop()) {
      navigator.popUntil((route) => route is! DialogRoute);
    }
  }

  // 1. Bestand kiezen en controleren.
  final RestorePlan plan;
  try {
    final bytes = await ref.read(backupFilePickerProvider).pick();
    if (bytes == null || !context.mounted) return false;
    navigator.push<void>(
      DialogRoute<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BusyDialog(S.current.readingBackup),
      ),
    );
    plan = await ref.read(restoreServiceProvider).inspect(bytes);
    closeBusy();
  } catch (error) {
    debugPrint('Reservekopie lezen mislukt (${error.runtimeType})');
    closeBusy();
    say(_messageFor(error));
    return false;
  }

  if (plan.hasNothingNew) {
    say(S.current.restoreNothingNew);
    return false;
  }
  if (!context.mounted) return false;

  // 2. Laten zien wat er wordt teruggezet.
  var summary = S.current.restoreFound(plan.productCount, plan.documentCount);
  if (plan.skipped > 0) summary += S.current.restoreSkipped(plan.skipped);
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(S.current.restoreData),
      content: Text(summary),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(S.current.cancel),
        ),
        FilledButton(
          key: const Key('restore.confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(S.current.restore),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;

  // 3. Terugzetten.
  navigator.push<void>(
    DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BusyDialog(S.current.restoringData),
    ),
  );
  RestoreResult? result;
  try {
    result = await ref.read(restoreServiceProvider).restore(plan);
  } catch (error) {
    debugPrint('Terugzetten mislukt (${error.runtimeType})');
  }
  ref
    ..invalidate(productsProvider)
    ..invalidate(documentsForProductProvider)
    ..invalidate(allDocumentsProvider)
    ..invalidate(documentByIdProvider);
  await ref.read(reminderSyncProvider).syncSafely();
  closeBusy();
  if (result == null) {
    say(S.current.restoreFailed);
    return false;
  }
  say(S.current.restoreDone(result.products, result.documents));
  return true;
}

String _messageFor(Object error) {
  if (error is AppException) return error.userMessage;
  if (error is BackupFormatException) {
    return switch (error.problem) {
      BackupProblem.notABackup => S.current.restoreNotBackup,
      BackupProblem.oldExport => S.current.restoreOldExport,
      BackupProblem.newerVersion => S.current.restoreNewer,
      BackupProblem.damaged => S.current.restoreDamaged,
    };
  }
  return S.current.restoreDamaged;
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Venster met een draaiend rondje, terwijl er iets gebeurt.
class BusyDialog extends StatelessWidget {
  const BusyDialog(this.message, {super.key});

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
