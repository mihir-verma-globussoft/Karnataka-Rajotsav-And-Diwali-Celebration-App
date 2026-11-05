import 'package:flutter/painting.dart';

/// Design tokens for the "arcade" look shared by the app-wide gate and
/// login (lib/app/gate, lib/app/auth) and the Flappy Bird game: a dark
/// festive purple with gold and saffron.
///
/// The values are exactly those the screens used before they moved here,
/// so the screens look the same. Prefer the general tokens in
/// app_tokens.dart where one fits; add arcade ones here, never inline.
abstract final class FlappyPalette {
  /// Fully transparent, for Material/Ink layers that only draw ripples.
  static const Color clear = Color(0x00000000);

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
  static const bronze = Color(0xffd9944a);

  /// Google sign-in button (Google's own colours).
  static const googleSurface = Color(0xffffffff);
  static const googleWarmSurface = Color(0xffffe5a0);
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

  /// Gap between the letters of a small uppercase section label.
  static const double labelSpacing = 1.5;
  static const double small = 11;
  static const double caption = 12;
  static const double error = 12.5;
  static const double body = 14;
  static const double button = 15.5;
  static const double googleButton = 15;
  static const double title = 22;
  static const double digit = 24;
  static const double medal = 30;
  static const double podiumMedal = 36;
  static const double podiumScore = 20;
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
  static const double lifeIcon = 34;
  static const double hudIcon = 32;
  static const double cameraIcon = 64;
  static const double obstacleOutline = 2;
  static const double obstacleShadow = 4;
  static const double obstacleBandHeight = 4;
  static const double obstacleBandGap = 38;
  static const double obstacleBandStart = 18;
  static const double obstacleBeadRadius = 3;
  static const double obstacleBeadGap = 14;
  static const double obstacleBeadInset = 7;
  static const double birdMinSize = 40;
  static const double birdMaxSize = 52;
  static const double scoreGlow = 8;

  static const double googleButtonHeight = 40;
  static const double googleButtonMaxWidth = 300;
  static const double googleButtonShadow = 8;
  static const double googleButtonShadowDrop = 3;
  static const double googleLogoSize = 44;
  static const double googleLogoGap = 0;
  static const double googleButtonPaddingHorizontal = 4;
  static const double googleButtonPaddingVertical = 0;
  static const double googleSpinnerSize = 22;
  static const double googleSpinnerStroke = 2.5;
  static const double spinnerStroke = 2;
  static const double panelElevation = 3;
  static const double compactButton = 36;

  static const double countdownTileWidth = 58;
  static const double countdownTileHeight = 48;
  static const double avatarPreview = 164;
  static const double podiumWidth = 126;
  static const double podiumCardMinHeight = 150;
  static const double podiumChampionMinHeight = 184;
  static const double podiumAvatarRadius = 28;
  static const double podiumChampionAvatarRadius = 38;
  static const double rowAvatarRadius = 24;
  static const double rankWidth = 44;
  static const double gameIconBox = 44;
  static const double calloutIcon = 32;

  /// Diyas along the backdrop's ground.
  static const double diyaWidth = 28;
  static const double diyaHeight = 12;
}

/// Radii of the arcade screens not covered by AppRadius.
abstract final class ArcadeRadius {
  static const BorderRadius panelAll = BorderRadius.all(Radius.circular(24));
  static const BorderRadius googleButtonAll = BorderRadius.all(
    Radius.circular(12),
  );
}

/// Lengths on the poster artwork grid (848 design pixels wide). The avatar
/// setup and Flappy Bird dashboard screens are laid over full-bleed artwork;
/// every length is multiplied by the screen's scale, so `p358` means 358
/// pixels of the artwork, not of the screen.
abstract final class PosterPx {
  static const double p8 = 8;
  static const double p12 = 12;
  static const double p18 = 18;
  static const double p23 = 23;
  static const double p24 = 24;
  static const double p25 = 25;
  static const double p28 = 28;
  static const double p30 = 30;
  static const double p31 = 31;
  static const double p34 = 34;
  static const double p38 = 38;
  static const double p42 = 42;
  static const double p44 = 44;
  static const double p46 = 46;
  static const double p48 = 48;
  static const double p54 = 54;
  static const double p56 = 56;
  static const double p58 = 58;
  static const double p60 = 60;
  static const double p62 = 62;
  static const double p64 = 64;
  static const double p70 = 70;
  static const double p72 = 72;
  static const double p84 = 84;
  static const double p105 = 105;
  static const double p119 = 119;
  static const double p124 = 124;
  static const double p157 = 157;
  static const double p225 = 225;
  static const double p248 = 248;
  static const double p358 = 358;
  static const double p371 = 371;
  static const double p520 = 520;
  static const double p648 = 648;
  static const double p656 = 656;
  static const double p762 = 762;
}
