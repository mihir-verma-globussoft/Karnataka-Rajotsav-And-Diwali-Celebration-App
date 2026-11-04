import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../domain/shake.dart';

/// [ShakeSource] on the device accelerometer (sensors_plus "user
/// accelerometer": movement without gravity). The sensor runs only while
/// the stream is listened to, at a game-rate interval (50 Hz) so quick
/// jolts are not missed; listeners stop it when the screen is not shown.
class SensorShakeSource implements ShakeSource {
  const SensorShakeSource();

  @override
  Stream<void> shakes() {
    final detector = ShakeDetector();
    final start = DateTime.now();
    return userAccelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        )
        .where(
          (e) => detector.add(e.x, e.y, e.z, e.timestamp.difference(start)),
        )
        // A device without the sensor just never shakes.
        .handleError((Object _) {})
        .map((_) {});
  }
}
