import 'dart:async';

import 'package:ar_hunt/app/app.dart';
import 'package:ar_hunt/app/auth/hunt_auth.dart';
import 'package:ar_hunt/app/feature_module.dart';
import 'package:ar_hunt/app/providers.dart';
import 'package:ar_hunt/core/config/app_config.dart';
import 'package:ar_hunt/core/theme/app_tokens.dart';
import 'package:ar_hunt/features/ar/ar_feature.dart';
import 'package:ar_hunt/features/ar/ar_providers.dart';
import 'package:ar_hunt/features/ar/domain/ar_scene.dart';
import 'package:ar_hunt/features/ar/domain/hunt_models.dart';
import 'package:ar_hunt/features/ar/domain/hunt_repository.dart';
import 'package:ar_hunt/features/ar/domain/poster_lock.dart';
import 'package:ar_hunt/features/ar/presentation/widgets/ar_camera_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session, User;

import '../test/features/ar/hunt_fakes.dart';

/// The whole game, through the real screens and navigation, on a real device or
/// simulator. The camera and server are stand-ins, so it can run anywhere:
///
///     flutter test integration_test/hunt_flow_test.dart -d <device>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final session = Session(
    accessToken: 'test',
    tokenType: 'bearer',
    user: const User(
      id: 'me',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-11-04T00:00:00Z',
    ),
  );

  late FakeScene scene;
  late _MemoryRepository repository;
  late _FakeAuth auth;

  Future<void> start(WidgetTester tester, {required bool adminBuild}) async {
    scene = FakeScene();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(environment: AppEnvironment.dev),
          ),
          featureModulesProvider.overrideWithValue([
            ArFeature(adminTools: adminBuild),
          ]),
          huntAdminToolsProvider.overrideWithValue(adminBuild),
          huntAuthProvider.overrideWithValue(auth),
          huntRepositoryProvider.overrideWithValue(repository),
          pendingFindsProvider.overrideWithValue(FakePendingFinds()),
          huntSoundsProvider.overrideWithValue(SilentSounds()),
          arPlatformProvider.overrideWithValue(FakeArPlatform()),
          arSceneFactoryProvider.overrideWithValue((_) => scene),
          arCameraBuilderProvider.overrideWithValue((_, onCreated) {
            scheduleMicrotask(() => onCreated(1));
            return const ColoredBox(color: AppColors.ink);
          }),
        ],
        child: const App(),
      ),
    );
  }

  /// Waits for something to appear, as a person would.
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Never appeared: $finder');
  }

  Future<void> tapWhenReady(WidgetTester tester, Finder finder) async {
    await waitFor(tester, finder);
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> holdPosterInView(WidgetTester tester, String poster) async {
    // Some real time passes between each, as it does with a real camera.
    for (var i = 0; i < PosterLock.samplesNeeded; i++) {
      scene.emit(sighting(poster));
      await tester.pump(const Duration(milliseconds: 30));
    }
    scene.emit(const ArTrackingChanged(ArTracking.normal));
    await tester.pump(const Duration(milliseconds: 100));
  }

  setUp(() {
    auth = _FakeAuth(session);
    repository = _MemoryRepository();
  });
  tearDown(() => auth.close());

  testWidgets(
    'a player joins with a name, hunts, collects and sees the leaderboard',
    (tester) async {
      await repository.placeItem(
        zone: 'a',
        kind: HuntItemKind.diya,
        x: 1,
        y: 0,
        z: 1,
        hint: 'Near the coffee machine',
      );
      await repository.placeItem(
        zone: 'b',
        kind: HuntItemKind.flag,
        x: 1,
        y: 0,
        z: 1,
      );

      await start(tester, adminBuild: false);

      // No account or password, just a name.
      await waitFor(tester, find.byKey(const ValueKey('join-name')));
      await tester.enterText(find.byKey(const ValueKey('join-name')), 'Sharuk');
      await tapWhenReady(tester, find.byKey(const ValueKey('join')));
      expect(auth.joined, ['Sharuk']);

      // The user build has no way into the admin tools.
      await waitFor(tester, find.byKey(const ValueKey('start-hunting')));
      expect(find.text('Admin'), findsNothing);
      await tapWhenReady(tester, find.byKey(const ValueKey('start-hunting')));

      // Nothing shows until a poster is locked on.
      await waitFor(tester, find.textContaining('Posters look like these'));
      expect(scene.origins, isEmpty);
      await holdPosterInView(tester, 'a');
      expect(scene.origins.single, isNotNull);
      expect(scene.items.map((i) => i.kind), [HuntItemKind.diya]);

      // Close but not looking at it: not found yet, so no way to claim it.
      final itemId = scene.items.single.id;
      scene.emit(
        ArNearestChanged(
          itemId: itemId,
          distance: 1,
          bearing: 3,
          onScreen: false,
        ),
      );
      await waitFor(tester, find.text('Right here!'));
      expect(find.textContaining('Clue: Near the coffee'), findsOneWidget);
      expect(find.byKey(const ValueKey('collect-nearest')), findsNothing);

      // Looking at it: now it can be collected.
      scene.emit(
        ArNearestChanged(
          itemId: itemId,
          distance: 1,
          bearing: 0,
          onScreen: true,
        ),
      );
      await tapWhenReady(tester, find.byKey(const ValueKey('collect-nearest')));
      await waitFor(tester, find.textContaining('first to find'));
      expect(repository.found, [itemId]);
      expect(scene.celebrated, [itemId]);
      expect(find.text('15 pts'), findsOneWidget);

      // Nothing left here: it points to the next start point.
      await waitFor(tester, find.textContaining('Start point B'));

      // Back on the hub, the score and leaderboard have caught up.
      await tapWhenReady(tester, find.byTooltip('Leave the hunt'));
      await waitFor(tester, find.text('15 points'));
      await waitFor(tester, find.textContaining('Sharuk (you)'));
    },
  );

  testWidgets(
    'the organiser unlocks with a PIN, places an item, and it reaches players',
    (tester) async {
      auth.signedIn = session;
      await start(tester, adminBuild: true);

      // A wrong PIN changes nothing.
      await waitFor(tester, find.byKey(const ValueKey('admin-unlock')));
      Future<void> enterPin(String pin) async {
        await tapWhenReady(tester, find.byKey(const ValueKey('admin-unlock')));
        await waitFor(tester, find.byKey(const ValueKey('admin-pin')));
        await tester.enterText(find.byKey(const ValueKey('admin-pin')), pin);
        await tapWhenReady(
          tester,
          find.byKey(const ValueKey('admin-pin-submit')),
        );
      }

      await enterPin('000000');
      await waitFor(tester, find.textContaining('PIN is not right'));
      expect(find.byKey(const ValueKey('admin-place')), findsNothing);
      await tester.pump(const Duration(seconds: 5));

      await enterPin('123456');
      await tapWhenReady(tester, find.byKey(const ValueKey('admin-place')));

      // Locks on a poster, taps a table, and saves with a clue.
      await waitFor(tester, find.textContaining('saved against this poster'));
      await holdPosterInView(tester, 'c');
      await waitFor(tester, find.textContaining('Start point C'));
      await tester.tapAt(const Offset(150, 200));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scene.taps, isNotEmpty, reason: 'taps reach the AR view');

      scene.emit(
        const ArSurfaceTapped(position: Vec3(1.5, -0.4, 2), onSurface: true),
      );
      await waitFor(tester, find.byKey(const ValueKey('save-draft')));
      expect(scene.items.single.id, 'draft', reason: 'a preview shows at once');
      await tester.enterText(find.byType(TextField), 'Behind the plant');
      await tapWhenReady(tester, find.byKey(const ValueKey('save-draft')));
      await waitFor(tester, find.textContaining('Players can find it now'));

      final saved = repository.items.single;
      expect(saved.zone, 'c');
      expect([saved.x, saved.y, saved.z], [1.5, -0.4, 2]);
      expect(saved.hint, 'Behind the plant');
      expect(scene.items.single.id, saved.id);

      // It is now in the admin's list, and can be removed from there.
      await tapWhenReady(tester, find.byTooltip('Finish placing'));
      await tapWhenReady(tester, find.byKey(const ValueKey('admin-items')));
      await waitFor(tester, find.text('Behind the plant'));
      await tapWhenReady(tester, find.byTooltip('Remove this diya'));
      await tapWhenReady(tester, find.text('Remove'));
      await waitFor(tester, find.text('Nothing placed yet.'));
      expect(repository.items, isEmpty);
    },
  );

  testWidgets('a lost connection on the hub offers a way to try again', (
    tester,
  ) async {
    auth.signedIn = session;
    repository.failLoad = true;
    await start(tester, adminBuild: false);
    await waitFor(tester, find.text('Retry'));
    expect(find.textContaining('connection'), findsOneWidget);

    repository.failLoad = false;
    await tapWhenReady(tester, find.text('Retry'));
    await waitFor(tester, find.textContaining('Nothing has been hidden'));
  });
}

class _FakeAuth extends HuntAuth {
  _FakeAuth(this._session)
    : super(const AppConfig(environment: AppEnvironment.dev));

  final Session _session;
  final _sessions = StreamController<Session?>.broadcast();
  final joined = <String>[];
  Session? signedIn;

  @override
  Stream<Session?> watchSession() async* {
    yield signedIn;
    yield* _sessions.stream;
  }

  @override
  Future<void> join(String name) async {
    joined.add(name.trim());
    signedIn = _session;
    _sessions.add(_session);
  }

  Future<void> close() => _sessions.close();
}

/// Behaves like the server, keeping state between screens.
class _MemoryRepository implements HuntRepository {
  final items = <HuntItem>[];
  final found = <String>[];
  bool isAdmin = false;
  bool failLoad = false;
  int _points = 0;
  int _next = 0;

  @override
  String? get currentUserId => 'me';

  @override
  Future<HuntSnapshot> load() async {
    if (failLoad) throw offline;
    return HuntSnapshot(
      isAdmin: isAdmin,
      isActive: true,
      points: _points,
      rank: _points == 0 ? null : 1,
      items: [
        for (final item in items) item.copyWith(found: found.contains(item.id)),
      ],
    );
  }

  @override
  Future<List<HuntLeader>> leaders({int limit = 50}) async => [
    if (_points > 0)
      HuntLeader(rank: 1, userId: 'me', username: 'Sharuk', points: _points),
  ];

  @override
  Future<CollectResult> collect(String itemId) async {
    found.add(itemId);
    _points += 15;
    return CollectResult(
      points: 15,
      firstFinder: true,
      alreadyFound: false,
      isAdmin: false,
      totalPoints: _points,
    );
  }

  @override
  Future<bool> unlockAdmin(String pin) async {
    if (pin != '123456') return false;
    isAdmin = true;
    return true;
  }

  @override
  Future<HuntItem> placeItem({
    required String zone,
    required HuntItemKind kind,
    required double x,
    required double y,
    required double z,
    String? hint,
  }) async {
    final item = HuntItem(
      id: 'item-${_next++}',
      zone: zone,
      kind: kind,
      x: x,
      y: y,
      z: z,
      hint: hint,
    );
    items.add(item);
    return item;
  }

  @override
  Future<void> removeItem(String itemId) async =>
      items.removeWhere((item) => item.id == itemId);
}
