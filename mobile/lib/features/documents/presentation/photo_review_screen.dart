import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

enum PhotoReviewDecision { use, retake }

/// Toont een zojuist gemaakte foto, zodat de gebruiker kan kiezen:
/// gebruiken of opnieuw maken. Terug = annuleren.
class PhotoReviewScreen extends StatelessWidget {
  const PhotoReviewScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Foto controleren'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  semanticLabel:
                      'Gemaakte foto. Controleer of de tekst leesbaar is.',
                  errorBuilder: (context, error, stackTrace) => const Text(
                    'Voorbeeld niet beschikbaar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Is de bon goed leesbaar en staat hij er helemaal op?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(PhotoReviewDecision.retake),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Opnieuw'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(PhotoReviewDecision.use),
                          icon: const Icon(Icons.check),
                          label: const Text('Gebruiken'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
