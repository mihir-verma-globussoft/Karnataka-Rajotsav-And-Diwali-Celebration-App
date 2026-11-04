import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/shake.dart';

/// Feeds readings at 50 Hz (every 20 ms) and returns the times (ms) of the
/// shakes detected. [accel] gives the acceleration magnitude at time ms.
List<int> _run(ShakeDetector d, int ms, double Function(int t) accel) {
  final shakes = <int>[];
  for (var t = 0; t <= ms; t += 20) {
    // Spread the magnitude over the axes, as a real reading would.
    final a = accel(t);
    if (d.add(a * 0.6, a * 0.64, a * 0.48, Duration(milliseconds: t))) {
      shakes.add(t);
    }
  }
  return shakes;
}

/// Back-and-forth shaking: strong peaks every [period] ms.
double Function(int) _shaking(double peak, int period) =>
    (t) => (sin(t / period * pi)).abs() * peak;

void main() {
  test('ordinary movement never triggers', () {
    // Walking, scrolling, picking the phone up: up to ~6 m/s².
    final d = ShakeDetector();
    expect(_run(d, 10000, (t) => 3 + 3 * sin(t / 300)), isEmpty);
  });

  test('a single bump does not trigger', () {
    final d = ShakeDetector();
    expect(_run(d, 3000, (t) => t >= 1000 && t < 1060 ? 25 : 1), isEmpty);
  });

  test('strong jolts spread over seconds do not trigger', () {
    final d = ShakeDetector();
    // One jolt every 1.5 s: never three within a second.
    expect(_run(d, 6000, (t) => t % 1500 < 40 ? 25 : 1), isEmpty);
  });

  test('an aggressive shake triggers once, quickly', () {
    final d = ShakeDetector();
    final shakes = _run(d, 1000, _shaking(25, 150));
    expect(shakes, hasLength(1));
    expect(shakes.single, lessThan(700));
  });

  test('a gentle shake below the threshold does not trigger', () {
    final d = ShakeDetector();
    expect(_run(d, 3000, _shaking(10, 150)), isEmpty);
  });

  test('shaking non-stop for 6 s triggers only once', () {
    final d = ShakeDetector();
    expect(_run(d, 6000, _shaking(25, 150)), hasLength(1));
  });

  test('after cooldown and settling, a new shake triggers again', () {
    final d = ShakeDetector();
    // Shake 1 s, rest 3 s, shake 1 s.
    final shakes = _run(
      d,
      5000,
      (t) => t < 1000 || (t >= 4000) ? _shaking(25, 150)(t) : 1,
    );
    expect(shakes, hasLength(2));
    expect(shakes.last, greaterThanOrEqualTo(4000));
  });

  test('a shake soon after the last one is ignored (cooldown)', () {
    final d = ShakeDetector();
    // Shake, rest only 1 s, shake again: still within the 2.5 s cooldown.
    final shakes = _run(
      d,
      3000,
      (t) => t < 800 || (t >= 1800 && t < 2600) ? _shaking(25, 150)(t) : 1,
    );
    expect(shakes, hasLength(1));
  });

  test('the threshold is configurable', () {
    final sensitive = ShakeDetector(threshold: 8);
    expect(_run(sensitive, 1000, _shaking(10, 150)), hasLength(1));
  });
}
