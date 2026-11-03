/// The app's design system: every colour, spacing, size, radius, opacity,
/// duration and text-scale limit used by the UI is defined here, once.
///
/// Golden rule: screens never hard-code these values. They use a token from
/// this file, or a colour from `Theme.of(context).colorScheme`. To change the
/// look of the app, change it here. `test/design_system_test.dart` fails if a
/// hard-coded value appears outside `lib/core/theme/`.
library;

import 'package:flutter/widgets.dart';

/// Spacing scale (logical pixels) for padding, gaps and margins.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));

  /// Rounded bottom corners, for banners that run under the status bar.
  static const BorderRadius xlBottom = BorderRadius.vertical(
    bottom: Radius.circular(xl),
  );
}

/// Icon sizes.
abstract final class AppIconSizes {
  /// Inside chips.
  static const double xs = 18;

  /// Inline with body text.
  static const double sm = 20;

  /// Default Material icon size.
  static const double md = 24;

  /// List and tile icons.
  static const double lg = 40;

  /// Empty, error and permission states.
  static const double xl = 48;

  /// Placeholders such as a missing photo.
  static const double xxl = 56;

  /// Celebration icons, e.g. the quiz trophy.
  static const double hero = 72;
}

/// Component and layout sizes.
abstract final class AppSizes {
  /// Minimum interactive target (Material / WCAG; Apple's is 44).
  static const double minTouchTarget = 48;

  /// Widest a content column grows before being centred on large screens.
  static const double maxContentWidth = 720;

  /// Widest the floating bottom bar grows.
  static const double bottomBarMaxWidth = 420;

  /// Bottom padding for scrollable tab content, so the floating bottom bar
  /// never covers the last item.
  static const double floatingBarClearance = 96;

  /// Round icon badges on list cards, and the large one on detail pages.
  static const double badge = 48;
  static const double badgeLarge = 64;

  /// Minimum width of a leading label column (years, numerals).
  static const double leadingLabel = 56;

  /// Grid tiles: widest a tile grows, and its base height at 1x text.
  static const double gridTileMaxWidth = 88;
  static const double gridTileBaseHeight = 60;

  /// Hanging festive decoration (toran, garland) across the top of a banner.
  static const double toran = 44;

  /// Flags drawn in the UI (3:2). Small is for inline use.
  static const double flagSmall = 40;
  static const double flag = 56;

  /// Progress bars.
  static const double progressBar = 8;

  /// Width of image decodes for photo tiles (keeps memory low).
  static const int photoDecodeWidth = 400;
}

/// Brand and festival colours. Screens use `colorScheme` roles; these are
/// only for seeding themes and for content whose colour is fixed, such as a
/// flag.
abstract final class AppColors {
  /// Seed of the app-wide Material theme.
  static const Color seed = Color(0xFFE65100);

  /// Kannada flag.
  static const Color kannadaYellow = Color(0xFFFFD21F);
  static const Color kannadaRed = Color(0xFFE3241B);

  /// Rajyotsava banner gradient, top to bottom. [onBanner] and
  /// [kannadaYellow] text on it has a contrast ratio above 7:1.
  static const Color bannerTop = Color(0xFF9E1B1B);
  static const Color bannerBottom = Color(0xFF5E0B12);
  static const Color onBanner = Color(0xFFFFFFFF);

  /// Fully transparent (system bars).
  static const Color transparent = Color(0x00000000);

  /// Deepavali tab palette (always dark). Contrast ratios (WCAG):
  /// [diwaliCream] on [diwaliNight]/[diwaliSurface]/[diwaliSurfaceHigh] > 7:1;
  /// [diwaliCreamMuted] on [diwaliSurface] > 4.5:1; [diwaliGold] on
  /// [diwaliNight] > 4.5:1; [diwaliNight] on [diwaliGold]/[diwaliSaffron] >
  /// 7:1. Checked by test/features/deepavali/foundation_test.dart.
  static const Color diwaliNight = Color(0xFF14081F);
  static const Color diwaliPlum = Color(0xFF2A1240);
  static const Color diwaliMaroon = Color(0xFF4A1424);
  static const Color diwaliSurface = Color(0xFF231238);
  static const Color diwaliSurfaceHigh = Color(0xFF2F1A4A);
  static const Color diwaliGold = Color(0xFFF5B83D);
  static const Color diwaliGoldDeep = Color(0xFFC98A12);
  static const Color diwaliSaffron = Color(0xFFFF9933);
  static const Color diwaliOrange = Color(0xFFF26A1B);
  static const Color diwaliFlameCore = Color(0xFFFFD36B);
  static const Color diwaliCream = Color(0xFFFFF4DC);
  static const Color diwaliCreamMuted = Color(0xFFD9C7A8);
  static const Color diwaliSuccess = Color(0xFF7BD88F);
  static const Color diwaliError = Color(0xFFFF8A80);

  // Deepavali rangoli palette: eight festival powders, brightest first.
  static const Color rangoliMarigold = Color(0xFFF5B83D);
  static const Color rangoliSaffron = Color(0xFFFF7A1A);
  static const Color rangoliVermilion = Color(0xFFE53935);
  static const Color rangoliMagenta = Color(0xFFD81B8C);
  static const Color rangoliViolet = Color(0xFF7E57C2);
  static const Color rangoliTeal = Color(0xFF1FB5A6);
  static const Color rangoliLeaf = Color(0xFF5CBF5A);
  static const Color rangoliCream = Color(0xFFFFF4DC);
}

/// Opacity levels for decoration and secondary text.
abstract final class AppOpacity {
  /// Faint background decoration.
  static const double faint = 0.16;

  /// Subtle decoration such as dots and patterns.
  static const double subtle = 0.22;

  /// Secondary text on a coloured background.
  static const double secondaryText = 0.85;

  /// Pressed-state tint on cards and buttons.
  static const double pressed = 0.08;

  /// Hairline borders on dark festive surfaces.
  static const double border = 0.3;

  /// Soft glow around lamps and page highlights.
  static const double glow = 0.35;

  /// Disabled controls.
  static const double disabled = 0.4;

  /// Decorative lines that fade out at their ends.
  static const double strong = 0.7;
}

/// Animation durations.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);

  /// Scrolling between sections.
  static const Duration slow = Duration(milliseconds: 700);

  /// A card or section fading and sliding into place.
  static const Duration entrance = Duration(milliseconds: 450);

  /// Delay between items that enter one after another.
  static const Duration stagger = Duration(milliseconds: 70);

  /// A number counting up to its value.
  static const Duration countUp = Duration(milliseconds: 1200);

  /// A one-off celebration when a screen opens (waving flag…). Keep
  /// decorative motion finite so it never distracts or drains the battery.
  static const Duration celebration = Duration(seconds: 4);

  /// Gentle ambient motion (a swaying toran, drifting petals) each time a
  /// screen appears; it then rests, so it never runs for long.
  static const Duration ambient = Duration(seconds: 8);

  /// One cycle of a looping indicator, e.g. "now playing" bars.
  static const Duration loop = Duration(milliseconds: 900);
}

/// Limits on the system text size. The app honours accessibility text sizes
/// up to [max] (Apple asks for at least 200%), and every screen is tested at
/// [max] on a 320-point-wide phone, so text never runs off the screen.
abstract final class AppTextScale {
  static const double min = 1;
  static const double max = 2;
}

/// Screen sizes every screen is tested at.
abstract final class AppTestScreens {
  /// Smallest supported phone width (iPhone SE 1st gen, small Androids).
  static const Size smallestPhone = Size(320, 568);
}
