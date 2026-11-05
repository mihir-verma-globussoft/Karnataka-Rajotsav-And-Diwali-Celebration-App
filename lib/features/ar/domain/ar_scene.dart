import 'dart:math' as math;

import 'hunt_models.dart';
import 'hunt_rules.dart';

/// The native view registered by `ArChannel.kt` and `AppDelegate.swift`.
const arViewType = 'festival_app/ar_view';

class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

/// Where a zone's coordinates start, in the AR session's world: a position
/// plus a turn around the vertical axis. See `poster_lock.dart`.
class ArOrigin {
  const ArOrigin({required this.position, required this.yaw});

  final Vec3 position;

  /// Radians. Zero means the poster faces along the world's +Z axis.
  final double yaw;
}

/// One thing for the native view to draw.
class ArSceneItem {
  const ArSceneItem({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    required this.z,
    this.scale = huntModelScale,
  });

  factory ArSceneItem.of(HuntItem item) => ArSceneItem(
    id: item.id,
    kind: item.kind,
    x: item.x,
    y: item.y,
    z: item.z,
    scale: item.scale * huntModelScale,
  );

  final String id;
  final HuntItemKind kind;
  final double x;
  final double y;
  final double z;

  /// How much to multiply the model by.
  final double scale;

  /// Radians around the origin's vertical axis. Items stay turned towards their
  /// poster, where players start, instead of following the camera: anything
  /// that turns as you walk around it does not look fixed in the room.
  double get yaw => math.atan2(-x, -z);
}

enum ArTracking {
  normal,
  initializing,
  tooFast,
  tooDark,
  lowDetail,
  unavailable;

  static ArTracking parse(Object? wire) => values.firstWhere(
    (value) => value.name == wire,
    orElse: () => ArTracking.unavailable,
  );
}

sealed class ArSceneEvent {
  const ArSceneEvent();
}

/// The camera can see a poster right now.
class ArPosterSeen extends ArSceneEvent {
  const ArPosterSeen({
    required this.posterId,
    required this.pose,
    required this.camera,
  });

  final String posterId;

  /// The poster's pose in the world: 16 values, column by column. On both
  /// platforms +X runs left to right across the image and +Z top to bottom.
  final List<double> pose;
  final Vec3 camera;
}

class ArTrackingChanged extends ArSceneEvent {
  const ArTrackingChanged(this.tracking);

  final ArTracking tracking;
}

/// The closest item that is drawn, reported a couple of times a second.
class ArNearestChanged extends ArSceneEvent {
  const ArNearestChanged({
    required this.itemId,
    required this.distance,
    required this.bearing,
    required this.onScreen,
  });

  final String itemId;

  /// Metres from the camera.
  final double distance;

  /// Radians from straight ahead; positive is to the player's right.
  final double bearing;

  /// Drawn and inside the camera view right now, so the player can see it.
  final bool onScreen;
}

class ArItemTapped extends ArSceneEvent {
  const ArItemTapped({required this.itemId, required this.distance});

  final String itemId;
  final double distance;
}

/// A tap away from any item.
class ArSurfaceTapped extends ArSceneEvent {
  const ArSurfaceTapped({required this.position, required this.onSurface});

  /// Metres from the current origin.
  final Vec3 position;

  /// False when no real surface was found and the point floats in front of
  /// the camera instead.
  final bool onSurface;
}

/// The session was paused (app left, call came in), so the world may have
/// shifted and the player should scan a poster again.
class ArInterrupted extends ArSceneEvent {
  const ArInterrupted();
}

class ArFailed extends ArSceneEvent {
  const ArFailed(this.code);

  final String code;
}

abstract interface class ArSceneController {
  Stream<ArSceneEvent> get events;

  /// Null hides everything until the next poster is scanned.
  Future<void> setOrigin(ArOrigin? origin);

  Future<void> setItems(List<ArSceneItem> items);

  /// Plays the found effect and removes the item from the scene.
  Future<void> celebrate(String itemId);

  /// A tap in logical pixels from the view's top-left corner.
  Future<void> tap(double x, double y);

  /// Stops the camera. Safe to call more than once.
  Future<void> dispose();
}
