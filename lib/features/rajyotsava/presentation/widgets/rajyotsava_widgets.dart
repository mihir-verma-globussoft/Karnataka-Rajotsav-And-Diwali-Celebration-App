import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/models.dart';

/// Red-and-yellow theme for every Rajyotsava screen, derived from the app
/// theme so shapes, sizes and light/dark mode stay consistent: red is the
/// primary colour and the flag's yellow is the tertiary colour.
class RajyotsavaTheme extends StatelessWidget {
  const RajyotsavaTheme({required this.child, super.key});

  final Widget child;

  static ThemeData of(ThemeData base) {
    final brightness = base.colorScheme.brightness;
    final red = ColorScheme.fromSeed(
      seedColor: AppColors.kannadaRed,
      brightness: brightness,
    );
    final yellow = ColorScheme.fromSeed(
      seedColor: AppColors.kannadaYellow,
      brightness: brightness,
    );
    return base.copyWith(
      colorScheme: red.copyWith(
        tertiary: yellow.primary,
        onTertiary: yellow.onPrimary,
        tertiaryContainer: yellow.primaryContainer,
        onTertiaryContainer: yellow.onPrimaryContainer,
      ),
      scaffoldBackgroundColor: red.surface,
    );
  }

  @override
  Widget build(BuildContext context) =>
      Theme(data: of(Theme.of(context)), child: child);
}

/// Small Kannada flag: yellow over red.
class KannadaFlag extends StatelessWidget {
  const KannadaFlag({this.width = AppSizes.flagSmall, super.key});

  final double width;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Kannada flag',
    image: true,
    child: ClipRRect(
      borderRadius: AppRadius.xsAll,
      child: SizedBox(
        width: width,
        height: width * 2 / 3,
        child: const Column(
          // Stretch: an empty ColoredBox would otherwise get zero width.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ColoredBox(color: AppColors.kannadaYellow)),
            Expanded(child: ColoredBox(color: AppColors.kannadaRed)),
          ],
        ),
      ),
    ),
  );
}

/// Section heading with an English title and its Kannada equivalent.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, required this.kannada, super.key});

  final String title;
  final String kannada;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: AppSpacing.sm,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            Text(
              kannada,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round icon used on list cards.
class IconBadge extends StatelessWidget {
  const IconBadge({required this.icon, this.size = AppSizes.badge, super.key});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size / 2, color: scheme.onSecondaryContainer),
    );
  }
}

/// Icon for each kind of Discover item.
IconData discoverIcon(DiscoverKind kind) => switch (kind) {
  DiscoverKind.monument => Icons.account_balance,
  DiscoverKind.temple => Icons.temple_hindu,
  DiscoverKind.waterfall => Icons.water,
  DiscoverKind.nature => Icons.landscape,
  DiscoverKind.sweet => Icons.cake,
  DiscoverKind.dish => Icons.restaurant,
  DiscoverKind.festival => Icons.celebration,
  DiscoverKind.art => Icons.theater_comedy,
  DiscoverKind.craft => Icons.palette,
  DiscoverKind.sport => Icons.emoji_events,
  DiscoverKind.writer => Icons.menu_book,
  DiscoverKind.leader => Icons.person,
  DiscoverKind.artist => Icons.movie,
  DiscoverKind.engineer => Icons.engineering,
};

/// Icon for each Discover category.
IconData categoryIcon(DiscoverCategory category) => switch (category) {
  DiscoverCategory.places => Icons.place,
  DiscoverCategory.food => Icons.restaurant,
  DiscoverCategory.culture => Icons.festival,
  DiscoverCategory.people => Icons.people,
};
