import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../theme/diwali_palette.dart';
import '../widgets/diwali_card.dart';
import '../widgets/section_header.dart';

/// The sections of the Deepavali page, in scroll order. Each phase replaces
/// one placeholder body with the real section while keeping the key, so the
/// hero CTA can scroll to it.
enum DiwaliSection {
  countdown('Celebration countdown', 'How close is the festival?', 2),
  explorer('Discover Deepavali', 'Stories, flavours and rituals', 3),
  destinations(
    'Deepavali Around India',
    'Six cities, six ways to celebrate',
    4,
  ),
  diyaGame('Light the Diyas', 'Tap every unlit diya before time runs out', 5),
  quiz('Deepavali Quiz', 'Test what you know', 6),
  rangoli('Rangoli Studio', 'Tap a shape to colour it', 7),
  greeting('Greeting Card', 'Create and share a wish', 8),
  more('More to Explore', 'Diya wall, guessing game and timeline', 9);

  const DiwaliSection(this.title, this.subtitle, this.phase);

  final String title;
  final String subtitle;

  /// Implementation phase that replaces this placeholder.
  final int phase;
}

/// Phase 1 placeholder: proves ordering, spacing and theming. Removed section
/// by section as the real content lands.
class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({required this.section, super.key});

  final DiwaliSection section;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(title: section.title, subtitle: section.subtitle),
      const SizedBox(height: AppSpacing.md),
      DiwaliCard(
        child: Row(
          children: [
            const Icon(Icons.hourglass_empty, color: DiwaliPalette.saffron),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Coming in phase ${section.phase}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
