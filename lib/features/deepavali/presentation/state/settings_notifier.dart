import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How animations are chosen. `system` follows the OS reduce-motion setting.
enum MotionPreference { system, on, off }

class DiwaliSettings {
  const DiwaliSettings({
    this.motion = MotionPreference.system,
    this.haptics = true,
    this.sound = false, // Sound stays off by default (plan Phase 10).
  });

  final MotionPreference motion;
  final bool haptics;
  final bool sound;

  DiwaliSettings copyWith({
    MotionPreference? motion,
    bool? haptics,
    bool? sound,
  }) => DiwaliSettings(
    motion: motion ?? this.motion,
    haptics: haptics ?? this.haptics,
    sound: sound ?? this.sound,
  );
}

/// In-memory for now; persistence is added when storage is approved.
/// Not autoDispose: the tab stays alive inside the home IndexedStack.
class DiwaliSettingsNotifier extends Notifier<DiwaliSettings> {
  @override
  DiwaliSettings build() => const DiwaliSettings();

  void setMotion(MotionPreference value) =>
      state = state.copyWith(motion: value);
  void setHaptics({required bool enabled}) =>
      state = state.copyWith(haptics: enabled);
  void setSound({required bool enabled}) =>
      state = state.copyWith(sound: enabled);
}

final diwaliSettingsProvider =
    NotifierProvider<DiwaliSettingsNotifier, DiwaliSettings>(
      DiwaliSettingsNotifier.new,
    );
