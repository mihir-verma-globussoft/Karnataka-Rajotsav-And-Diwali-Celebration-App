import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deepavali_providers.dart';
import '../../domain/sound.dart';

/// How strong a vibration is. Errors never vibrate.
enum Haptic { selection, light, medium, heavy }

/// The one place the tab makes a vibration or a sound effect.
class DiwaliFeedback {
  DiwaliFeedback(this._ref);

  final Ref _ref;

  /// A short vibration. Always on: the phone's own touch-feedback setting
  /// decides whether it is actually felt.
  void haptic(Haptic kind) {
    final call = switch (kind) {
      Haptic.selection => HapticFeedback.selectionClick(),
      Haptic.light => HapticFeedback.lightImpact(),
      Haptic.medium => HapticFeedback.mediumImpact(),
      Haptic.heavy => HapticFeedback.heavyImpact(),
    };
    unawaited(call.catchError((Object _) {}));
  }

  /// A short sound effect, if its file is bundled. Effects always play: the
  /// mute button only silences the background song.
  void sfx(Sfx sound) {
    unawaited(_ref.read(deepavaliAudioProvider).playEffect(sound));
  }

  /// A vibration and a sound together.
  void both(Haptic kind, Sfx sound) {
    haptic(kind);
    sfx(sound);
  }
}

final diwaliFeedbackProvider = Provider<DiwaliFeedback>(DiwaliFeedback.new);
