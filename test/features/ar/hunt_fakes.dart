import 'dart:async';

import 'package:rajotsav_and_diwali_celebration_app/core/errors/app_failure.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/haptics/app_haptics.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_availability.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_platform.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_scene.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_models.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_repository.dart';

class FakeArPlatform implements ArPlatform {
  FakeArPlatform([this.answer = ArAvailability.supported]);

  ArAvailability answer;

  @override
  Future<ArAvailability> checkAvailability() async => answer;

  @override
  Future<ArAvailability> prepare() async => answer;

  @override
  Future<void> openSettings() async {}
}

class FakeScene implements ArSceneController {
  final _events = StreamController<ArSceneEvent>.broadcast(sync: true);
  final origins = <ArOrigin?>[];
  final celebrated = <String>[];
  final taps = <List<double>>[];
  List<ArSceneItem> items = const [];
  bool disposed = false;

  void emit(ArSceneEvent event) => _events.add(event);

  @override
  Stream<ArSceneEvent> get events => _events.stream;

  @override
  Future<void> setOrigin(ArOrigin? origin) async => origins.add(origin);

  @override
  Future<void> setItems(List<ArSceneItem> items) async => this.items = items;

  @override
  Future<void> celebrate(String itemId) async => celebrated.add(itemId);

  @override
  Future<void> tap(double x, double y) async => taps.add([x, y]);

  @override
  Future<void> dispose() async => disposed = true;
}

class FakeRepository implements HuntRepository {
  FakeRepository({this.snapshot = emptySnapshot, this.leaderRows = const []});

  static const emptySnapshot = HuntSnapshot(
    isAdmin: false,
    isActive: true,
    items: [],
    points: 0,
  );

  HuntSnapshot snapshot;
  List<HuntLeader> leaderRows;

  /// Thrown by [collect] when set, as the server would.
  Object? collectError;
  CollectResult collectResult = const CollectResult(
    points: 10,
    firstFinder: false,
    alreadyFound: false,
    isAdmin: false,
    totalPoints: 10,
  );
  Object? placeError;
  final collected = <String>[];
  final removed = <String>[];
  final placed = <HuntItem>[];

  @override
  String? get currentUserId => 'me';

  @override
  Future<HuntSnapshot> load() async => snapshot;

  @override
  Future<List<HuntLeader>> leaders({int limit = 50}) async => leaderRows;

  @override
  Future<CollectResult> collect(String itemId) async {
    final error = collectError;
    if (error != null) throw error;
    collected.add(itemId);
    return collectResult;
  }

  @override
  Future<HuntItem> placeItem({
    required String zone,
    required HuntItemKind kind,
    required double x,
    required double y,
    required double z,
    String? hint,
    double scale = 1,
  }) async {
    final error = placeError;
    if (error != null) throw error;
    final item = HuntItem(
      id: 'placed-${placed.length}',
      zone: zone,
      kind: kind,
      x: x,
      y: y,
      z: z,
      hint: hint,
      scale: scale,
    );
    placed.add(item);
    return item;
  }

  /// The PIN [unlockAdmin] accepts. A right one makes this player an admin.
  String adminPin = '123456';

  @override
  Future<bool> unlockAdmin(String pin) async {
    if (pin != adminPin) return false;
    snapshot = HuntSnapshot(
      isAdmin: true,
      isActive: snapshot.isActive,
      items: snapshot.items,
      points: snapshot.points,
      rank: snapshot.rank,
    );
    return true;
  }

  @override
  Future<void> removeItem(String itemId) async => removed.add(itemId);
}

class FakePendingFinds implements PendingFindsStore {
  final ids = <String>[];

  @override
  Future<List<String>> load() async => List.of(ids);

  @override
  Future<void> add(String itemId) async {
    if (!ids.contains(itemId)) ids.add(itemId);
  }

  @override
  Future<void> remove(String itemId) async => ids.remove(itemId);
}

class SilentSounds implements HuntSounds {
  @override
  Future<void> found() async {}

  @override
  Future<void> allFound() async {}

  @override
  Future<void> startMusic() async {}

  @override
  Future<void> stopMusic() async {}
}

class CountingSounds extends SilentSounds {
  int musicStarts = 0;
  bool playing = false;

  @override
  Future<void> startMusic() async {
    musicStarts++;
    playing = true;
  }

  @override
  Future<void> stopMusic() async => playing = false;
}

class CountingHaptics extends SilentHaptics {
  int successes = 0;

  @override
  Future<void> success() async => successes++;
}

/// A poster on a wall in front of the camera, facing it. The world looks along
/// -Z, so the camera sits at +Z. Pose columns: +X right across the image, +Y
/// out of it, +Z down it.
ArPosterSeen sighting(String id, {double cameraDistance = 1}) => ArPosterSeen(
  posterId: id,
  pose: const [
    1, 0, 0, 0, //
    0, 0, 1, 0, //
    0, -1, 0, 0, //
    2, 1, -3, 1, //
  ],
  camera: Vec3(2, 1, -3 + cameraDistance),
);

const offline = NetworkFailure();

HuntItem item(
  String id, {
  String zone = 'a',
  HuntItemKind kind = HuntItemKind.diya,
  bool found = false,
  String? hint,
  double scale = 1,
}) => HuntItem(
  id: id,
  zone: zone,
  kind: kind,
  x: 1,
  y: 0,
  z: 2,
  found: found,
  hint: hint,
  scale: scale,
);
