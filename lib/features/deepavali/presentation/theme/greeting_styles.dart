import 'package:flutter/material.dart';

import '../../domain/greeting.dart';
import 'diwali_palette.dart';
import 'rangoli_palette.dart';

/// Colours of one card design. Every design is dark with light text, so the
/// wording stays readable (checked by a contrast test).
class GreetingStyle {
  const GreetingStyle({
    required this.background,
    required this.title,
    required this.body,
    required this.accent,
  });

  /// Background gradient stops, top to bottom.
  final List<Color> background;
  final Color title;
  final Color body;
  final Color accent;
}

abstract final class GreetingStyles {
  static GreetingStyle of(GreetingDesign design) => switch (design) {
    GreetingDesign.goldenDiyas => const GreetingStyle(
      background: [
        DiwaliPalette.night,
        DiwaliPalette.plum,
        DiwaliPalette.maroon,
      ],
      title: DiwaliPalette.gold,
      body: DiwaliPalette.cream,
      accent: DiwaliPalette.saffron,
    ),
    GreetingDesign.rangoliBorder => const GreetingStyle(
      background: [DiwaliPalette.surfaceHigh, DiwaliPalette.night],
      title: RangoliPalette.marigoldColor,
      body: DiwaliPalette.cream,
      accent: DiwaliPalette.gold,
    ),
    GreetingDesign.nightLanterns => const GreetingStyle(
      background: [
        DiwaliPalette.night,
        DiwaliPalette.surface,
        DiwaliPalette.plum,
      ],
      title: DiwaliPalette.gold,
      body: DiwaliPalette.cream,
      accent: DiwaliPalette.saffron,
    ),
    GreetingDesign.marigoldGarland => const GreetingStyle(
      background: [DiwaliPalette.maroon, DiwaliPalette.plum],
      title: RangoliPalette.marigoldColor,
      body: DiwaliPalette.cream,
      accent: DiwaliPalette.saffron,
    ),
  };
}
