import 'package:flutter/painting.dart';

/// Design tokens for the "arcade" look shared by the app-wide gate and
/// login (lib/app/gate, lib/app/auth) and the Flappy Bird game: a dark
/// festive purple with gold and saffron.
///
/// The values are exactly those the screens used before they moved here,
/// so the screens look the same. Prefer the general tokens in
/// app_tokens.dart where one fits; add arcade ones here, never inline.
abstract final class FlappyPalette {
  static const sky = Color(0xff26145f);
  static const midnight = Color(0xff120b38);
  static const dusk = Color(0xff55236f);
  static const grass = Color(0xff32144f);
  static const pipe = Color(0xff8e245d);
  static const pipeShadow = Color(0xff4d123b);
  static const gold = Color(0xffffc94a);
  static const festivalGold = Color(0xffffd166);
  static const saffron = Color(0xffff7a2f);
  static const ink = Color(0xff24113f);

  /// Background behind the gate, login and setup screens.
  static const night = Color(0xff1b0b2e);

  /// Countdown and notice panels.
  static const panel = Color(0xff140728);

  /// Countdown digit tiles, top to bottom.
  static const tileTop = Color(0xff38144e);
  static const tileBottom = Color(0xff220a35);

  /// A highlighted stat tile.
  static const selectedSurface = Color(0xff2e1c40);

  /// Saffron glow around avatars and panels.
  static const glow = Color(0x99ff9e32);
  static const glowSoft = Color(0x66ff9e32);

  /// Beads on the game's garland.
  static const bead = Color(0xffff8a3d);

  /// Fireworks in the backdrop.
  static const sparkPink = Color(0xffff6fb5);
  static const sparkCyan = Color(0xff65e7ff);

  /// Google sign-in button (Google's own colours).
  static const googleSurface = Color(0xffffffff);
  static const googleBorder = Color(0xffdadce0);
  static const googleBlue = Color(0xff4285f4);
  static const googleText = Color(0xff202124);

  /// Errors on the login screens.
  static const errorAccent = Color(0xffff5252);

  // Neutrals, as Material's Colors.* values.
  static const white = Color(0xffffffff);
  static const white70 = Color(0xb3ffffff);
  static const white38 = Color(0x61ffffff);
  static const white24 = Color(0x3dffffff);
  static const black = Color(0xff000000);
  static const black45 = Color(0x73000000);
  static const black26 = Color(0x42000000);
  static const grey = Color(0xff9e9e9e);
}

/// Opacities of the arcade screens.
abstract final class ArcadeOpacity {
  static const double hairline = 0.08;
  static const double splashHighlight = 0.1;
  static const double splash = 0.2;
  static const double shadow = 0.35;
  static const double half = 0.5;
  static const double scrimLight = 0.6;
  static const double scrim = 0.65;
  static const double error = 0.7;
  static const double stars = 0.78;
  static const double border = 0.8;
  static const double panelLight = 0.88;
  static const double garland = 0.9;
  static const double panel = 0.92;
  static const double card = 0.94;
  static const double selected = 0.95;
}

/// Font sizes of the arcade screens.
abstract final class ArcadeText {
  static const double tiny = 9;
  static const double unit = 10;
  static const double small = 11;
  static const double caption = 12;
  static const double error = 12.5;
  static const double body = 14;
  static const double button = 15.5;
  static const double googleButton = 18;
  static const double title = 22;
  static const double digit = 24;
  static const double medal = 30;
  static const double initial = 48;
}

/// Sizes of the arcade screens.
abstract final class ArcadeSizes {
  /// Longest side of a captured avatar photo, in pixels.
  static const double photoCaptureSide = 640;

  static const double loginMaxWidth = 360;
  static const double countdownMaxWidth = 380;
  static const double panelMaxWidth = 420;
  static const double avatarPanelMaxWidth = 460;

  /// Border widths.
  static const double hairline = 1;
  static const double goldBorder = 1.5;
  static const double ringThin = 3;
  static const double ring = 4;
  static const double ringThick = 5;

  /// Gaps.
  static const double tightGap = 2;
  static const double chipGap = 5;
  static const double buttonGap = 12;

  /// Icons.
  static const double smallIcon = 15;
  static const double statIcon = 22;
  static const double lifeIcon = 30;
  static const double cameraIcon = 64;

  static const double googleButtonHeight = 64;
  static const double googleButtonElevation = 2;
  static const double googleLogoSize = 24;
  static const double googleLogoGap = 14;
  static const double googleButtonPaddingHorizontal = 24;
  static const double googleButtonPaddingVertical = 16;
  static const double googleSpinnerStroke = 2.5;
  static const double spinnerStroke = 2;
  static const double panelElevation = 3;
  static const double compactButton = 36;

  static const double countdownTileWidth = 58;
  static const double countdownTileHeight = 48;
  static const double avatarPreview = 164;
  static const double podiumWidth = 126;
  static const double rankWidth = 34;

  /// Diyas along the backdrop's ground.
  static const double diyaWidth = 28;
  static const double diyaHeight = 12;
}

/// Radii of the arcade screens not covered by AppRadius.
abstract final class ArcadeRadius {
  static const BorderRadius panelAll = BorderRadius.all(Radius.circular(24));
  static const BorderRadius googleButtonAll = BorderRadius.all(Radius.circular(40));
}
