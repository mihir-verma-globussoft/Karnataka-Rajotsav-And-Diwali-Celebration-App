/// Colours, opacities, sizes and durations for the Pac-Man game's Diwali look.
/// Lives in `lib/core/theme/` like every other token (docs/DESIGN_SYSTEM.md);
/// the game's widgets and painters refer to these names instead of literals.
library;

import 'package:flutter/material.dart';

/// Palette of the sky, maze, characters and effects. The hex name is the
/// colour (AARRGGBB), so a painter line reads the same as the value it draws.
abstract final class PacmanColors {
  static const Color black87 = Colors.black87;
  static const Color blueDeep = Color(0xFF0D47A1);
  static const Color deepOrange = Colors.deepOrange;
  static const Color deepOrangeAccent = Colors.deepOrangeAccent;
  static const Color orange = Colors.orange;
  static const Color orangeAccent = Colors.orangeAccent;
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color yellow = Colors.yellow;

  static const Color c33FFC107 = Color(0x33FFC107);
  static const Color c40000000 = Color(0x40000000);
  static const Color c88FFFFFF = Color(0x88FFFFFF);
  static const Color c99200040 = Color(0x99200040);
  static const Color c994CAF50 = Color(0x994CAF50);
  static const Color c99FFD54F = Color(0x99FFD54F);
  static const Color cAA12002B = Color(0xAA12002B);
  static const Color cAAFFF176 = Color(0xAAFFF176);
  static const Color cCC4A1070 = Color(0xCC4A1070);
  static const Color cFF0B0020 = Color(0xFF0B0020);
  static const Color cFF0D47A1 = Color(0xFF0D47A1);
  static const Color cFF12002B = Color(0xFF12002B);
  static const Color cFF1565C0 = Color(0xFF1565C0);
  static const Color cFF1B5E20 = Color(0xFF1B5E20);
  static const Color cFF212121 = Color(0xFF212121);
  static const Color cFF2A0845 = Color(0xFF2A0845);
  static const Color cFF2E7D32 = Color(0xFF2E7D32);
  static const Color cFF37474F = Color(0xFF37474F);
  static const Color cFF3E0A0A = Color(0xFF3E0A0A);
  static const Color cFF3E2723 = Color(0xFF3E2723);
  static const Color cFF40C4FF = Color(0xFF40C4FF);
  static const Color cFF4527A0 = Color(0xFF4527A0);
  static const Color cFF4A1050 = Color(0xFF4A1050);
  static const Color cFF4A148C = Color(0xFF4A148C);
  static const Color cFF4CAF50 = Color(0xFF4CAF50);
  static const Color cFF4E342E = Color(0xFF4E342E);
  static const Color cFF5D4037 = Color(0xFF5D4037);
  static const Color cFF66BB6A = Color(0xFF66BB6A);
  static const Color cFF69F0AE = Color(0xFF69F0AE);
  static const Color cFF6A1B9A = Color(0xFF6A1B9A);
  static const Color cFF6D4C41 = Color(0xFF6D4C41);
  static const Color cFF7E57C2 = Color(0xFF7E57C2);
  static const Color cFF8D6E63 = Color(0xFF8D6E63);
  static const Color cFF8E1B3A = Color(0xFF8E1B3A);
  static const Color cFF90A4AE = Color(0xFF90A4AE);
  static const Color cFFB39DDB = Color(0xFFB39DDB);
  static const Color cFFB3E5FC = Color(0xFFB3E5FC);
  static const Color cFFBF360C = Color(0xFFBF360C);
  static const Color cFFD1C4E9 = Color(0xFFD1C4E9);
  static const Color cFFD2691E = Color(0xFFD2691E);
  static const Color cFFD84315 = Color(0xFFD84315);
  static const Color cFFE53935 = Color(0xFFE53935);
  static const Color cFFECEFF1 = Color(0xFFECEFF1);
  static const Color cFFEF6C00 = Color(0xFFEF6C00);
  static const Color cFFF9A825 = Color(0xFFF9A825);
  static const Color cFFFF4081 = Color(0xFFFF4081);
  static const Color cFFFF7043 = Color(0xFFFF7043);
  static const Color cFFFF80AB = Color(0xFFFF80AB);
  static const Color cFFFF8F00 = Color(0xFFFF8F00);
  static const Color cFFFF9800 = Color(0xFFFF9800);
  static const Color cFFFFA000 = Color(0xFFFFA000);
  static const Color cFFFFC107 = Color(0xFFFFC107);
  static const Color cFFFFCC80 = Color(0xFFFFCC80);
  static const Color cFFFFD54F = Color(0xFFFFD54F);
  static const Color cFFFFEB3B = Color(0xFFFFEB3B);
  static const Color cFFFFF59D = Color(0xFFFFF59D);
}

/// Opacities used by the game's cartoons and chips.
abstract final class PacmanOpacity {
  /// Faded copies trailing behind Thunder Man's dash.
  static const double afterimage = 0.18;

  /// Tinted fill behind a character's power chip.
  static const double chipFill = 0.3;
}

/// Sizes specific to the Pac-Man screens.
abstract final class PacmanSizes {
  /// Square stage for a character on the pick-a-chaser cards.
  static const double cardStage = 120;

  /// Square stage for a character in the 4-second popup.
  static const double popupStage = 220;

  /// Selfie width sent to the game (keeps the photo small in memory).
  static const double selfieMaxWidth = 512;
}

/// Animation timing for the Pac-Man screens.
abstract final class PacmanDurations {
  /// One loop of a character's performance on the intro screen.
  static const Duration performCycle = Duration(milliseconds: 1600);

  /// Longest wait for one play of the game-over clip before moving on.
  static const Duration soundTimeout = Duration(seconds: 8);
}
