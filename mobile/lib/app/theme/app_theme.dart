import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Vaste afstanden, zodat schermen een consistent ritme hebben.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

/// Vaste hoekafrondingen.
abstract final class AppRadius {
  static const card = 16.0;
  static const button = 12.0;
}

/// Design system van Bonvrij op basis van Material 3.
abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.teal,
          onPrimary: Colors.white,
          primaryContainer: AppColors.tealContainer,
          onPrimaryContainer: AppColors.navy,
          secondary: AppColors.navy,
          onSecondary: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.navy,
          onSurfaceVariant: AppColors.textMuted,
          outline: AppColors.textMuted,
          outlineVariant: AppColors.border,
          error: AppColors.error,
          onError: Colors.white,
        );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
    );

    final textTheme = base.textTheme
        .apply(bodyColor: AppColors.navy, displayColor: AppColors.navy)
        .copyWith(
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        );

    return base.copyWith(
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.tealContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: AppColors.navy,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    );
  }
}
