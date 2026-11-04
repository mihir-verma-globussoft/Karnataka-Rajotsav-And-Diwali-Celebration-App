import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../deepavali_providers.dart';
import '../../domain/festival_dates.dart';
import '../../domain/festival_status.dart';
import '../theme/diwali_palette.dart';
import '../widgets/diwali_button.dart';
import '../widgets/diwali_card.dart';
import '../widgets/diwali_motion.dart';
import '../widgets/section_header.dart';
import '../widgets/timeline_sheet.dart';

const List<String> _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "Sunday, 8 November 2026" for a civil date.
String formatCivilDate(DateTime d, {bool weekday = true}) {
  final base = '${d.day} ${_months[d.month - 1]} ${d.year}';
  return weekday ? '${_weekdays[d.weekday - 1]}, $base' : base;
}

/// Short "Fri 6 Nov".
String formatShortDate(DateTime d) =>
    '${_weekdays[d.weekday - 1].substring(0, 3)} ${d.day} '
    '${_months[d.month - 1].substring(0, 3)}';

/// Countdown to Lakshmi Puja, or the matching celebration status.
class CountdownSection extends ConsumerStatefulWidget {
  const CountdownSection({
    required this.onExplore,
    this.dates = deepavaliDates,
    super.key,
  });

  final VoidCallback onExplore;
  final FestivalDates dates;

  @override
  ConsumerState<CountdownSection> createState() => _CountdownSectionState();
}

class _CountdownSectionState extends ConsumerState<CountdownSection> {
  Timer? _timer;
  late FestivalStatus _status = _compute();

  FestivalStatus _compute() =>
      FestivalStatus.at(ref.read(deepavaliNowProvider)(), widget.dates);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _status = _compute());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tick only while the tab is visible and the app is resumed. Always
    // recompute from the clock, never by decrementing, so a changed device
    // clock or a long pause cannot leave a stale value.
    final active = DiwaliMotion.of(context).active;
    if (active && _timer == null) {
      _status = _compute();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else if (!active && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = widget.dates;
    final puja = dates.civilDate(dates.lakshmiPuja);
    final status = _status;
    final theme = Theme.of(context).textTheme;

    final Widget body;
    switch (status.phase) {
      case FestivalPhase.before:
      case FestivalPhase.festivalWeek:
        final next = status.next;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status.today != null)
              Text(
                'Today is ${status.today!.title}',
                style: theme.titleMedium?.copyWith(color: DiwaliPalette.gold),
              ),
            if (status.untilPuja != null) ...[
              if (status.today != null) const SizedBox(height: AppSpacing.sm),
              _Digits(remaining: status.untilPuja!),
            ] else
              Text('The festival days continue.', style: theme.bodyLarge),
            if (next != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Next: ${next.title} · '
                '${formatShortDate(dates.civilDate(next))}',
                style: theme.bodyMedium?.copyWith(
                  color: DiwaliPalette.creamMuted,
                ),
              ),
            ],
          ],
        );
      case FestivalPhase.diwaliDay:
        body = Text(
          'Happy Deepavali! Today is the day.',
          style: theme.titleLarge?.copyWith(color: DiwaliPalette.gold),
        );
      case FestivalPhase.after:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deepavali has passed. See you next year!',
              style: theme.titleMedium?.copyWith(color: DiwaliPalette.gold),
            ),
            const SizedBox(height: AppSpacing.sm),
            DiwaliButton(
              label: 'Relive the celebration',
              kind: DiwaliButtonKind.secondary,
              onPressed: widget.onExplore,
            ),
          ],
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Celebration countdown',
          subtitle: 'How close is the festival?',
        ),
        const SizedBox(height: AppSpacing.md),
        DiwaliCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deepavali · ${formatCivilDate(puja)}',
                style: theme.titleSmall?.copyWith(
                  color: DiwaliPalette.creamMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              body,
              const SizedBox(height: AppSpacing.sm),
              DiwaliButton(
                label: 'View five-day schedule',
                icon: Icons.calendar_month,
                kind: DiwaliButtonKind.tertiary,
                onPressed: () =>
                    showTimelineSheet(context, dates: dates, status: status),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Days / hours / minutes / seconds tiles. The spoken label changes once a
/// minute; the ticking tiles are hidden from screen readers.
class _Digits extends StatelessWidget {
  const _Digits({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final d = remaining.isNegative ? Duration.zero : remaining;
    final units = [
      ('days', d.inDays),
      ('hrs', d.inHours % 24),
      ('min', d.inMinutes % 60),
      ('sec', d.inSeconds % 60),
    ];
    final label =
        '${d.inDays} days, ${d.inHours % 24} hours, ${d.inMinutes % 60} '
        'minutes until Deepavali';
    final tiles = [for (final u in units) _Tile(label: u.$1, value: u.$2)];
    final bigText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: bigText
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(child: tiles[0]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: tiles[1]),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: tiles[2]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: tiles[3]),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(child: tiles[i]),
                ],
              ],
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reduce = DiwaliMotion.of(context).reduceMotion;
    final number = value.toString().padLeft(2, '0');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DiwaliPalette.night.withValues(alpha: AppOpacity.strong),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: DiwaliPalette.goldBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: reduce ? Duration.zero : AppDurations.fast,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                number,
                key: ValueKey(number),
                style: text.headlineSmall?.copyWith(
                  color: DiwaliPalette.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              label,
              style: text.bodySmall?.copyWith(color: DiwaliPalette.creamMuted),
            ),
          ],
        ),
      ),
    );
  }
}
