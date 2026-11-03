import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../rajyotsava_routes.dart';
import 'rajyotsava_widgets.dart';

/// A bundled photo, decoded at display size. Falls back to an icon badge
/// when there is no photo ([asset] is null) or it fails to load.
class RajyotsavaPhoto extends StatelessWidget {
  const RajyotsavaPhoto({
    required this.asset,
    required this.fallbackIcon,
    this.size = AppSizes.badgeLarge,
    this.circle = false,
    this.semanticLabel,
    super.key,
  });

  final String? asset;
  final IconData fallbackIcon;

  /// Width and height of the square thumbnail.
  final double size;

  /// Round (people) instead of rounded square (places, food).
  final bool circle;

  /// Describes the photo; null marks it decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fallback = IconBadge(icon: fallbackIcon, size: size);
    final path = asset;
    if (path == null) return fallback;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final image = Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: pixels,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      errorBuilder: (_, _, _) => fallback,
    );
    return circle
        ? ClipOval(child: image)
        : ClipRRect(borderRadius: AppRadius.mdAll, child: image);
  }
}

/// A wide photo for the top of a detail page, 16:9.
class RajyotsavaHeroPhoto extends StatelessWidget {
  const RajyotsavaHeroPhoto({
    required this.asset,
    required this.semanticLabel,
    super.key,
  });

  final String asset;
  final String semanticLabel;

  static const double _aspectRatio = 16 / 9;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final pixels =
          (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
              .round();
      return ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            cacheWidth: pixels,
            semanticLabel: semanticLabel,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      );
    },
  );
}

/// App bar button that opens the Photo credits screen.
class PhotoCreditsButton extends StatelessWidget {
  const PhotoCreditsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Photo credits',
    icon: const Icon(Icons.copyright_outlined),
    onPressed: () => context.push(RajyotsavaRoutes.photoCredits),
  );
}
