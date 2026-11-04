import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'diwali_palette.dart';

/// Feature-local theme for the Deepavali tab. Nothing in `core` changes.
abstract final class DiwaliTheme {
  /// Poppins is bundled under `assets/google_fonts/` (weights 400-700 only),
  /// so the tab never needs the network for text.
  static ThemeData get data {
    GoogleFonts.config.allowRuntimeFetching = false;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: DiwaliPalette.gold,
          brightness: Brightness.dark,
        ).copyWith(
          primary: DiwaliPalette.gold,
          onPrimary: DiwaliPalette.night,
          secondary: DiwaliPalette.saffron,
          onSecondary: DiwaliPalette.night,
          surface: DiwaliPalette.surface,
          onSurface: DiwaliPalette.cream,
          onSurfaceVariant: DiwaliPalette.creamMuted,
          outline: DiwaliPalette.goldDeep,
          outlineVariant: DiwaliPalette.goldBorder,
          error: DiwaliPalette.error,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: DiwaliPalette.night,
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: DiwaliPalette.cream,
        displayColor: DiwaliPalette.cream,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: DiwaliPalette.surfaceHigh,
        modalBackgroundColor: DiwaliPalette.surfaceHigh,
        showDragHandle: true,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: DiwaliPalette.surfaceHigh,
      ),
    );
  }
}
