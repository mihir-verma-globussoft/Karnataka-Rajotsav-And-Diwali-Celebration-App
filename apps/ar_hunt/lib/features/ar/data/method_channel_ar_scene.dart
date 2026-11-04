import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/ar_scene.dart';

/// Talks to one native AR view. Everything the view draws or reports goes
/// through here; the same method names are handled in `ArHuntView.kt` and
/// `ArHuntView.swift`.
class MethodChannelArScene implements ArSceneController {
  MethodChannelArScene(int viewId)
    : _channel = MethodChannel('${arViewType}_$viewId') {
    _channel.setMethodCallHandler(_onNativeCall);
    // Native waits for this, so no event fires before the handler is set.
    _send('start');
  }

  final MethodChannel _channel;
  final _events = StreamController<ArSceneEvent>.broadcast();
  bool _disposed = false;

  @override
  Stream<ArSceneEvent> get events => _events.stream;

  @override
  Future<void> setOrigin(ArOrigin? origin) => _send(
    'setOrigin',
    origin == null
        ? null
        : {
            'x': origin.position.x,
            'y': origin.position.y,
            'z': origin.position.z,
            'yaw': origin.yaw,
          },
  );

  @override
  Future<void> setItems(List<ArSceneItem> items) => _send('setItems', [
    for (final item in items)
      {
        'id': item.id,
        'kind': item.kind.name,
        'x': item.x,
        'y': item.y,
        'z': item.z,
      },
  ]);

  @override
  Future<void> celebrate(String itemId) => _send('celebrate', itemId);

  @override
  Future<void> tap(double x, double y) => _send('tap', {'x': x, 'y': y});

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _channel.setMethodCallHandler(null);
    await _send('dispose');
    await _events.close();
  }

  Future<void> _send(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // The native view is already gone; there is nothing left to update.
    } on PlatformException {
      // As above.
    }
  }

  Future<void> _onNativeCall(MethodCall call) async {
    final event = parseArSceneEvent(call.method, call.arguments);
    if (event != null && !_events.isClosed) _events.add(event);
  }
}

/// Unknown events return null: a newer native side must not break older Dart.
ArSceneEvent? parseArSceneEvent(String method, Object? arguments) {
  final args = arguments is Map ? arguments : const <Object?, Object?>{};
  double number(Object? key) => (args[key] as num).toDouble();
  switch (method) {
    case 'onPoster':
      final pose = args['pose'] as List<Object?>;
      final camera = args['camera'] as List<Object?>;
      return ArPosterSeen(
        posterId: args['id'] as String,
        pose: [for (final v in pose) (v! as num).toDouble()],
        camera: Vec3(
          (camera[0]! as num).toDouble(),
          (camera[1]! as num).toDouble(),
          (camera[2]! as num).toDouble(),
        ),
      );
    case 'onTracking':
      return ArTrackingChanged(ArTracking.parse(args['state']));
    case 'onNearest':
      return ArNearestChanged(
        itemId: args['id'] as String,
        distance: number('distance'),
        bearing: number('bearing'),
        onScreen: args['onScreen'] as bool? ?? false,
      );
    case 'onItemTap':
      return ArItemTapped(
        itemId: args['id'] as String,
        distance: number('distance'),
      );
    case 'onSurfaceTap':
      return ArSurfaceTapped(
        position: Vec3(number('x'), number('y'), number('z')),
        onSurface: args['onSurface'] as bool,
      );
    case 'onInterrupted':
      return const ArInterrupted();
    case 'onError':
      return ArFailed(args['code'] as String? ?? 'unknown');
  }
  return null;
}
