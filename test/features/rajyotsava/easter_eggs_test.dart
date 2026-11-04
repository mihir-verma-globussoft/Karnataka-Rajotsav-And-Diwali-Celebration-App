import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/data/bundled_rajyotsava_content.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/data/easter_egg_collectibles.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/data/prefs_easter_egg_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/easter_eggs.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory store that keeps what was saved, like a device would.
class MemoryEggStore implements EasterEggStore {
  Map<String, Discovery> saved = {};
  var saves = 0;

  @override
  Future<Map<String, Discovery>> load() async => Map.of(saved);

  @override
  Future<void> save(Map<String, Discovery> discoveries) async {
    saves++;
    saved = Map.of(discoveries);
  }
}

ProviderContainer _container(MemoryEggStore store, {int seed = 1}) {
  final c = ProviderContainer(
    overrides: [
      easterEggStoreProvider.overrideWithValue(store),
      easterEggRandomProvider.overrideWithValue(Random(seed)),
      rajyotsavaClockProvider.overrideWithValue(() => DateTime(2026, 11, 4)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('collectibles', () {
    test('22 collectibles, unique stable ids, every category', () {
      expect(karnatakaCollectibles, hasLength(22));
      final ids = karnatakaCollectibles.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id, matches(RegExp(r'^[a-z_]+$')));
      }
      for (final category in EggCategory.values) {
        expect(
          karnatakaCollectibles.where((c) => c.category == category),
          isNotEmpty,
          reason: category.name,
        );
      }
    });

    test('every card has both sides filled in, in Kannada and English', () {
      for (final c in karnatakaCollectibles) {
        for (final text in [
          c.title,
          c.kannadaTitle,
          c.tagline,
          c.history,
          c.importance,
          c.kannadaDescription,
          c.englishDescription,
        ]) {
          expect(text.trim(), isNotEmpty, reason: c.id);
        }
        expect(c.facts, isNotEmpty, reason: c.id);
        expect(
          c.kannadaDescription,
          matches(RegExp('[ಀ-೿]')),
          reason: '${c.id}: Kannada script',
        );
      }
    });

    test('every photo key resolves to a credited photo on disk', () {
      final photos = bundledRajyotsavaContent.photos;
      for (final c in karnatakaCollectibles) {
        final asset = photos.byKey(c.photoKey);
        expect(asset, isNotNull, reason: '${c.id}: ${c.photoKey}');
        expect(File(asset!).existsSync(), isTrue, reason: asset);
        expect(photos.credits[asset], isNotNull, reason: asset);
      }
    });
  });

  group('pickUndiscovered', () {
    test('only picks collectibles not found yet', () {
      final found = {for (final c in karnatakaCollectibles.skip(1)) c.id};
      final pick = pickUndiscovered(karnatakaCollectibles, found, Random(3));
      expect(pick?.id, karnatakaCollectibles.first.id);
    });

    test('returns null when everything has been found', () {
      final all = {for (final c in karnatakaCollectibles) c.id};
      expect(pickUndiscovered(karnatakaCollectibles, all, Random(3)), isNull);
    });
  });

  group('EasterEggManager', () {
    test('reveals all 22 without a repeat, then the completion', () async {
      final store = MemoryEggStore();
      final c = _container(store);
      final manager = c.read(easterEggManagerProvider.notifier);
      final seen = <String>[];
      for (var i = 0; i < 22; i++) {
        final reveal = await manager.discover();
        expect(reveal, isA<NewCollectible>(), reason: 'discovery ${i + 1}');
        seen.add((reveal as NewCollectible).collectible.id);
      }
      expect(seen.toSet(), hasLength(22));
      expect(await manager.discover(), isA<CollectionComplete>());
      expect(store.saved, hasLength(22));
      expect(store.saves, 22, reason: 'saved after every discovery');
    });

    test('discoveries survive a restart and are not repeated', () async {
      final store = MemoryEggStore();
      final first = _container(store);
      final before = <String>{};
      for (var i = 0; i < 10; i++) {
        final r = await first
            .read(easterEggManagerProvider.notifier)
            .discover();
        before.add((r as NewCollectible).collectible.id);
      }

      // A fresh app run with the same saved data and a different seed.
      final second = _container(store, seed: 99);
      final manager = second.read(easterEggManagerProvider.notifier);
      expect(
        (await second.read(easterEggManagerProvider.future)).keys.toSet(),
        before,
      );
      for (var i = 0; i < 12; i++) {
        final r = await manager.discover();
        expect(before.contains((r as NewCollectible).collectible.id), isFalse);
      }
      expect(await manager.discover(), isA<CollectionComplete>());
    });

    test('simultaneous triggers reveal one collectible', () async {
      final store = MemoryEggStore();
      final manager = _container(store).read(easterEggManagerProvider.notifier);
      final reveals = await Future.wait([
        manager.discover(),
        manager.discover(),
        manager.discover(),
      ]);
      final ids = {
        for (final r in reveals) (r as NewCollectible).collectible.id,
      };
      expect(ids, hasLength(1));
      expect(store.saved, hasLength(1));
    });
  });

  group('PrefsEasterEggStore', () {
    test('round-trips discoveries', () async {
      SharedPreferences.setMockInitialValues({});
      const store = PrefsEasterEggStore();
      final at = DateTime.utc(2026, 11, 4, 10);
      await store.save({
        'hampi': Discovery(discoveredAt: at),
        'kuvempu': Discovery(discoveredAt: at, count: 3),
      });
      final loaded = await store.load();
      expect(loaded.keys, unorderedEquals(['hampi', 'kuvempu']));
      expect(loaded['kuvempu']!.count, 3);
      expect(loaded['hampi']!.discoveredAt, at);
    });

    test(
      'damaged data starts a fresh collection instead of crashing',
      () async {
        SharedPreferences.setMockInitialValues({
          'rajyotsava.easter_eggs.v1': '{not json',
        });
        expect(await const PrefsEasterEggStore().load(), isEmpty);
        SharedPreferences.setMockInitialValues({
          'rajyotsava.easter_eggs.v1': '{"hampi": {"at": "bad", "count": 1}}',
        });
        expect(await const PrefsEasterEggStore().load(), isEmpty);
      },
    );
  });
}
