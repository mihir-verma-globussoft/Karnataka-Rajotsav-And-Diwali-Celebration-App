import 'package:flutter/material.dart';

import '../theme/diwali_palette.dart';

/// Page background: deep gradient with a soft warm glow near the top.
/// Static, so it is painted once inside its own repaint boundary.
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ExcludeSemantics(
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: DiwaliPalette.page),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: DiwaliPalette.glow),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}
