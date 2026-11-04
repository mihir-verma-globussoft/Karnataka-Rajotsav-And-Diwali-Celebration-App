import 'package:ar_hunt/features/ar/data/method_channel_ar_platform.dart';
import 'package:ar_hunt/features/ar/data/method_channel_ar_scene.dart';
import 'package:ar_hunt/features/ar/domain/ar_availability.dart';
import 'package:ar_hunt/features/ar/domain/ar_scene.dart';
import 'package:ar_hunt/features/ar/domain/hunt_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel(arChannelName);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('availability', () {
    test('parses native values; unknown becomes unavailable', () {
      expect(ArAvailability.parse('supported'), ArAvailability.supported);
      expect(ArAvailability.parse('weird'), ArAvailability.unavailable);
      expect(ArAvailability.parse(null), ArAvailability.unavailable);
    });

    test('channel returns the native answer', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'prepare'
            ? 'cameraPermissionDenied'
            : 'unsupportedDevice',
      );
      final platform = MethodChannelArPlatform();
      expect(
        await platform.checkAvailability(),
        ArAvailability.unsupportedDevice,
      );
      expect(await platform.prepare(), ArAvailability.cameraPermissionDenied);
    });

    test('missing native implementation degrades to unavailable', () async {
      final platform = MethodChannelArPlatform();
      expect(await platform.checkAvailability(), ArAvailability.unavailable);
      expect(await platform.prepare(), ArAvailability.unavailable);
      await platform.openSettings();
    });

    test('native failure degrades to unavailable', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'boom'),
      );
      final platform = MethodChannelArPlatform();
      expect(await platform.checkAvailability(), ArAvailability.unavailable);
      await platform.openSettings();
    });
  });

  group('events from the native view', () {
    test('poster sightings keep the full pose', () {
      final event = parseArSceneEvent('onPoster', {
        'id': 'a',
        'pose': List<double>.generate(16, (i) => i.toDouble()),
        'camera': [1.0, 2.0, 3.0],
      });
      expect(event, isA<ArPosterSeen>());
      final seen = event! as ArPosterSeen;
      expect(seen.posterId, 'a');
      expect(seen.pose[14], 14);
      expect(seen.camera.z, 3);
    });

    test('whole numbers from the codec still parse', () {
      final event = parseArSceneEvent('onNearest', {
        'id': 'x',
        'distance': 3,
        'bearing': 0,
      });
      expect((event! as ArNearestChanged).distance, 3.0);
      expect(
        (event as ArNearestChanged).onScreen,
        isFalse,
        reason: 'not reported means not seen, so it can never be claimed',
      );
    });

    test('every other event parses', () {
      expect(
        parseArSceneEvent('onTracking', {'state': 'tooDark'}),
        isA<ArTrackingChanged>().having(
          (e) => e.tracking,
          'tracking',
          ArTracking.tooDark,
        ),
      );
      expect(
        parseArSceneEvent('onItemTap', {'id': 'x', 'distance': 1.5}),
        isA<ArItemTapped>(),
      );
      expect(
        parseArSceneEvent('onSurfaceTap', {
          'x': 1.0,
          'y': 2.0,
          'z': 3.0,
          'onSurface': false,
        }),
        isA<ArSurfaceTapped>().having((e) => e.onSurface, 'onSurface', isFalse),
      );
      expect(parseArSceneEvent('onInterrupted', null), isA<ArInterrupted>());
      expect(
        parseArSceneEvent('onError', {'code': 'camera_unavailable'}),
        isA<ArFailed>(),
      );
    });

    test('unknown events and tracking states are harmless', () {
      expect(parseArSceneEvent('onSomethingNew', {'a': 1}), isNull);
      expect(ArTracking.parse('new'), ArTracking.unavailable);
    });
  });

  group('calls to the native view', () {
    const viewChannel = MethodChannel('${arViewType}_7');
    tearDown(() => messenger.setMockMethodCallHandler(viewChannel, null));

    test('starts on creation and sends what the scene needs', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(viewChannel, (call) async {
        calls.add(call);
        return null;
      });
      final scene = MethodChannelArScene(7);
      await scene.setOrigin(const ArOrigin(position: Vec3(1, 2, 3), yaw: 0.5));
      await scene.setItems(const [
        ArSceneItem(id: 'i', kind: HuntItemKind.flag, x: 1, y: 2, z: 3),
      ]);
      await scene.celebrate('i');
      await scene.tap(10, 20);
      await scene.setOrigin(null);
      await scene.dispose();
      await scene.dispose();
      expect(calls.map((c) => c.method), [
        'start',
        'setOrigin',
        'setItems',
        'celebrate',
        'tap',
        'setOrigin',
        'dispose',
      ]);
      expect(calls[1].arguments, {'x': 1.0, 'y': 2.0, 'z': 3.0, 'yaw': 0.5});
      expect((calls[2].arguments as List<Object?>).first, {
        'id': 'i',
        'kind': 'flag',
        'x': 1.0,
        'y': 2.0,
        'z': 3.0,
      });
      expect(calls[5].arguments, isNull);
    });

    test('native events reach the stream', () async {
      messenger.setMockMethodCallHandler(viewChannel, (_) async => null);
      final scene = MethodChannelArScene(7);
      final received = <ArSceneEvent>[];
      final subscription = scene.events.listen(received.add);
      addTearDown(subscription.cancel);
      await messenger.handlePlatformMessage(
        viewChannel.name,
        viewChannel.codec.encodeMethodCall(const MethodCall('onInterrupted')),
        (_) {},
      );
      await pumpEventQueue();
      expect(received.single, isA<ArInterrupted>());
      await scene.dispose();
    });

    test('a view that has gone away is not an error', () async {
      final scene = MethodChannelArScene(7);
      await scene.setOrigin(null);
      await scene.dispose();
    });
  });

  test('hunt data from the server parses', () {
    final parsed = HuntItem.fromJson({
      'id': 'abc',
      'zone': 'b',
      'kind': 'flag',
      'x': 1,
      'y': 0.5,
      'z': -2,
      'hint': null,
      'found': true,
    });
    expect(parsed.kind, HuntItemKind.flag);
    expect(parsed.x, 1.0);
    expect(parsed.found, isTrue);

    final leader = HuntLeader.fromJson({
      'rank': 1,
      'user_id': 'u',
      'username': 'Asha',
      'avatar_url': null,
      'high_score': 25,
    });
    expect(leader.points, 25);

    final result = CollectResult.fromJson({
      'points': 15,
      'first_finder': true,
      'already_found': false,
      'is_admin': false,
      'total_points': 40,
    });
    expect(result.totalPoints, 40);
  });

  test('an unknown kind from a newer server still shows something', () {
    expect(HuntItemKind.parse('lantern'), HuntItemKind.diya);
  });

  test('poster assets exist for every zone', () {
    for (final zone in huntZones) {
      expect(zone.posterAsset, 'assets/ar/posters/${zone.id}.png');
    }
    expect(huntZoneById('a')?.label, 'Start point A');
    expect(huntZoneById('nope'), isNull);
  });
}
