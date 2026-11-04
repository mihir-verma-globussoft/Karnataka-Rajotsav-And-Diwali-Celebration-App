import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../deepavali_providers.dart';
import '../state/settings_notifier.dart';
import '../theme/diwali_palette.dart';

/// A round button that mutes and unmutes the background song, floating at the
/// top right of the page. The sound effects are not affected. It is only shown
/// when a song file is bundled.
class MuteButton extends ConsumerWidget {
  const MuteButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final music = ref.watch(diwaliSettingsProvider.select((s) => s.music));
    final hasMusic = ref.watch(audioCatalogProvider).value?.hasMusic ?? false;
    if (!hasMusic) return const SizedBox.shrink();
    final label = music ? 'Mute music' : 'Turn music on';
    void toggle() =>
        ref.read(diwaliSettingsProvider.notifier).setMusic(enabled: !music);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: toggle,
      child: Tooltip(
        message: label,
        child: Material(
          color: DiwaliPalette.night.withValues(alpha: AppOpacity.strong),
          shape: CircleBorder(
            side: BorderSide(color: DiwaliPalette.goldBorder),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: toggle,
            child: SizedBox.square(
              dimension: AppSizes.minTouchTarget,
              child: Icon(
                music ? Icons.volume_up : Icons.volume_off,
                color: DiwaliPalette.gold,
                size: AppIconSizes.md,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
