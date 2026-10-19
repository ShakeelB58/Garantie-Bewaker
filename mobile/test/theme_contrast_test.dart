import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/app/theme/app_colors.dart';
import 'package:garantiebewaker/app/theme/app_theme.dart';

/// WCAG 2.x contrastverhouding tussen twee kleuren.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const minimumNormalText = 4.5;

  group('kleurcontrast (WCAG AA, gewone tekst)', () {
    test('primaire tekst op achtergrond en kaarten', () {
      expect(
        contrastRatio(AppColors.navy, AppColors.background),
        greaterThanOrEqualTo(minimumNormalText),
      );
      expect(
        contrastRatio(AppColors.navy, AppColors.surface),
        greaterThanOrEqualTo(minimumNormalText),
      );
    });

    test('secundaire tekst op achtergrond en kaarten', () {
      expect(
        contrastRatio(AppColors.textMuted, AppColors.background),
        greaterThanOrEqualTo(minimumNormalText),
      );
      expect(
        contrastRatio(AppColors.textMuted, AppColors.surface),
        greaterThanOrEqualTo(minimumNormalText),
      );
    });

    test('witte tekst op accentkleur (knoppen)', () {
      expect(
        contrastRatio(Colors.white, AppColors.teal),
        greaterThanOrEqualTo(minimumNormalText),
      );
    });

    test('waarschuwingskleur op wit (onzeker herkende velden)', () {
      expect(
        contrastRatio(AppColors.warning, AppColors.surface),
        greaterThanOrEqualTo(minimumNormalText),
      );
    });

    test('tekst op lichte accentachtergrond', () {
      expect(
        contrastRatio(AppColors.navy, AppColors.tealContainer),
        greaterThanOrEqualTo(minimumNormalText),
      );
    });
  });

  test('thema gebruikt de kleuren van het design system', () {
    final theme = AppTheme.light();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.teal);
    expect(theme.colorScheme.onSurface, AppColors.navy);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });
}
