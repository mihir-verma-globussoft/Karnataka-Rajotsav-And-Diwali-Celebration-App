import 'dart:math' as math;

import 'package:ar_hunt/features/ar/domain/ar_scene.dart';
import 'package:ar_hunt/features/ar/domain/poster_lock.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hunt_fakes.dart';

void main() {
  final start = DateTime(2026, 11, 4, 12);
  DateTime at(int i) => start.add(Duration(milliseconds: 66 * i));

  ArOrigin? feed(
    PosterLock lock,
    int count, {
    ArPosterSeen Function(int)? make,
    int from = 0,
  }) {
    ArOrigin? result;
    for (var i = from; i < from + count; i++) {
      result = lock.add(make?.call(i) ?? sighting('a'), at(i)) ?? result;
    }
    return result;
  }

  test('locks only after enough steady sightings', () {
    final lock = PosterLock();
    expect(feed(lock, PosterLock.samplesNeeded - 1), isNull);
    expect(lock.progress, greaterThan(0.9));
    final origin = lock.add(sighting('a'), at(PosterLock.samplesNeeded));
    expect(origin, isNotNull);
    expect(lock.progress, 0, reason: 'starts over for the next lock');
  });

  test('origin sits on the poster, facing out of it', () {
    final origin = feed(PosterLock(), PosterLock.samplesNeeded)!;
    expect(origin.position.x, closeTo(2, 1e-9));
    expect(origin.position.y, closeTo(1, 1e-9));
    expect(origin.position.z, closeTo(-3, 1e-9));
    // The poster faces +Z, the direction a yaw of zero means.
    expect(origin.yaw, closeTo(0, 1e-9));
  });

  test('facing is the same whichever way a platform points the normal', () {
    // The camera is what decides, so ARKit and ARCore cannot disagree.
    const flipped = ArPosterSeen(
      posterId: 'a',
      pose: [1, 0, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0, 2, 1, -3, 1],
      camera: Vec3(2, 1, -2),
    );
    final origin = feed(
      PosterLock(),
      PosterLock.samplesNeeded,
      make: (_) => flipped,
    )!;
    expect(origin.yaw, closeTo(0, 1e-9));
  });

  test('a poster turned to the side gives the matching yaw', () {
    // Facing +X, with the camera out to the right of it.
    const turned = ArPosterSeen(
      posterId: 'a',
      pose: [0, 0, -1, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 1],
      camera: Vec3(1.5, 1, 0),
    );
    final origin = feed(
      PosterLock(),
      PosterLock.samplesNeeded,
      make: (_) => turned,
    )!;
    expect(origin.yaw, closeTo(math.pi / 2, 1e-9));
  });

  test('a tilted poster still gives a level origin', () {
    // Tilted back 20 degrees: only its level direction may count.
    const tilt = 20 * math.pi / 180;
    final tilted = ArPosterSeen(
      posterId: 'a',
      pose: [
        1, 0, 0, 0, //
        0, math.sin(tilt), math.cos(tilt), 0, //
        0, -math.cos(tilt), math.sin(tilt), 0, //
        0, 1, 0, 1, //
      ],
      camera: const Vec3(0, 1, 1),
    );
    final forward = levelledForward(tilted.pose, tilted.camera);
    expect(forward.y, 0);
    expect(forward.z, closeTo(1, 1e-9));
  });

  test('a poster lying flat falls back to the way its top points', () {
    // Flat on a table, normal straight up, top of the image towards -Z.
    const flat = ArPosterSeen(
      posterId: 'a',
      pose: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
      camera: Vec3(0, 1, 0.5),
    );
    final forward = levelledForward(flat.pose, flat.camera);
    expect(forward.z, closeTo(-1, 1e-9));
    expect(forward.x, closeTo(0, 1e-9));
  });

  test('sightings from too far away never count', () {
    final lock = PosterLock();
    final origin = feed(
      lock,
      PosterLock.samplesNeeded * 2,
      make: (_) => sighting('a', cameraDistance: 5),
    );
    expect(origin, isNull);
    expect(lock.tooFar, isTrue);
    expect(lock.progress, 0);
  });

  test('losing sight of the poster starts the count again', () {
    final lock = PosterLock();
    feed(lock, 10);
    expect(lock.progress, greaterThan(0));
    final later = at(10).add(PosterLock.maxGap * 2);
    expect(lock.add(sighting('a'), later), isNull);
    expect(lock.progress, closeTo(1 / PosterLock.samplesNeeded, 1e-9));
  });

  test('changing posters mid-lock starts the count again', () {
    final lock = PosterLock();
    feed(lock, 10);
    lock.add(sighting('b'), at(11));
    expect(lock.posterId, 'b');
    expect(lock.progress, closeTo(1 / PosterLock.samplesNeeded, 1e-9));
  });

  test('the shaky first sightings are left out of the average', () {
    final origin = feed(
      PosterLock(),
      PosterLock.samplesNeeded,
      make: (i) {
        final base = sighting('a');
        final pose = List<double>.of(base.pose);
        if (i < PosterLock.samplesSkipped) pose[12] += 0.5;
        return ArPosterSeen(posterId: 'a', pose: pose, camera: base.camera);
      },
    )!;
    expect(origin.position.x, closeTo(2, 1e-9));
  });
}
