import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/content/destinations.dart';
import '../theme/diwali_palette.dart';

/// A destination photo with a themed placeholder while decoding and when the
/// asset is missing or broken. [decodeWidth] keeps memory low in lists.
class DestinationImage extends StatelessWidget {
  const DestinationImage({
    required this.destination,
    this.decodeWidth,
    this.fit = BoxFit.cover,
    super.key,
  });

  final Destination destination;
  final int? decodeWidth;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(
    destination.photo.asset,
    fit: fit,
    cacheWidth: decodeWidth,
    semanticLabel: destination.photo.altText,
    frameBuilder: (context, child, frame, sync) => sync || frame != null
        ? child
        : _Placeholder(name: destination.name, loading: true),
    errorBuilder: (context, error, stack) =>
        _Placeholder(name: destination.name, loading: false),
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.name, required this.loading});

  final String name;
  final bool loading;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: DiwaliPalette.card),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            loading ? Icons.hourglass_empty : Icons.image_not_supported,
            color: DiwaliPalette.saffron,
            size: AppIconSizes.xl,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: DiwaliPalette.cream),
          ),
        ],
      ),
    ),
  );
}
