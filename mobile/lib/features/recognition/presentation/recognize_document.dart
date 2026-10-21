import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../documents/domain/document.dart';
import '../application/recognition_service.dart';
import '../domain/parsed_receipt.dart';

/// Stand van het herkennen, voor het voortgangsscherm.
@immutable
class RecognitionStatus {
  const RecognitionStatus({
    required this.step,
    required this.progress,
    required this.detail,
  });

  /// 0 = tekst herkennen, 1 = gegevens verwerken, 2 = velden invullen.
  final int step;

  /// 0.0 – 1.0.
  final double progress;

  /// Bijv. "Tekst herkennen… pagina 2 van 3".
  final String detail;

  static const start = RecognitionStatus(
    step: 0,
    progress: 0.1,
    detail: 'Tekst herkennen…',
  );
}

/// Herkent gegevens in [document] en toont intussen een voortgangsscherm.
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
  final status = ValueNotifier<RecognitionStatus>(RecognitionStatus.start);
  navigator.push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, _, _) => _RecognitionPage(status: status),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
  try {
    final result = await service.recognize(
      document,
      onProgress: (p) => status.value = RecognitionStatus(
        step: 0,
        progress: 0.1 + 0.6 * (p.page / (p.pageCount == 0 ? 1 : p.pageCount)),
        detail: p.message,
      ),
    );
    status.value = const RecognitionStatus(
      step: 2,
      progress: 1,
      detail: 'Velden invullen…',
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

class _RecognitionPage extends StatelessWidget {
  const _RecognitionPage({required this.status});

  final ValueListenable<RecognitionStatus> status;

  static const _steps = [
    'Tekst herkennen',
    'Gegevens verwerken',
    'Velden invullen',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Gegevens herkennen'),
        ),
        body: SafeArea(
          child: ValueListenableBuilder<RecognitionStatus>(
            valueListenable: status,
            builder: (context, s, _) => ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const SizedBox(height: AppSpacing.lg),
                const Center(
                  child: Icon(
                    Icons.document_scanner_outlined,
                    size: 80,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'We lezen je bon…',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Dit kan enkele seconden duren. Alles gebeurt op je '
                  'telefoon.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: s.progress,
                    minHeight: 8,
                    semanticsLabel: 'Voortgang herkennen',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${(s.progress * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                for (var i = 0; i < _steps.length; i++)
                  _StepRow(
                    label: _steps[i],
                    done: i < s.step || s.progress >= 1,
                    active: i == s.step && s.progress < 1,
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  s.detail,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done || active
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: active ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
