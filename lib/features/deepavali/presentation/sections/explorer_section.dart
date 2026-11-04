import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../deepavali_providers.dart';
import '../../domain/content/explorer_topics.dart';
import '../../domain/festival_dates.dart';
import '../../domain/festival_status.dart';
import '../theme/diwali_palette.dart';
import '../widgets/diwali_card.dart';
import '../widgets/section_header.dart';
import '../widgets/timeline_sheet.dart';
import '../widgets/topic_sheet.dart';

/// Discover Deepavali: six tappable topic cards opening bottom sheets.
class ExplorerSection extends ConsumerWidget {
  const ExplorerSection({this.dates = deepavaliDates, super.key});

  final FestivalDates dates;

  /// Cards go single-column when narrow or when text is very large.
  static const double _twoColumnMinWidth = 360;
  static const double _bigText = 1.6;
  static const int _titleLines = 2;
  static const int _teaserLines = 3;

  void _open(BuildContext context, WidgetRef ref, ExplorerTopic topic) {
    if (topic.id == fiveDaysTopicId) {
      final status = FestivalStatus.at(ref.read(deepavaliNowProvider)(), dates);
      showTimelineSheet(context, dates: dates, status: status);
    } else {
      showTopicSheet(context, topic);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader(
        title: 'Discover Deepavali',
        subtitle: 'Stories, flavours and rituals',
      ),
      const SizedBox(height: AppSpacing.md),
      LayoutBuilder(
        builder: (context, constraints) {
          final big = MediaQuery.textScalerOf(context).scale(1) >= _bigText;
          final cols = constraints.maxWidth < _twoColumnMinWidth || big ? 1 : 2;
          // Fixed tile height computed from the text scale (see
          // docs/DESIGN_SYSTEM.md "Grid tiles"): deterministic, so it does not
          // depend on when the font finishes loading. Text is capped at
          // [_titleLines] / [_teaserLines] lines.
          final theme = Theme.of(context).textTheme;
          final scaler = MediaQuery.textScalerOf(context);
          double line(TextStyle? style) =>
              scaler.scale((style?.fontSize ?? 16) * (style?.height ?? 1.5));
          final tileHeight =
              2 * AppSpacing.md +
              AppIconSizes.lg +
              AppSpacing.sm +
              _titleLines * line(theme.titleMedium) +
              AppSpacing.xs +
              _teaserLines * line(theme.bodySmall) +
              // Slack for font metrics that differ slightly from the estimate.
              AppSpacing.sm;
          final rows = <Widget>[];
          for (var i = 0; i < explorerTopics.length; i += cols) {
            final row = explorerTopics.skip(i).take(cols).toList();
            rows.add(
              SizedBox(
                height: tileHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < cols; c++) ...[
                      if (c > 0) const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: c < row.length
                            ? _TopicCard(
                                topic: row[c],
                                onTap: () => _open(context, ref, row[c]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            );
            if (i + cols < explorerTopics.length) {
              rows.add(const SizedBox(height: AppSpacing.md));
            }
          }
          return Column(children: rows);
        },
      ),
    ],
  );
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.onTap});

  final ExplorerTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DiwaliCard(
      onTap: onTap,
      semanticLabel: '${topic.title}. ${topic.teaser} Opens details.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            topicIcon(topic.id),
            color: DiwaliPalette.saffron,
            size: AppIconSizes.lg,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            topic.title,
            maxLines: ExplorerSection._titleLines,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(
              color: DiwaliPalette.cream,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            topic.teaser,
            maxLines: ExplorerSection._teaserLines,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: DiwaliPalette.creamMuted),
          ),
        ],
      ),
    );
  }
}
