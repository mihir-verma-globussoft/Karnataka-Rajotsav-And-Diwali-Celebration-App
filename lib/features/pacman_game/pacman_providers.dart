import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/asset_game_over_audio.dart';
import 'domain/game_over_audio.dart';

/// Override in tests with a fake [GameOverAudio].
final gameOverAudioProvider = Provider<GameOverAudio>((ref) {
  final audio = AssetGameOverAudio();
  ref.onDispose(audio.dispose);
  return audio;
});
