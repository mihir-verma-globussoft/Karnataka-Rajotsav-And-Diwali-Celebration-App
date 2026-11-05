import 'dart:math' as math;

import 'ar_scene.dart';

/// Turns a stream of poster sightings into a stable origin for a zone.
///
/// The origin keeps world up as its +Y and points its +Z straight out of the
/// poster, levelled. Both ARKit and ARCore align world up with gravity, so
/// using it, rather than the poster's own tilt, removes most of the angle error
/// that would otherwise grow with distance from the poster. It also means a
/// position saved on an iPhone lands in the same place on an Android phone.
class PosterLock {
  /// Early sightings are the least accurate, so they are thrown away.
  static const int samplesSkipped = 10;
  static const int samplesAveraged = 30;
  static const int samplesNeeded = samplesSkipped + samplesAveraged;

  /// Further than this the pose estimate of a small poster is too rough, and
  /// every item saved against it would land somewhere else next time.
  static const double maxDistanceMetres = 1.5;

  static const Duration maxGap = Duration(seconds: 1);

  final List<ArPosterSeen> _samples = [];
  DateTime? _last;

  String? get posterId => _samples.isEmpty ? null : _samples.last.posterId;

  double get progress => _samples.length / samplesNeeded;

  bool _tooFar = false;

  /// The last sighting was too far away to use.
  bool get tooFar => _tooFar;

  void reset() {
    _samples.clear();
    _last = null;
    _tooFar = false;
  }

  /// Returns the origin once enough steady sightings have come in.
  ArOrigin? add(ArPosterSeen sighting, DateTime now) {
    final last = _last;
    if (last != null && now.difference(last) > maxGap ||
        posterId != null && posterId != sighting.posterId) {
      reset();
    }
    _last = now;
    _tooFar = _distance(sighting) > maxDistanceMetres;
    if (_tooFar) return null;
    _samples.add(sighting);
    if (_samples.length < samplesNeeded) return null;

    final usable = _samples.skip(samplesSkipped).toList();
    var x = 0.0, y = 0.0, z = 0.0, forwardX = 0.0, forwardZ = 0.0;
    for (final sample in usable) {
      x += sample.pose[12];
      y += sample.pose[13];
      z += sample.pose[14];
      final forward = levelledForward(sample.pose, sample.camera);
      forwardX += forward.x;
      forwardZ += forward.z;
    }
    final count = usable.length;
    reset();
    return ArOrigin(
      position: Vec3(x / count, y / count, z / count),
      yaw: math.atan2(forwardX, forwardZ),
    );
  }

  static double _distance(ArPosterSeen sighting) {
    final dx = sighting.camera.x - sighting.pose[12];
    final dy = sighting.camera.y - sighting.pose[13];
    final dz = sighting.camera.z - sighting.pose[14];
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }
}

/// The level direction a poster faces, as a unit vector.
Vec3 levelledForward(List<double> pose, Vec3 camera) {
  // The second column is the image's normal. The camera is always on the
  // printed side, which settles which way it points on every platform.
  var normalX = pose[4], normalY = pose[5], normalZ = pose[6];
  final toCamera =
      (camera.x - pose[12]) * normalX +
      (camera.y - pose[13]) * normalY +
      (camera.z - pose[14]) * normalZ;
  if (toCamera < 0) {
    normalX = -normalX;
    normalY = -normalY;
    normalZ = -normalZ;
  }
  var x = normalX, z = normalZ;
  // A poster lying flat has no level normal, so use the way its top points.
  // The third column runs down the image.
  if (math.sqrt(x * x + z * z) < 0.5) {
    x = -pose[8];
    z = -pose[10];
  }
  final length = math.sqrt(x * x + z * z);
  return Vec3(x / length, 0, z / length);
}
