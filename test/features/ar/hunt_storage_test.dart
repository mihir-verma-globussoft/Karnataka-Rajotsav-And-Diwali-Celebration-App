import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/errors/app_failure.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/ar_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/data/prefs_pending_finds_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hunt_fakes.dart';

void main() {
  group('finds saved on the phone', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('are kept across restarts of the store', () async {
      await const PrefsPendingFindsStore('me').add('a');
      await const PrefsPendingFindsStore('me').add('b');
      expect(await const PrefsPendingFindsStore('me').load(), ['a', 'b']);
    });

    test('are not added twice', () async {
      const store = PrefsPendingFindsStore('me');
      await store.add('a');
      await store.add('a');
      expect(await store.load(), ['a']);
    });

    test('can be removed one at a time', () async {
      const store = PrefsPendingFindsStore('me');
      await store.add('a');
      await store.add('b');
      await store.remove('a');
      expect(await store.load(), ['b']);
      await store.remove('not there');
      expect(await store.load(), ['b']);
    });

    test('never mix between players on a shared phone', () async {
      await const PrefsPendingFindsStore('asha').add('a');
      expect(await const PrefsPendingFindsStore('ravi').load(), isEmpty);
    });

    test('start empty', () async {
      expect(await const PrefsPendingFindsStore('new').load(), isEmpty);
    });
  });

  group('what the hub loads', () {
    late FakeRepository repository;
    late FakePendingFinds pending;
    late ProviderContainer container;

    setUp(() {
      repository = FakeRepository(
        snapshot: HuntSnapshot(
          isAdmin: false,
          isActive: true,
          points: 25,
          rank: 2,
          items: [item('a1'), item('a2')],
        ),
      );
      pending = FakePendingFinds();
      container = ProviderContainer(
        overrides: [
          huntRepositoryProvider.overrideWithValue(repository),
          pendingFindsProvider.overrideWithValue(pending),
        ],
      );
      addTearDown(container.dispose);
    });

    Future<HuntSnapshot> load() async {
      final subscription = container.listen(
        huntSnapshotProvider.future,
        (_, _) {},
      );
      addTearDown(subscription.close);
      return subscription.read();
    }

    test('passes the server state through', () async {
      final snapshot = await load();
      expect(snapshot.points, 25);
      expect(snapshot.rank, 2);
      expect(snapshot.foundCount, 0);
    });

    test('sends saved finds before loading', () async {
      pending.ids.add('a1');
      await load();
      expect(repository.collected, ['a1']);
      expect(pending.ids, isEmpty);
    });

    test('still counts a find as found while it cannot be sent', () async {
      pending.ids.add('a2');
      repository.collectError = offline;
      final snapshot = await load();
      expect(pending.ids, ['a2'], reason: 'kept until the server has it');
      expect(
        snapshot.items.firstWhere((candidate) => candidate.id == 'a2').found,
        isTrue,
      );
      expect(
        snapshot.items.firstWhere((candidate) => candidate.id == 'a1').found,
        isFalse,
      );
    });

    test('reports when the server cannot be reached', () async {
      final failing = _FailingRepository();
      final broken = ProviderContainer(
        overrides: [
          huntRepositoryProvider.overrideWithValue(failing),
          pendingFindsProvider.overrideWithValue(pending),
        ],
      );
      addTearDown(broken.dispose);
      final subscription = broken.listen(
        huntSnapshotProvider.future,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await expectLater(subscription.read(), throwsA(isA<NetworkFailure>()));
    });
  });
}

class _FailingRepository extends FakeRepository {
  @override
  Future<HuntSnapshot> load() async => throw const NetworkFailure();
}
