import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// One rangoli colour with the name screen readers speak.
class RangoliColour {
  const RangoliColour(this.name, this.color);
  final String name;
  final Color color;
}

/// The eight rangoli colours, in palette-index order.
abstract final class RangoliPalette {
  /// Marigold, also used by greeting cards.
  static const Color marigoldColor = AppColors.rangoliMarigold;

  static const List<RangoliColour> colours = [
    RangoliColour('Marigold', AppColors.rangoliMarigold),
    RangoliColour('Saffron', AppColors.rangoliSaffron),
    RangoliColour('Vermilion', AppColors.rangoliVermilion),
    RangoliColour('Magenta', AppColors.rangoliMagenta),
    RangoliColour('Violet', AppColors.rangoliViolet),
    RangoliColour('Teal', AppColors.rangoliTeal),
    RangoliColour('Leaf green', AppColors.rangoliLeaf),
    RangoliColour('Cream', AppColors.rangoliCream),
  ];
}
