import 'package:ar_hunt/app/demo/demo_hunt.dart';
import 'package:ar_hunt/app/providers.dart';
import 'package:ar_hunt/features/ar/ar_providers.dart';
import 'package:ar_hunt/features/ar/domain/ar_scene.dart';
import 'package:ar_hunt/features/ar/domain/hunt_models.dart';
import 'package:ar_hunt/features/ar/domain/hunt_repository.dart';
import 'package:ar_hunt/features/ar/domain/hunt_rules.dart';
import 'package:ar_hunt/features/ar/domain/poster_lock.dart';
import 'package:ar_hunt/features/ar/presentation/state/hunt_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hunt_fakes.dart';

void main() {
  late FakeRepository repository;
  late FakePendingFinds pending;
  late FakeScene scene;
  late CountingHaptics haptics;
  late ProviderContainer container;
  late DateTime now;
  late HuntNotifier notifier;

  HuntViewState state() => container.read(huntProvider);

  setUp(() {
    repository = FakeRepository();
    pending = FakePendingFinds();
    scene = FakeScene();
    haptics = CountingHaptics();
    container = ProviderContainer(
      overrides: [
        huntRepositoryProvider.overrideWithValue(repository),
        pendingFindsProvider.overrideWithValue(pending),
        huntSoundsProvider.overrideWithValue(SilentSounds()),
        hapticsProvider.overrideWithValue(haptics),
      ],
    );
    addTearDown(container.dispose);
    // Keeps the auto-dispose notifier alive for the whole test.
    container.listen(huntProvider, (_, _) {});
    now = DateTime(2026, 11, 4, 12);
    notifier = container.read(huntProvider.notifier)
      ..clock = (() => now)
      ..attach(scene);
  });

  void begin(List<HuntItem> items, {int points = 0}) => notifier.begin(
    HuntSnapshot(isAdmin: false, isActive: true, items: items, points: points),
  );

  void lockOn(String poster) {
    for (var i = 0; i < PosterLock.samplesNeeded; i++) {
      now = now.add(const Duration(milliseconds: 66));
      scene.emit(sighting(poster));
    }
  }

  ArNearestChanged near(String id, double metres, {bool onScreen = true}) =>
      ArNearestChanged(
        itemId: id,
        distance: metres,
        bearing: 0,
        onScreen: onScreen,
      );

  test('scanning a poster starts the hunt with only that zone', () {
    begin([item('a1'), item('a2', found: true), item('b1', zone: 'b')]);
    expect(state().phase, HuntPhase.scanning);
    expect(scene.origins, isEmpty);

    lockOn('a');

    expect(state().phase, HuntPhase.hunting);
    expect(state().zone?.id, 'a');
    expect(scene.origins.single, isNotNull);
    expect(scene.items.map((i) => i.id), [
      'a1',
    ], reason: 'found ones stay hidden');
    expect(state().leftHere, 1);
    expect(haptics.successes, 1);
    expect(state().message, contains('1 to find'));
  });

  test('progress climbs while the poster is being locked on', () {
    begin([item('a1')]);
    scene.emit(sighting('a'));
    expect(state().lockProgress, greaterThan(0));
    expect(state().phase, HuntPhase.scanning);
  });

  test('tells the player to move closer when too far away', () {
    begin([item('a1')]);
    scene.emit(sighting('a', cameraDistance: 5));
    expect(state().posterTooFar, isTrue);
    expect(state().lockProgress, 0);
  });

  test('ignores posters this version does not know', () {
    begin([item('a1')]);
    for (var i = 0; i < PosterLock.samplesNeeded; i++) {
      scene.emit(sighting('z'));
    }
    expect(state().phase, HuntPhase.scanning);
    expect(scene.origins, isEmpty);
  });

  test('walking to another poster switches zone', () {
    begin([item('a1'), item('b1', zone: 'b'), item('b2', zone: 'b')]);
    lockOn('a');
    now = now.add(const Duration(seconds: 2));
    lockOn('b');
    expect(state().zone?.id, 'b');
    expect(scene.items.map((i) => i.id), ['b1', 'b2']);
    expect(state().leftHere, 2);
    expect(state().message, contains('Start point B'));
  });

  test('a poster left in view does not keep moving everything', () {
    begin([item('a1')]);
    lockOn('a');
    lockOn('a');
    lockOn('a');
    expect(scene.origins, hasLength(1));
  });

  test('scanning the same poster later corrects drift quietly', () {
    begin([item('a1')]);
    lockOn('a');
    now = now.add(HuntNotifier.relockAfter + const Duration(seconds: 1));
    lockOn('a');
    expect(scene.origins, hasLength(2));
    expect(state().phase, HuntPhase.hunting);
    expect(haptics.successes, 1, reason: 'no fanfare for a correction');
  });

  test('the heat meter follows the nearest item', () {
    begin([item('a1', hint: 'By the printer')]);
    lockOn('a');
    scene.emit(near('a1', 20));
    expect(state().heat, HuntHeat.cold);
    expect(state().canCollect, isFalse);
    expect(state().nearestHint, 'By the printer');
    scene.emit(near('a1', 9));
    expect(state().heat, HuntHeat.warm);
    scene.emit(near('a1', huntVisibleRadiusMetres));
    expect(state().heat, HuntHeat.hot);
    scene.emit(near('a1', huntCollectRadiusMetres));
    expect(state().heat, HuntHeat.burning);
    expect(state().canCollect, isTrue);
  });

  test('a tap from far away asks the player to walk closer', () async {
    begin([item('a1')]);
    lockOn('a');
    scene.emit(const ArItemTapped(itemId: 'a1', distance: 5));
    await pumpEventQueue();
    expect(state().message, contains('Walk closer'));
    expect(repository.collected, isEmpty);
    expect(scene.celebrated, isEmpty);
    expect(state().foundCount, 0);
  });

  test('a close tap collects, celebrates and banks the points', () async {
    repository.collectResult = const CollectResult(
      points: 15,
      firstFinder: true,
      alreadyFound: false,
      isAdmin: false,
      totalPoints: 15,
    );
    begin([item('a1'), item('a2')]);
    lockOn('a');
    scene.emit(const ArItemTapped(itemId: 'a1', distance: 2));
    await pumpEventQueue();
    expect(repository.collected, ['a1']);
    expect(scene.celebrated, ['a1']);
    expect(state().points, 15);
    expect(state().foundCount, 1);
    expect(state().leftHere, 1);
    expect(state().message, contains('first to find'));
    expect(pending.ids, isEmpty);
  });

  test('a second tap on the same item does nothing', () async {
    begin([item('a1'), item('a2')]);
    lockOn('a');
    scene.emit(const ArItemTapped(itemId: 'a1', distance: 2));
    scene.emit(const ArItemTapped(itemId: 'a1', distance: 2));
    await pumpEventQueue();
    expect(repository.collected, ['a1']);
    expect(scene.celebrated, ['a1']);
    expect(state().foundCount, 1);
  });

  test('the button collects the nearest item', () async {
    begin([item('a1'), item('a2')]);
    lockOn('a');
    scene.emit(near('a2', 2));
    notifier.collectNearest();
    await pumpEventQueue();
    expect(repository.collected, ['a2']);
    expect(state().nearestId, isNull, reason: 'waits for the next report');
  });

  test('being close is not enough: the item must be in view', () async {
    begin([item('a1'), item('a2')]);
    lockOn('a');
    scene.emit(near('a1', 1, onScreen: false));
    expect(state().heat, HuntHeat.burning, reason: 'the meter still helps');
    expect(state().canCollect, isFalse);
    notifier.collectNearest();
    await pumpEventQueue();
    expect(repository.collected, isEmpty);
    expect(state().foundCount, 0);

    scene.emit(near('a1', 1));
    expect(state().canCollect, isTrue);
    notifier.collectNearest();
    await pumpEventQueue();
    expect(repository.collected, ['a1']);
  });

  test('in view but too far away cannot be collected', () {
    begin([item('a1')]);
    lockOn('a');
    scene.emit(near('a1', huntCollectRadiusMetres + 1));
    expect(state().canCollect, isFalse);
  });

  test('the button does nothing when nothing is in reach', () async {
    begin([item('a1')]);
    lockOn('a');
    scene.emit(near('a1', 9));
    notifier.collectNearest();
    await pumpEventQueue();
    expect(repository.collected, isEmpty);
  });

  test('offline finds are kept on the phone, never lost', () async {
    repository.collectError = offline;
    begin([item('a1'), item('a2')], points: 20);
    lockOn('a');
    scene.emit(const ArItemTapped(itemId: 'a1', distance: 2));
    await pumpEventQueue();
    expect(pending.ids, ['a1']);
    expect(state().foundCount, 1);
    expect(state().points, 20, reason: 'not claimed until the server agrees');
    expect(state().message, contains('once you are online'));
  });

  test('a too-quick find is kept for later as well', () async {
    repository.collectError = const HuntTooFastException();
    begin([item('a1'), item('a2')]);
    lockOn('a');
    scene.emit(const ArItemTapped(itemId: 'a1', distance: 2));
    await pumpEventQueue();
    expect(pending.ids, ['a1']);
  });

  test('a removed item or closed hunt is not kept', () async {
    begin([item('a1'), item('a2'), item('a3')]);
    lockOn('a');
    repository.collectError = const HuntItemGoneException();
    scene.emit(const ArItemTapped(itemId: 'a1', distance: 2));
    await pumpEventQueue();
    expect(state().message, contains('removed'));
    repository.collectError = const HuntClosedException();
    scene.emit(const ArItemTapped(itemId: 'a2', distance: 2));
    await pumpEventQueue();
    expect(state().message, contains('closed'));
    expect(pending.ids, isEmpty);
  });

  test('admins are told their finds do not score', () async {
    repository.collectResult = const CollectResult(
      points: 0,
      firstFinder: false,
      alreadyFound: false,
      isAdmin: true,
      totalPoints: 0,
    );
    begin([item('a1'), item('a2')], points: 5);
    lockOn('a');
    scene.emit(const ArItemTapped(itemId: 'a1', distance: 2));
    await pumpEventQueue();
    expect(state().message, contains('Admins do not score'));
    expect(state().points, 5);
  });

  test('finding the last item finishes the hunt', () async {
    begin([item('a1'), item('b1', zone: 'b', found: true)]);
    lockOn('a');
    scene.emit(const ArItemTapped(itemId: 'a1', distance: 2));
    await pumpEventQueue();
    expect(state().phase, HuntPhase.finished);
  });

  test('a player with nothing left starts on the finished screen', () {
    begin([item('a1', found: true)]);
    expect(state().phase, HuntPhase.finished);
  });

  test('all found here points to where there is more', () {
    begin([item('a1', found: true), item('c1', zone: 'c')]);
    lockOn('a');
    expect(state().message, contains('Start point C'));
    expect(state().leftHere, 0);
  });

  test('the next start point skips zones cleared during this hunt', () async {
    begin([item('a1'), item('b1', zone: 'b'), item('c1', zone: 'c')]);
    lockOn('a');
    expect(notifier.nextZone()?.id, 'b');
    now = now.add(const Duration(seconds: 2));
    lockOn('b');
    scene.emit(const ArItemTapped(itemId: 'b1', distance: 1));
    await pumpEventQueue();
    // Back at A: B is cleared now, even though the hub's copy says otherwise.
    now = now.add(const Duration(seconds: 2));
    lockOn('a');
    expect(notifier.nextZone()?.id, 'c');
  });

  test('an interruption goes back to scanning and clears the origin', () {
    begin([item('a1')]);
    lockOn('a');
    scene.emit(near('a1', 2));
    scene.emit(const ArInterrupted());
    expect(state().phase, HuntPhase.scanning);
    expect(scene.origins.last, isNull);
    expect(state().nearestId, isNull);
    expect(state().message, contains('Scan a poster'));
  });

  test('scanning again from the button lines things back up', () {
    begin([item('a1')]);
    lockOn('a');
    notifier.rescan();
    expect(state().phase, HuntPhase.scanning);
    lockOn('a');
    expect(state().phase, HuntPhase.hunting);
    expect(scene.origins.whereType<ArOrigin>(), hasLength(2));
  });

  test('tracking problems and failures reach the screen', () {
    begin([item('a1')]);
    scene.emit(const ArTrackingChanged(ArTracking.tooDark));
    expect(state().tracking, ArTracking.tooDark);
    scene.emit(const ArFailed('camera_unavailable'));
    expect(state().failure, 'camera_unavailable');
  });

  test('leaving stops the camera', () async {
    begin([item('a1')]);
    container.dispose();
    await pumpEventQueue();
    expect(scene.disposed, isTrue);
  });

  test('demo mode scores like the server and never scores twice', () async {
    final demo = DemoHuntRepository();
    final placed = await demo.placeItem(
      zone: 'a',
      kind: HuntItemKind.flag,
      x: 1,
      y: 0,
      z: 0,
      hint: '  ',
    );
    expect(placed.hint, isNull);
    expect((await demo.collect(placed.id)).points, 15);
    final again = await demo.collect(placed.id);
    expect(again.alreadyFound, isTrue);
    expect(again.totalPoints, 15);
    final state = await demo.load();
    expect(state.foundCount, 1);
    expect((await demo.leaders()).first.username, 'You');
    await demo.removeItem(placed.id);
    expect((await demo.load()).items, isEmpty);
  });

  group('sending saved finds', () {
    test('clears what the server accepts or can never accept', () async {
      pending.ids.addAll(['ok', 'gone']);
      final repo = _ScriptedRepository({'gone': const HuntItemGoneException()});
      await syncPendingFinds(repo, pending);
      expect(pending.ids, isEmpty);
      expect(repo.collected, ['ok']);
    });

    test('stops at the first network error, keeping the rest', () async {
      pending.ids.addAll(['a', 'b']);
      await syncPendingFinds(_ScriptedRepository({'a': offline}), pending);
      expect(pending.ids, ['a', 'b']);
    });

    test('keeps a too-quick find and carries on', () async {
      pending.ids.addAll(['a', 'b']);
      final repo = _ScriptedRepository({'a': const HuntTooFastException()});
      await syncPendingFinds(repo, pending);
      expect(pending.ids, ['a']);
      expect(repo.collected, ['b']);
    });
  });
}

class _ScriptedRepository extends FakeRepository {
  _ScriptedRepository(this.errors);

  final Map<String, Object> errors;

  @override
  Future<CollectResult> collect(String itemId) async {
    final error = errors[itemId];
    if (error != null) throw error;
    return super.collect(itemId);
  }
}
