import 'dart:math';

/// Recognises a deliberate, aggressive shake in a stream of accelerometer
/// readings (device movement with gravity removed, in m/s²). Pure, so the
/// thresholds can be tested without a device.
///
/// A shake is [joltsNeeded] jolts (readings rising above [threshold]) within
/// [window]. After a shake it waits for [cooldown] and for the device to
/// settle below half the threshold for [settle], so one long shake triggers
/// only once and ordinary movement (walking, scrolling, picking the phone
/// up) never does.
class ShakeDetector {
  ShakeDetector({
    this.threshold = 15,
    this.joltsNeeded = 3,
    this.window = const Duration(seconds: 1),
    this.cooldown = const Duration(milliseconds: 2500),
    this.settle = const Duration(milliseconds: 500),
  });

  /// Acceleration in m/s² that counts as a jolt (about 1.5 g by default).
  final double threshold;
  final int joltsNeeded;
  final Duration window;
  final Duration cooldown;
  final Duration settle;

  final List<Duration> _jolts = [];
  var _above = false;
  Duration? _lastShake;
  Duration? _calmSince;
  var _armed = true;

  /// Adds one reading taken at [time]; returns true when it completes a
  /// shake.
  bool add(double x, double y, double z, Duration time) {
    final magnitude = sqrt(x * x + y * y + z * z);

    if (!_armed) {
      // Wait for the cooldown and for the device to settle.
      if (magnitude < threshold / 2) {
        _calmSince ??= time;
      } else {
        _calmSince = null;
      }
      final cooled = time - _lastShake! >= cooldown;
      final calm = _calmSince != null && time - _calmSince! >= settle;
      if (cooled && calm) {
        _armed = true;
        _above = false;
      }
      return false;
    }

    final rising = magnitude >= threshold && !_above;
    _above = magnitude >= threshold;
    if (!rising) return false;

    _jolts
      ..add(time)
      ..removeWhere((t) => time - t > window);
    if (_jolts.length < joltsNeeded) return false;

    _jolts.clear();
    _lastShake = time;
    _calmSince = null;
    _armed = false;
    return true;
  }

  /// Forgets partial jolts, e.g. when the screen stops listening.
  void reset() {
    _jolts.clear();
    _above = false;
  }
}

/// A stream of detected shakes. It reads the motion sensor only while
/// someone listens, so cancelling the subscription stops the sensor.
abstract interface class ShakeSource {
  Stream<void> shakes();
}
