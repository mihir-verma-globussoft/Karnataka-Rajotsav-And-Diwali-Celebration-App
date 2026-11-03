import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/festival_dates.dart';
import '../../domain/festival_status.dart';
import '../sections/countdown_section.dart';
import '../theme/diwali_palette.dart';
import 'diwali_sheet.dart';

/// Bottom sheet listing the five days, highlighting today if it is one.
Future<void> showTimelineSheet(
  BuildContext context, {
  required FestivalDates dates,
  required FestivalStatus status,
}) => showDiwaliSheet<void>(
  context,
  builder: (context) => _TimelineSheet(dates: dates, today: status.today),
);

class _TimelineSheet extends StatelessWidget {
  const _TimelineSheet({required this.dates, required this.today});

  final FestivalDates dates;
  final FestivalDay? today;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'The five days of Deepavali',
              style: text.titleLarge?.copyWith(color: DiwaliPalette.gold),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Dates follow the calendar set for this app. Names and customs '
            'differ by region.',
            style: text.bodyMedium?.copyWith(color: DiwaliPalette.creamMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final day in festivalDays)
            _DayRow(
              day: day,
              date: dates.civilDate(day),
              isToday: day == today,
            ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.date, required this.isToday});

  final FestivalDay day;
  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        container: true,
        label:
            '${day.title}, ${formatCivilDate(date)}${isToday ? ', today' : ''}'
            '. ${day.summary}',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: isToday ? DiwaliPalette.gold : DiwaliPalette.goldBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        day.title,
                        style: text.titleMedium?.copyWith(
                          color: DiwaliPalette.cream,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Today',
                        style: text.labelLarge?.copyWith(
                          color: DiwaliPalette.gold,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${formatShortDate(date)} · ${day.alsoKnownAs}',
                  style: text.bodySmall?.copyWith(color: DiwaliPalette.saffron),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(day.summary, style: text.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
