import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/errors/app_failure.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/ar_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_scene.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_models.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_rules.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/poster_lock.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/presentation/state/place_notifier.dart';

import 'hunt_fakes.dart';

void main() {
  late FakeRepository repository;
  late FakeScene scene;
  late ProviderContainer container;
  late DateTime now;
  late PlaceNotifier notifier;

  PlaceViewState state() => container.read(placeProvider);

  void lockOn(String poster) {
    for (var i = 0; i < PosterLock.samplesNeeded; i++) {
      now = now.add(const Duration(milliseconds: 66));
      scene.emit(sighting(poster));
    }
  }

  const tappedTable = ArSurfaceTapped(
    position: Vec3(1.5, -0.4, 2),
    onSurface: true,
  );

  setUp(() {
    repository = FakeRepository();
    scene = FakeScene();
    container = ProviderContainer(
      overrides: [
        huntRepositoryProvider.overrideWithValue(repository),
        hapticsProvider.overrideWithValue(CountingHaptics()),
        pendingFindsProvider.overrideWithValue(FakePendingFinds()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(placeProvider, (_, _) {});
    now = DateTime(2026, 11, 4, 12);
    notifier = container.read(placeProvider.notifier)
      ..clock = (() => now)
      ..attach(scene)
      ..begin(
        HuntSnapshot(
          isAdmin: true,
          isActive: true,
          points: 0,
          items: [
            item('a1', hint: 'Old clue'),
            item('b1', zone: 'b'),
          ],
        ),
      );
  });

  test('locking on a poster shows only that zone', () {
    expect(state().scanning, isTrue);
    lockOn('a');
    expect(state().zone?.id, 'a');
    expect(scene.items.map((i) => i.id), ['a1']);
    expect(scene.origins.single, isNotNull);
  });

  test('tapping before a poster is locked places nothing', () {
    scene.emit(tappedTable);
    expect(state().draft, isNull);
  });

  test('another poster coming into view never changes the zone', () {
    lockOn('a');
    lockOn('b');
    expect(state().zone?.id, 'a');
    expect(scene.origins, hasLength(1));
  });

  test('a tap shows a preview immediately, and a new tap moves it', () {
    lockOn('a');
    scene.emit(tappedTable);
    expect(state().draft, isNotNull);
    expect(scene.items.map((i) => i.id), ['a1', 'draft']);
    expect(scene.items.last.x, 1.5);
    scene.emit(const ArSurfaceTapped(position: Vec3(3, 0, 0), onSurface: true));
    expect(scene.items.where((i) => i.id == 'draft'), hasLength(1));
    expect(scene.items.last.x, 3);
  });

  group('a tap that finds no surface', () {
    const missed = ArSurfaceTapped(position: Vec3(3, 0, 0), onSurface: false);

    test('still places it, in the air, and says so', () {
      lockOn('a');
      scene.emit(missed);
      expect(state().draft?.onSurface, isFalse);
      expect(scene.items.last.id, 'draft');
      expect(scene.items.last.x, 3);
    });

    test('can then be moved onto a surface', () {
      lockOn('a');
      scene.emit(missed);
      scene.emit(tappedTable);
      expect(state().draft?.onSurface, isTrue);
      expect(scene.items.where((i) => i.id == 'draft'), hasLength(1));
      expect(scene.items.last.x, 1.5);
    });

    test('can be saved where it floats', () async {
      lockOn('a');
      scene.emit(missed);
      await notifier.saveDraft('');
      expect(repository.placed.single.x, 3);
    });
  });

  group('making an item smaller', () {
    test('resizes the preview straight away', () {
      lockOn('a');
      scene.emit(tappedTable);
      expect(scene.items.last.scale, huntModelScale);
      notifier.setScale(0.5);
      expect(state().scale, 0.5);
      expect(scene.items.last.scale, 0.5 * huntModelScale);
    });

    test('leaves items already placed alone', () {
      lockOn('a');
      scene.emit(tappedTable);
      notifier.setScale(0.5);
      expect(scene.items.first.scale, huntModelScale);
    });

    test('is saved with the item', () async {
      lockOn('a');
      scene.emit(tappedTable);
      notifier.setScale(0.75);
      await notifier.saveDraft('');
      expect(repository.placed.single.scale, 0.75);
      expect(scene.items.last.scale, 0.75 * huntModelScale);
    });

    test('carries on to the next item, which is usually the same', () async {
      lockOn('a');
      scene.emit(tappedTable);
      notifier.setScale(0.75);
      await notifier.saveDraft('');
      scene.emit(tappedTable);
      expect(scene.items.last.id, 'draft');
      expect(scene.items.last.scale, 0.75 * huntModelScale);
    });
  });

  test('changing the kind updates the preview', () {
    lockOn('a');
    scene.emit(tappedTable);
    notifier.setKind(HuntItemKind.flag);
    expect(scene.items.last.kind, HuntItemKind.flag);
  });

  test('saving keeps the position relative to the poster', () async {
    lockOn('a');
    notifier.setKind(HuntItemKind.flag);
    scene.emit(tappedTable);
    await notifier.saveDraft('Behind the plant');
    final saved = repository.placed.single;
    expect(saved.zone, 'a');
    expect(saved.kind, HuntItemKind.flag);
    expect([saved.x, saved.y, saved.z], [1.5, -0.4, 2]);
    expect(saved.hint, 'Behind the plant');
    expect(state().draft, isNull);
    expect(state().items, hasLength(2));
    expect(scene.items.map((i) => i.id), ['a1', 'placed-0']);
    expect(state().message, contains('Saved'));
  });

  test('a failed save keeps the spot so nothing has to be redone', () async {
    repository.placeError = const NetworkFailure();
    lockOn('a');
    scene.emit(tappedTable);
    await notifier.saveDraft('');
    expect(state().draft, isNotNull);
    expect(state().saving, isFalse);
    expect(state().message, contains('connection'));
    expect(repository.placed, isEmpty);
  });

  test(
    'saving makes the hunt screen see the new item, not a stale list',
    () async {
      // What the server would actually return right now: the same items
      // PlaceNotifier was seeded with in setUp, before anything is placed.
      // Both PlaceNotifier and this read share `container`, exactly as the
      // placing screen and the hunt screen share one container in the app.
      repository.snapshot = HuntSnapshot(
        isAdmin: true,
        isActive: true,
        points: 0,
        items: [item('a1', hint: 'Old clue'), item('b1', zone: 'b')],
      );

      // The hunt screen loaded its snapshot before this item existed, just
      // like it would if the admin had the hub open before placing.
      final before = await container.read(huntSnapshotProvider.future);
      final beforeIds = before.items.map((i) => i.id).toSet();

      lockOn('a');
      scene.emit(tappedTable);
      await notifier.saveDraft('Behind the plant');

      // The place really did happen server-side; the fake just does not
      // simulate it, so the state the server would now return is set here.
      final saved = repository.placed.single;
      expect(beforeIds, isNot(contains(saved.id)));
      repository.snapshot = HuntSnapshot(
        isAdmin: true,
        isActive: true,
        points: 0,
        items: [...repository.snapshot.items, saved],
      );

      final after = await container.read(huntSnapshotProvider.future);
      expect(
        after.items.map((i) => i.id),
        contains(saved.id),
        reason: 'placing an item must not leave the hunt screen stale',
      );
    },
  );

  test('cancelling removes the preview', () {
    lockOn('a');
    scene.emit(tappedTable);
    notifier.cancelDraft();
    expect(state().draft, isNull);
    expect(scene.items.map((i) => i.id), ['a1']);
  });

  test('tapping a placed item selects it, and removing it works', () async {
    lockOn('a');
    scene.emit(const ArItemTapped(itemId: 'a1', distance: 1));
    expect(state().selected?.id, 'a1');
    await notifier.removeSelected();
    expect(repository.removed, ['a1']);
    expect(state().selected, isNull);
    expect(state().items, isEmpty);
    expect(scene.items, isEmpty);
  });

  test(
    'removing an item makes the hunt screen forget it, not a stale list',
    () async {
      // What the server would actually return right now: the same items
      // PlaceNotifier was seeded with in setUp, before anything is removed.
      // Both PlaceNotifier and this read share `container`, exactly as the
      // placing screen and the hunt screen share one container in the app.
      repository.snapshot = HuntSnapshot(
        isAdmin: true,
        isActive: true,
        points: 0,
        items: [item('a1', hint: 'Old clue'), item('b1', zone: 'b')],
      );

      // The hunt screen loaded its snapshot while 'a1' was still there, just
      // like it would if the admin had the hub open before removing it.
      final before = await container.read(huntSnapshotProvider.future);
      expect(before.items.map((i) => i.id), contains('a1'));

      lockOn('a');
      scene.emit(const ArItemTapped(itemId: 'a1', distance: 1));
      // The remove really did happen server-side; the fake just does not
      // simulate it, so the state the server would now return is set here.
      repository.snapshot = HuntSnapshot(
        isAdmin: true,
        isActive: true,
        points: 0,
        items: [item('b1', zone: 'b')],
      );
      await notifier.removeSelected();

      final after = await container.read(huntSnapshotProvider.future);
      expect(
        after.items.map((i) => i.id),
        isNot(contains('a1')),
        reason: 'removing an item must not leave the hunt screen stale',
      );
    },
  );

  test('tapping the preview itself is not treated as a placed item', () {
    lockOn('a');
    scene.emit(tappedTable);
    scene.emit(const ArItemTapped(itemId: 'draft', distance: 1));
    expect(state().selected, isNull);
    expect(state().draft, isNotNull);
  });

  test('choosing another poster clears the view for the next lock', () {
    lockOn('a');
    notifier.rescan();
    expect(state().scanning, isTrue);
    expect(scene.origins.last, isNull);
    expect(scene.items, isEmpty);
    lockOn('b');
    expect(state().zone?.id, 'b');
    expect(scene.items.map((i) => i.id), ['b1']);
  });

  test(
    'items placed this session are there when returning to a poster',
    () async {
      lockOn('a');
      scene.emit(tappedTable);
      await notifier.saveDraft('');
      notifier.rescan();
      lockOn('a');
      expect(scene.items.map((i) => i.id), ['a1', 'placed-0']);
    },
  );

  test('an interruption goes back to scanning', () {
    lockOn('a');
    scene.emit(const ArInterrupted());
    expect(state().scanning, isTrue);
    expect(state().message, contains('Scan the poster'));
  });
}
