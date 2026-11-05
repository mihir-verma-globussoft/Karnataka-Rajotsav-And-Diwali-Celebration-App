import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_scene.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_models.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_rules.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/presentation/ar_models.dart';

import 'hunt_fakes.dart';

/// Items are real-sized, can be made smaller or larger when placed, and stay
/// exactly as placed instead of turning to follow the player.
void main() {
  Map<String, dynamic> row({Object? scale}) => {
    'id': 'i',
    'zone': 'a',
    'kind': 'flag',
    'x': 1,
    'y': 2,
    'z': 3,
    'scale': ?scale,
  };

  test('items saved before sizes existed read as the standard size', () {
    expect(HuntItem.fromJson(row()).scale, 1);
  });

  test('a saved size is kept', () {
    final saved = HuntItem.fromJson(row(scale: 0.5));
    expect(saved.scale, 0.5);
    expect(saved.copyWith(found: true).scale, 0.5, reason: 'finding keeps it');
  });

  test('the standard size draws the models at about real life', () {
    final flag = huntModel(HuntItemKind.flag).height * huntModelScale;
    final diya = huntModel(HuntItemKind.diya).height * huntModelScale;
    expect(flag, lessThan(0.4), reason: 'a desk flag, metres tall was too big');
    expect(diya, lessThan(0.12));
  });

  test('a flag has no glow, which tints the whole screen up close', () {
    for (final part in huntModel(HuntItemKind.flag).parts) {
      expect(part.argb >>> 24, 0xFF, reason: 'every part of a flag is solid');
    }
  });

  test('an item is drawn at its saved size', () {
    expect(ArSceneItem.of(item('i')).scale, huntModelScale);
    expect(ArSceneItem.of(item('i', scale: 2)).scale, 2 * huntModelScale);
  });

  test('the smallest size can go well below the standard one', () {
    expect(huntItemMinScale, lessThanOrEqualTo(0.5));
    expect(huntItemMaxScale, greaterThan(1));
  });

  group('an item stays as placed', () {
    void expectFacesPoster(double x, double z) {
      final yaw = ArSceneItem(
        id: 'i',
        kind: HuntItemKind.flag,
        x: x,
        y: 0,
        z: z,
      ).yaw;
      final length = math.sqrt(x * x + z * z);
      // A model's front is +Z, which this yaw turns towards (sin, cos).
      expect(math.sin(yaw), closeTo(-x / length, 1e-9));
      expect(math.cos(yaw), closeTo(-z / length, 1e-9));
    }

    test('facing its poster, wherever it is', () {
      expectFacesPoster(0, 3);
      expectFacesPoster(2, 0);
      expectFacesPoster(-2, -1);
      expectFacesPoster(1.5, 2);
    });

    test('with an item on the poster itself still facing somewhere', () {
      final yaw = const ArSceneItem(
        id: 'i',
        kind: HuntItemKind.flag,
        x: 0,
        y: 0,
        z: 0,
      ).yaw;
      expect(yaw.isFinite, isTrue);
    });
  });
}
