import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/festival_dates.dart';
import '../sections/countdown_section.dart' show formatShortDate;
import '../theme/diwali_palette.dart';
import 'diwali_motion.dart';

/// The five days as a horizontal stepper. Today's step (if today is one of
/// the days) glows. Every step is a button.
/// Width of one step: grows with the phone's text size so long day names wrap
/// between words instead of breaking inside them.
double timelineStepWidth(BuildContext context) {
  // Measured on body-text size: Android scales big sizes less, so scaling the
  // step width itself would barely change it.
  const reference = 14.0;
  final factor = MediaQuery.textScalerOf(context).scale(reference) / reference;
  return AppSizes.timelineStep * factor;
}

class TimelineStepper extends StatefulWidget {
  const TimelineStepper({
    required this.dates,
    required this.today,
    required this.onTap,
    super.key,
  });

  final FestivalDates dates;

  /// Today's festival day, or null outside the five days.
  final FestivalDay? today;
  final ValueChanged<FestivalDay> onTap;

  @override
  State<TimelineStepper> createState() => _TimelineStepperState();
}

class _TimelineStepperState extends State<TimelineStepper> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    // Start with today's step in view.
    final index = widget.today == null
        ? 0
        : festivalDays.indexOf(widget.today!).clamp(0, festivalDays.length - 1);
    _initialIndex = index;
    _scroll = ScrollController()..addListener(_updateCue);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      // Start with today's step in view.
      final target = _initialIndex * timelineStepWidth(context) / 2;
      _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
      _updateCue();
    });
  }

  late final int _initialIndex;

  /// More days are hidden off to the right.
  bool _moreToRight = false;

  /// Scrolls on to the days that are out of sight.
  void _showMore() {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      unawaited(
        _scroll.animateTo(
          target,
          duration: AppDurations.slow,
          curve: Curves.easeInOutCubic,
        ),
      );
    }
  }

  void _updateCue() {
    if (!mounted || !_scroll.hasClients) return;
    final more = _scroll.position.extentAfter > 0;
    if (more != _moreToRight) setState(() => _moreToRight = more);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = DiwaliMotion.of(context);
    return Semantics(
      label: 'The five days of Deepavali',
      container: true,
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < festivalDays.length; i++)
                  _Step(
                    day: festivalDays[i],
                    date: widget.dates.civilDate(festivalDays[i]),
                    isFirst: i == 0,
                    isLast: i == festivalDays.length - 1,
                    isToday: festivalDays[i] == widget.today,
                    isPast:
                        widget.today != null &&
                        i < festivalDays.indexOf(widget.today!),
                    clock: motion.animate ? motion.clock : null,
                    onTap: () => widget.onTap(festivalDays[i]),
                  ),
              ],
            ),
          ),
          if (_moreToRight)
            Positioned(
              top: 0,
              right: 0,
              child: Semantics(
                container: true,
                button: true,
                label: 'Show the last days',
                excludeSemantics: true,
                onTap: _showMore,
                child: InkResponse(
                  onTap: _showMore,
                  radius: AppSizes.minTouchTarget / 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DiwaliPalette.surfaceHigh.withValues(
                        alpha: AppOpacity.secondaryText,
                      ),
                      border: Border.all(color: DiwaliPalette.gold),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: DiwaliPalette.gold,
                      size: AppIconSizes.md,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.day,
    required this.date,
    required this.isFirst,
    required this.isLast,
    required this.isToday,
    required this.isPast,
    required this.clock,
    required this.onTap,
  });

  final FestivalDay day;
  final DateTime date;
  final bool isFirst;
  final bool isLast;
  final bool isToday;
  final bool isPast;
  final ValueListenable<double>? clock;
  final VoidCallback onTap;

  /// Dot sizes.
  static const double _dot = 16;
  static const double _todayDot = 24;
  static const double _lineThickness = 2;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label =
        '${day.title}, ${formatShortDate(date)}'
        '${isToday ? ', today' : ''}';
    final lit = isToday || isPast;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: SizedBox(
          width: timelineStepWidth(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                SizedBox(
                  height: _todayDot + AppSpacing.sm,
                  child: Row(
                    children: [
                      Expanded(
                        child: _Line(visible: !isFirst, lit: lit),
                      ),
                      _Dot(
                        size: isToday ? _todayDot : _dot,
                        lit: lit,
                        glow: isToday,
                        clock: clock,
                      ),
                      Expanded(
                        child: _Line(visible: !isLast, lit: isPast),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatShortDate(date),
                  style: text.labelMedium?.copyWith(
                    color: isToday
                        ? DiwaliPalette.gold
                        : DiwaliPalette.creamMuted,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    day.title,
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: isToday
                          ? DiwaliPalette.cream
                          : DiwaliPalette.creamMuted,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
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

class _Line extends StatelessWidget {
  const _Line({required this.visible, required this.lit});

  final bool visible;
  final bool lit;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _Step._lineThickness,
    child: ColoredBox(
      color: !visible
          ? AppColors.transparent
          : lit
          ? DiwaliPalette.gold
          : DiwaliPalette.goldBorder,
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.size,
    required this.lit,
    required this.glow,
    required this.clock,
  });

  final double size;
  final bool lit;
  final bool glow;
  final ValueListenable<double>? clock;

  @override
  Widget build(BuildContext context) {
    Widget dot(double pulse) => DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? DiwaliPalette.gold : DiwaliPalette.surfaceHigh,
        border: Border.all(
          color: lit ? DiwaliPalette.flameCore : DiwaliPalette.goldBorder,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: DiwaliPalette.flameCore.withValues(
                    alpha: AppOpacity.glow * (0.6 + 0.4 * pulse),
                  ),
                  blurRadius: AppSpacing.md * (0.7 + 0.3 * pulse),
                  spreadRadius: AppSpacing.xs * pulse,
                ),
              ]
            : null,
      ),
      child: SizedBox.square(dimension: size),
    );
    final c = clock;
    if (!glow || c == null) return dot(1);
    return ValueListenableBuilder<double>(
      valueListenable: c,
      // A slow breathing pulse between 0 and 1.
      builder: (context, t, _) => dot((1 + math.sin(t * 2.4)) / 2),
    );
  }
}
