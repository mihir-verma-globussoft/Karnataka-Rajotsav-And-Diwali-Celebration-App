import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_tokens.dart';

/// Feature-local theme: the festive night look of the Deepavali tab. Always
/// dark, because most of the hunt happens over a live camera image.
abstract final class ArTheme {
  static final ThemeData data = _build();

  static ThemeData _build() {
    // Poppins is bundled under `assets/google_fonts/`.
    GoogleFonts.config.allowRuntimeFetching = false;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.diwaliGold,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.diwaliGold,
          onPrimary: AppColors.diwaliNight,
          secondary: AppColors.diwaliSaffron,
          onSecondary: AppColors.diwaliNight,
          surface: AppColors.diwaliSurface,
          onSurface: AppColors.diwaliCream,
          onSurfaceVariant: AppColors.diwaliCreamMuted,
          outline: AppColors.diwaliGoldDeep,
          error: AppColors.diwaliError,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.diwaliNight,
    );
    const minSize = Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget);
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.diwaliCream,
        displayColor: AppColors.diwaliCream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.transparent,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: minSize),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: minSize),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minSize),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppRadius.smAll),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.diwaliSurfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
