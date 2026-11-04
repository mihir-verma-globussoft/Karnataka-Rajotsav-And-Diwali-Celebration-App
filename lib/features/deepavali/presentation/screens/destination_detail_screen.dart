import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/state_views.dart';
import '../../deepavali_routes.dart';
import '../../domain/content/destinations.dart';
import '../theme/diwali_palette.dart';
import '../theme/diwali_theme.dart';
import '../widgets/destination_image.dart';
import '../widgets/diwali_card.dart';
import '../widgets/glow_background.dart';

/// Full-screen detail for one destination. Unknown ids show a "not found"
/// message with a way back.
class DestinationDetailScreen extends StatelessWidget {
  const DestinationDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final destination = destinationById(id);
    return Theme(
      data: DiwaliTheme.data,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: GlowBackground()),
              if (destination == null)
                SafeArea(
                  child: ErrorView(
                    error: const NotFoundFailure(
                      'We could not find that destination.',
                    ),
                    onRetry: () => _back(context),
                    retryLabel: 'Back',
                  ),
                )
              else
                _Body(destination: destination),
              if (destination != null)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: IconButton.filled(
                      tooltip: 'Back',
                      style: IconButton.styleFrom(
                        backgroundColor: DiwaliPalette.night.withValues(
                          alpha: AppOpacity.strong,
                        ),
                        foregroundColor: DiwaliPalette.cream,
                        minimumSize: const Size.square(AppSizes.minTouchTarget),
                      ),
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _back(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final d = destination;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: ConstrainedBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: AppRadius.xlBottom,
                child: Hero(
                  tag: DeepavaliRoutes.heroTag(d.id),
                  child: DestinationImage(destination: d),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSizes.floatingBarClearance / 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      d.name,
                      style: text.displaySmall?.copyWith(
                        color: DiwaliPalette.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    d.state,
                    style: text.titleMedium?.copyWith(
                      color: DiwaliPalette.saffron,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    d.tagline,
                    style: text.titleMedium?.copyWith(
                      color: DiwaliPalette.cream,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _Heading('How it’s celebrated'),
                  for (final p in d.description) ...[
                    Text(p, style: text.bodyLarge),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.event,
                        color: DiwaliPalette.gold,
                        size: AppIconSizes.md,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Best time: ${d.bestTime}',
                          style: text.bodyMedium?.copyWith(
                            color: DiwaliPalette.creamMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _Heading('Interesting facts'),
                  for (final f in d.facts) ...[
                    DiwaliCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.text, style: text.bodyMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Source: ${f.source}',
                            style: text.bodySmall?.copyWith(
                              color: DiwaliPalette.creamMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    d.photo.line,
                    style: text.bodySmall?.copyWith(
                      color: DiwaliPalette.creamMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(color: DiwaliPalette.gold, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
