import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rajyotsava_providers.dart';

/// Speaker button that reads [text] aloud in Kannada. If no Kannada voice is
/// installed, it explains how to install one on this platform.
class ListenButton extends ConsumerWidget {
  const ListenButton({required this.text, this.label, super.key});

  /// Kannada text to speak.
  final String text;

  /// Visible label; when null an icon-only button is shown.
  final String? label;

  static String get _installHint => defaultTargetPlatform == TargetPlatform.iOS
      ? 'Kannada voice not installed. On iPhone, go to Settings > '
            'Accessibility > Read & Speak (Spoken Content) > Voices > '
            'Kannada, and download "Soumya".'
      : 'Kannada voice not installed. On Android, go to Settings > '
            'Text-to-speech output > Preferred engine settings > Install '
            'voice data, and add Kannada.';

  Future<void> _listen(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final speaker = ref.read(kannadaSpeakerProvider);
    if (!await speaker.isAvailable()) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_installHint)));
      return;
    }
    // Pause the tab's song while the Kannada voice speaks.
    final song = ref.read(rajyotsavaSongProvider.notifier)..holdForVoice(true);
    try {
      await speaker.speak(text);
    } finally {
      song.holdForVoice(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = 'Listen to $text';
    if (label != null) {
      return Semantics(
        label: semantic,
        excludeSemantics: true,
        child: FilledButton.tonalIcon(
          onPressed: () => _listen(context, ref),
          icon: const Icon(Icons.volume_up),
          label: Text(label!),
        ),
      );
    }
    return IconButton(
      tooltip: semantic,
      onPressed: () => _listen(context, ref),
      icon: Icon(Icons.volume_up, color: Theme.of(context).colorScheme.primary),
    );
  }
}
