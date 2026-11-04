import 'package:flutter/services.dart';

/// App-wide haptic feedback with names that say what happened, so every
/// module feels the same on iOS and Android. Read it from `hapticsProvider`
/// (lib/app/providers.dart); see docs/DESIGN_SYSTEM.md for when to use each.
abstract interface class AppHaptics {
  /// A light tap: pressing a button or card.
  Future<void> tap();

  /// A small tick: changing a selection (chips, tabs, toggles, pickers).
  Future<void> selection();

  /// Something good happened: a right answer, a discovery, a completed task.
  Future<void> success();

  /// Something needs attention but is not an error.
  Future<void> warning();

  /// Something went wrong: a wrong answer, a failed action.
  Future<void> error();

  /// A strong, deliberate moment: a detected shake, a big reveal.
  Future<void> heavy();
}

/// [AppHaptics] using the platform's haptic engine (Taptic Engine on
/// iPhone, the vibration motor on Android). Devices without haptics ignore
/// the calls; failures are swallowed, since haptics are never essential.
class SystemHaptics implements AppHaptics {
  const SystemHaptics();

  Future<void> _run(Future<void> Function() feedback) async {
    try {
      await feedback();
    } on Object {
      // No haptics on this device.
    }
  }

  @override
  Future<void> tap() => _run(HapticFeedback.lightImpact);

  @override
  Future<void> selection() => _run(HapticFeedback.selectionClick);

  @override
  Future<void> success() => _run(HapticFeedback.mediumImpact);

  @override
  Future<void> warning() => _run(HapticFeedback.heavyImpact);

  @override
  Future<void> error() => _run(HapticFeedback.vibrate);

  @override
  Future<void> heavy() => _run(HapticFeedback.heavyImpact);
}

/// [AppHaptics] that does nothing: for tests, or a "haptics off" setting.
class SilentHaptics implements AppHaptics {
  const SilentHaptics();

  @override
  Future<void> tap() async {}

  @override
  Future<void> selection() async {}

  @override
  Future<void> success() async {}

  @override
  Future<void> warning() async {}

  @override
  Future<void> error() async {}

  @override
  Future<void> heavy() async {}
}
