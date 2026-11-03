import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../deepavali_routes.dart';
import '../../domain/content/destinations.dart';
import '../theme/diwali_palette.dart';
import '../widgets/destination_image.dart';
import '../widgets/diwali_button.dart';
import '../widgets/photo_credits_sheet.dart';
import '../widgets/section_header.dart';

/// Deepavali Around India: a horizontally swipeable gallery of six cities.
class DestinationsSection extends StatefulWidget {
  const DestinationsSection({super.key});

  @override
  State<DestinationsSection> createState() => _DestinationsSectionState();
}

class _DestinationsSectionState extends State<DestinationsSection> {
  static const double _compactFraction = 0.78;
  static const double _mediumFraction = 0.46;
  static const double _mediumFrom = 600;
  static const double _imageAspect = 4 / 3;
  static const int _taglineLines = 3;
  static const double _dot = 8;
  static const double _dotActive = 20;

  PageController? _controller;
  double _fraction = 0;
  int _page = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _ensureController(double fraction) {
    if ((_controller != null) && (fraction - _fraction).abs() < 0.001) return;
    _controller?.dispose();
    _fraction = fraction;
    _controller = PageController(
      viewportFraction: fraction,
      initialPage: _page,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader(
        title: 'Deepavali Around India',
        subtitle: 'Six cities, six ways to celebrate',
      ),
      const SizedBox(height: AppSpacing.md),
      LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          _ensureController(
            MediaQuery.sizeOf(context).width >= _mediumFrom
                ? _mediumFraction
                : _compactFraction,
          );
          final cardWidth = w * _fraction - AppSpacing.md;
          final theme = Theme.of(context).textTheme;
          final scaler = MediaQuery.textScalerOf(context);
          double line(TextStyle? s) =>
              scaler.scale((s?.fontSize ?? 16) * (s?.height ?? 1.5));
          // Fixed height from the text scale (docs/DESIGN_SYSTEM.md): photo,
          // name, state and up to [_taglineLines] lines of tagline.
          final height =
              cardWidth / _imageAspect +
              2 * AppSpacing.md +
              line(theme.titleLarge) +
              line(theme.bodySmall) +
              _taglineLines * line(theme.bodyMedium) +
              2 * AppSpacing.xs +
              AppSpacing.sm;
          return Column(
            children: [
              SizedBox(
                height: height,
                child: PageView.builder(
                  controller: _controller,
                  padEnds: false,
                  itemCount: destinations.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: _DestinationCard(
                      destination: destinations[i],
                      index: i,
                      aspect: _imageAspect,
                      taglineLines: _taglineLines,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      AnimatedContainer(
                        duration: AppDurations.fast,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        width: i == _page ? _dotActive : _dot,
                        height: _dot,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? DiwaliPalette.gold
                              : DiwaliPalette.goldBorder,
                          borderRadius: AppRadius.mdAll,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: DiwaliButton(
          label: 'Photo credits',
          icon: Icons.photo_library_outlined,
          kind: DiwaliButtonKind.tertiary,
          onPressed: () => showPhotoCreditsSheet(context),
        ),
      ),
    ],
  );
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.destination,
    required this.index,
    required this.aspect,
    required this.taglineLines,
  });

  final Destination destination;
  final int index;
  final double aspect;
  final int taglineLines;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = destination;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label:
          '${d.name}, ${d.state}. ${d.tagline} '
          '${index + 1} of ${destinations.length}. Opens details.',
      onTap: () => context.push(DeepavaliRoutes.destinationPath(d.id)),
      child: Material(
        color: DiwaliPalette.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: DiwaliPalette.goldBorder),
        ),
        child: InkWell(
          onTap: () => context.push(DeepavaliRoutes.destinationPath(d.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: aspect,
                child: Hero(
                  tag: DeepavaliRoutes.heroTag(d.id),
                  child: DestinationImage(
                    destination: d,
                    decodeWidth: AppSizes.photoDecodeWidth,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge?.copyWith(
                        color: DiwaliPalette.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      d.state,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: DiwaliPalette.saffron,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      d.tagline,
                      maxLines: taglineLines,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
