import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Names for the Deepavali tab's colours. Values live in `AppColors`
/// (docs/DESIGN_SYSTEM.md); this class only aliases them and builds gradients.
abstract final class DiwaliPalette {
  static const Color night = AppColors.diwaliNight;
  static const Color plum = AppColors.diwaliPlum;
  static const Color maroon = AppColors.diwaliMaroon;
  static const Color surface = AppColors.diwaliSurface;
  static const Color surfaceHigh = AppColors.diwaliSurfaceHigh;
  static const Color gold = AppColors.diwaliGold;
  static const Color goldDeep = AppColors.diwaliGoldDeep;
  static const Color saffron = AppColors.diwaliSaffron;
  static const Color orange = AppColors.diwaliOrange;
  static const Color flameCore = AppColors.diwaliFlameCore;
  static const Color cream = AppColors.diwaliCream;
  static const Color creamMuted = AppColors.diwaliCreamMuted;
  static const Color success = AppColors.diwaliSuccess;
  static const Color error = AppColors.diwaliError;

  /// Page background, top to bottom.
  static const LinearGradient page = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [night, plum, maroon],
    stops: [0, 0.55, 1],
  );

  /// Card fill.
  static const LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceHigh],
  );

  /// Primary button fill.
  static const LinearGradient cta = LinearGradient(colors: [gold, saffron]);

  /// Soft warm glow near the top of the page.
  static RadialGradient get glow => RadialGradient(
    center: const Alignment(0, -0.75),
    radius: 0.9,
    colors: [
      flameCore.withValues(alpha: AppOpacity.glow),
      flameCore.withValues(alpha: 0),
    ],
  );

  /// Gold hairline used on card borders.
  static Color get goldBorder => gold.withValues(alpha: AppOpacity.border);
}
