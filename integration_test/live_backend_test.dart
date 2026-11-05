import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/errors/app_failure.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/data/hunt_connection.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/data/supabase_hunt_repository.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_models.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// The real connection and repository against the game's real database. Off by
/// default, as each run creates a player called "Live Test":
///
///     flutter test integration_test/live_backend_test.dart -d <device> \
///       --dart-define=HUNT_LIVE=true
///
/// Add `--dart-define=HUNT_TEST_PIN=...` to test the admin tools as well.
const _live = bool.fromEnvironment('HUNT_LIVE');
const _pin = String.fromEnvironment('HUNT_TEST_PIN');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late HuntRepository repository;

  setUpAll(() {
    if (!_live) return;
    final hunt = SupabaseClient(huntDatabaseUrl, huntDatabaseKey);
    // A new id each run, so it never reuses a saved player on this device.
    final id = 'live-test-${DateTime.now().millisecondsSinceEpoch}';
    final connection = HuntConnection(hunt, _LivePlayer(id));
    repository = SupabaseHuntRepository(hunt, ready: connection.ready);
  });

  testWidgets('a main app player gets a game player, and the rules hold', (
    tester,
  ) async {
    if (!_live) return;
    final snapshot = await repository.load();
    expect(repository.currentUserId, isNotNull);
    expect(snapshot.isActive, isTrue);
    expect(snapshot.isAdmin, isFalse);
    await repository.leaders();

    await expectLater(
      repository.placeItem(
        zone: 'a',
        kind: HuntItemKind.diya,
        x: 0,
        y: 0,
        z: 0,
      ),
      throwsA(
        isA<UnexpectedFailure>().having(
          (failure) => failure.message,
          'message',
          contains('admins'),
        ),
      ),
    );
    expect(await repository.unlockAdmin('000000'), isFalse);
    await expectLater(
      repository.collect('00000000-0000-0000-0000-000000000000'),
      throwsA(isA<HuntItemGoneException>()),
    );
  });

  testWidgets('with the PIN: unlock, place, test a find, remove', (
    tester,
  ) async {
    if (!_live || _pin.isEmpty) return;
    expect(await repository.unlockAdmin(_pin), isTrue);
    final placed = await repository.placeItem(
      zone: 'd',
      kind: HuntItemKind.flag,
      x: 1.25,
      y: -0.5,
      z: 2,
      hint: 'Live test item',
    );
    addTearDown(() => repository.removeItem(placed.id));
    final find = await repository.collect(placed.id);
    expect(find.isAdmin, isTrue);
    expect(find.points, 0, reason: 'admins never score');
  });
}

class _LivePlayer implements HuntPlayerSource {
  const _LivePlayer(this.currentId);

  @override
  final String currentId;

  @override
  Future<String> name() async => 'Live Test';
}
