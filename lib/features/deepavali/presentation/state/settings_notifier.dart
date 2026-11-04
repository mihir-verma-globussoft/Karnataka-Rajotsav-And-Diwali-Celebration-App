import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deepavali_providers.dart';

/// The one choice the person can make in the Deepavali tab.
class DiwaliSettings {
  const DiwaliSettings({this.music = true});

  /// The background song is on until the person mutes it. Only the song: the
  /// short sound effects always play.
  final bool music;
}

/// Remembers whether the song is muted, between launches. Not autoDispose: the
/// tab stays alive inside the home IndexedStack.
class DiwaliSettingsNotifier extends Notifier<DiwaliSettings> {
  @override
  DiwaliSettings build() {
    // The song shows as on at once; a remembered mute replaces it a moment
    // later.
    unawaited(_restore());
    return const DiwaliSettings();
  }

  Future<void> _restore() async {
    final stored = await ref.read(deepavaliSettingsStoreProvider).loadMusic();
    if (stored != null) state = DiwaliSettings(music: stored);
  }

  void setMusic({required bool enabled}) {
    state = DiwaliSettings(music: enabled);
    unawaited(ref.read(deepavaliSettingsStoreProvider).saveMusic(enabled));
  }
}

final diwaliSettingsProvider =
    NotifierProvider<DiwaliSettingsNotifier, DiwaliSettings>(
      DiwaliSettingsNotifier.new,
    );
