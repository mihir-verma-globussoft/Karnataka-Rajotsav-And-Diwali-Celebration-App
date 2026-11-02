import 'package:flutter/widgets.dart';

/// Spacing scale (logical pixels). Use these instead of literals.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radii.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}

/// Sizing constants.
abstract final class AppSizes {
  /// Minimum interactive target (Material / WCAG guidance).
  static const double minTouchTarget = 48;

  /// Widest a content column grows before being centred on large screens.
  static const double maxContentWidth = 720;
}
