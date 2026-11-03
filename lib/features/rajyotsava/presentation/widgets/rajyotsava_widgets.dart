import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/models.dart';
import 'rajyotsava_motion.dart';

/// The Rajyotsava section's own look, the same in the phone's light and
/// dark mode (like the Deepavali tab): the banner's maroon gradient runs
/// behind every screen, cards are translucent "glass" on it, the flag's
/// yellow is the highlight colour (readable on maroon) and red fills
/// containers.
class RajyotsavaTheme extends StatelessWidget {
  const RajyotsavaTheme({required this.child, super.key});

  final Widget child;

  /// Built once from the app's dark theme, so shapes, sizes and component
  /// styles match the rest of the app.
  static final ThemeData data = _build();

  /// Background of every Rajyotsava screen.
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.sectionTop,
      AppColors.sectionMiddle,
      AppColors.sectionBottom,
    ],
  );

  static ThemeData _build() {
    // "Fidelity" keeps the flag's red and yellow vivid; the default
    // (tonal spot) mutes them into browns.
    final red = ColorScheme.fromSeed(
      seedColor: AppColors.kannadaRed,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final yellow = ColorScheme.fromSeed(
      seedColor: AppColors.kannadaYellow,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final base = AppTheme.dark;
    return base.copyWith(
      colorScheme: red.copyWith(
        // The flag's yellow as the highlight (red text would not read on
        // maroon), with dark maroon on yellow buttons.
        primary: AppColors.kannadaYellow,
        onPrimary: AppColors.bannerBottom,
        tertiary: yellow.primary,
        onTertiary: yellow.onPrimary,
        tertiaryContainer: yellow.primaryContainer,
        onTertiaryContainer: yellow.onPrimaryContainer,
        surface: AppColors.sectionMiddle,
        surfaceDim: AppColors.sectionBottom,
        surfaceBright: AppColors.sectionTop,
        surfaceContainerLowest: AppColors.glassLow,
        surfaceContainerLow: AppColors.glassLow,
        surfaceContainer: AppColors.glass,
        surfaceContainerHigh: AppColors.glassHigh,
        surfaceContainerHighest: AppColors.glassHighest,
        onSurface: AppColors.onNight,
        onSurfaceVariant: AppColors.onNightMuted,
        outline: AppColors.glassOutline,
        outlineVariant: AppColors.glassBorder,
      ),
      // The gradient shows through: see [build].
      scaffoldBackgroundColor: AppColors.transparent,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.transparent,
        surfaceTintColor: AppColors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.onNight,
      ),
      // Sheets and dialogs stay opaque so content does not show through.
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: AppColors.sectionSheet,
        modalBackgroundColor: AppColors.sectionSheet,
        dragHandleColor: AppColors.onNightMuted,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: AppColors.sectionSheet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: background),
    child: Theme(data: data, child: child),
  );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OrnamentDivider(),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
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
        ],
      ),
    );
  }
}

/// Round icon used on list cards.
class IconBadge extends StatelessWidget {
  const IconBadge({
    required this.icon,
    this.size = AppSizes.badge,
    this.accent,
    super.key,
  });

  final IconData icon;
  final double size;

  /// A solid accent colour (from `AppColors.accent…`) with a white icon; the
  /// theme's container colour when null.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = this.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent ?? scheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size / 2,
        color: accent == null
            ? scheme.onSecondaryContainer
            : AppColors.onBanner,
      ),
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
