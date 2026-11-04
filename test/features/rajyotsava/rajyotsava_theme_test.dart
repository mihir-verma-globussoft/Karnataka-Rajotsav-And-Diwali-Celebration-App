import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/widgets/rajyotsava_widgets.dart';

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('text colours of the section theme are readable on their '
      'backgrounds (4.5:1, small text)', () {
    final s = RajyotsavaTheme.data.colorScheme;
    final pairs = {
      'primary': (s.primary, s.onPrimary),
      // The flag-yellow cards: daily fact, vowel tiles, nearest district.
      'tertiaryContainer': (s.tertiaryContainer, s.onTertiaryContainer),
      'tertiary': (s.tertiary, s.onTertiary),
      'surface': (s.surface, s.onSurface),
    };
    for (final MapEntry(key: name, value: (background, text))
        in pairs.entries) {
      expect(
        _contrast(text, background),
        greaterThanOrEqualTo(4.5),
        reason: 'on$name on $name',
      );
    }
  });
}
