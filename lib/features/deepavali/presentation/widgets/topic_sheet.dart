import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/content/explorer_topics.dart';
import '../theme/diwali_palette.dart';
import 'diwali_button.dart';
import 'diwali_sheet.dart';

/// Icon for each explorer topic (kept out of the domain layer).
IconData topicIcon(String id) => switch (id) {
  'significance' => Icons.wb_twilight,
  'traditions' => Icons.auto_stories,
  'rangoli' => Icons.filter_vintage,
  'sweets' => Icons.bakery_dining,
  'rituals' => Icons.temple_hindu,
  fiveDaysTopicId => Icons.calendar_month,
  _ => Icons.auto_awesome,
};

/// Detail sheet for a text topic.
Future<void> showTopicSheet(BuildContext context, ExplorerTopic topic) =>
    showDiwaliSheet<void>(
      context,
      builder: (context) => _TopicSheet(topic: topic),
    );

class _TopicSheet extends StatelessWidget {
  const _TopicSheet({required this.topic});

  final ExplorerTopic topic;

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
          Row(
            children: [
              Icon(
                topicIcon(topic.id),
                color: DiwaliPalette.saffron,
                size: AppIconSizes.lg,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    topic.title,
                    style: text.headlineSmall?.copyWith(
                      color: DiwaliPalette.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final p in topic.paragraphs) ...[
            Text(p, style: text.bodyLarge),
            const SizedBox(height: AppSpacing.md),
          ],
          if (topic.regionalNote != null)
            _Callout(
              icon: Icons.public,
              title: 'Regional note',
              body: topic.regionalNote!,
            ),
          if (topic.didYouKnow != null) ...[
            const SizedBox(height: AppSpacing.md),
            _Callout(
              icon: Icons.lightbulb_outline,
              title: 'Did you know?',
              body: topic.didYouKnow!,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: DiwaliButton(
              label: 'Close',
              kind: DiwaliButtonKind.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DiwaliPalette.night.withValues(alpha: AppOpacity.strong),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: DiwaliPalette.goldBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: DiwaliPalette.gold, size: AppIconSizes.md),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(color: DiwaliPalette.gold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(body, style: text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
