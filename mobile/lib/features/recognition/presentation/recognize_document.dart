import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../documents/domain/document.dart';
import '../application/recognition_service.dart';
import '../domain/parsed_receipt.dart';

/// Herkent gegevens in [document] en toont intussen de voortgang.
///
/// Geeft `null` terug als het niet lukt; er verschijnt dan een melding en
/// de gebruiker vult de gegevens zelf in. Herkennen blokkeert nooit het
/// toevoegen van een aankoop.
Future<ParsedReceipt?> recognizeWithProgress({
  required NavigatorState navigator,
  required ScaffoldMessengerState? messenger,
  required RecognitionService service,
  required StagedDocument document,
}) async {
  final status = ValueNotifier<String>('Tekst herkennen…');
  navigator.push<void>(
    DialogRoute<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => _RecognitionDialog(status: status),
    ),
  );
  try {
    final result = await service.recognize(
      document,
      onProgress: (progress) => status.value = progress.message,
    );
    if (!result.hasAnything) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Er zijn geen gegevens herkend. Vul ze zelf in.'),
        ),
      );
    }
    return result;
  } catch (error) {
    debugPrint('Herkennen mislukt (${error.runtimeType})');
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Automatisch herkennen lukte niet. Vul de gegevens zelf in.',
        ),
      ),
    );
    return null;
  } finally {
    if (navigator.mounted) navigator.pop();
    status.dispose();
  }
}

class _RecognitionDialog extends StatelessWidget {
  const _RecognitionDialog({required this.status});

  final ValueListenable<String> status;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: status,
                builder: (context, message, _) => Text(message),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
