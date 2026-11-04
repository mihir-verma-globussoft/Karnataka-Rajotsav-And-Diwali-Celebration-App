import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../team_members.dart';
import 'team_member_view.dart';

/// Team tab: an animated header and staggered, parallax photo cards that
/// fade in one after another. Tap a card to open the member full-screen.
class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  static const double _gap = AppSpacing.md;
  static const int _maxColumns = 3;

  /// Large text gets one card per row so names never get cut.
  static const double _singleColumnTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final bigText =
        MediaQuery.textScalerOf(context).scale(1) > _singleColumnTextScale;
    return Scaffold(
      body: SafeArea(
        child: ConstrainedBody(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth - _gap * 2;
              final fit = ((width + _gap) / (AppSizes.teamTileMinWidth + _gap))
                  .floor();
              final columns = bigText ? 1 : fit.clamp(1, _maxColumns);
              final tileWidth = (width - _gap * (columns - 1)) / columns;
              final rows = (teamMembers.length / columns).ceil();
              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _Header()),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: _gap),
                    sliver: SliverList.separated(
                      itemCount: rows,
                      separatorBuilder: (_, _) => const SizedBox(height: _gap),
                      itemBuilder: (context, row) {
                        final start = row * columns;
                        final end = (start + columns).clamp(
                          0,
                          teamMembers.length,
                        );
                        // A short last row is centred, not left-aligned.
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = start; i < end; i++) ...[
                              if (i > start) const SizedBox(width: _gap),
                              SizedBox(
                                width: tileWidth,
                                // Every other column sits lower: a staggered,
                                // less grid-like look.
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: columns > 1 && (i - start).isOdd
                                        ? AppSpacing.lg
                                        : 0,
                                  ),
                                  child: Reveal(
                                    delay: AppDurations.stagger * (i - start),
                                    child: _MemberCard(index: i),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  // Keeps the last row clear of the floating bar.
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSizes.floatingBarClearance),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Gradient banner: the icon pulses and a light sweeps across it a few times,
/// then it comes to rest.
class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> with SingleTickerProviderStateMixin {
  static const int _pulses = 4;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      unawaited(_c.repeat(reverse: true, count: _pulses));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(TeamPage._gap),
      child: Reveal(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.xlAll,
              gradient: LinearGradient(
                // The gradient's angle drifts slowly with the pulse.
                begin: Alignment(-1 + _c.value, -1),
                end: Alignment(1 - _c.value, 1),
                colors: [
                  scheme.primaryContainer,
                  scheme.tertiaryContainer,
                  scheme.secondaryContainer,
                ],
              ),
            ),
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, child) => Transform.scale(
                    scale: 1 + (1 - AppScale.pressed) * 4 * _c.value,
                    child: child,
                  ),
                  child: Icon(
                    Icons.diversity_3,
                    size: AppIconSizes.lg,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Meet the team',
                          style: text.titleLarge?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${teamMembers.length} people who built this '
                        'celebration. Tap a card to meet them.',
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends ConsumerStatefulWidget {
  const _MemberCard({required this.index});

  final int index;

  @override
  ConsumerState<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends ConsumerState<_MemberCard> {
  bool _pressed = false;

  static const double _aspect = 4 / 5;

  @override
  Widget build(BuildContext context) {
    final member = teamMembers[widget.index];
    final accent = memberAccent(widget.index);
    final text = Theme.of(context).textTheme;
    return AnimatedScale(
      scale: _pressed ? AppScale.pressed : 1,
      duration: AppDurations.fast,
      curve: Curves.easeOut,
      child: AspectRatio(
        aspectRatio: _aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: memberHeroTag(member),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: accent, width: AppSizes.ring),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.lgAll,
                  // The photo drifts as the card scrolls past.
                  child: Parallax(
                    child: MemberPhoto(
                      member: member,
                      cacheWidth: AppSizes.photoDecodeWidth,
                    ),
                  ),
                ),
              ),
            ),
            // Dark fade so the name reads on any photo.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lgAll,
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.transparent,
                      AppColors.ink.withValues(alpha: AppOpacity.strong),
                    ],
                  ),
                ),
              ),
            ),
            // Number badge.
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    '${widget.index + 1}'.padLeft(2, '0'),
                    style: text.labelMedium?.copyWith(
                      color: AppColors.onBanner,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    member.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: text.titleSmall?.copyWith(color: AppColors.onNight),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Accent bar that draws itself in.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: AppDurations.slow,
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => Container(
                      width: AppSizes.dotActive * 2 * t,
                      height: AppSizes.dot / 2,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: AppRadius.lgAll,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: AppColors.transparent,
                borderRadius: AppRadius.lgAll,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onHighlightChanged: (v) => setState(() => _pressed = v),
                  onTap: () {
                    ref.read(hapticsProvider).selection();
                    openMember(context, widget.index);
                  },
                  child: Semantics(
                    button: true,
                    label: 'Open ${member.name}',
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
