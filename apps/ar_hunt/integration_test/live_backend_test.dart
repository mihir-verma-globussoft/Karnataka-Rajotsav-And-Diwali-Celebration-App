import 'package:ar_hunt/app/auth/hunt_auth.dart';
import 'package:ar_hunt/core/config/app_config.dart';
import 'package:ar_hunt/core/errors/app_failure.dart';
import 'package:ar_hunt/features/ar/data/supabase_hunt_repository.dart';
import 'package:ar_hunt/features/ar/domain/hunt_models.dart';
import 'package:ar_hunt/features/ar/domain/hunt_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The real app code against the real database. Off by default, as it creates
/// a test player each run:
///
///     flutter test integration_test/live_backend_test.dart -d <device> \
///       --dart-define=HUNT_LIVE=true
///
/// Add `--dart-define=HUNT_TEST_PIN=...` to test the admin tools as well.
/// Afterwards, remove the test players in the Supabase SQL editor:
///
///     delete from auth.users where raw_user_meta_data->>'name' = 'Live Test';
const _live = bool.fromEnvironment('HUNT_LIVE');
const _pin = String.fromEnvironment('HUNT_TEST_PIN');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late HuntRepository repository;

  setUpAll(() async {
    if (!_live) return;
    final config = AppConfig.fromEnvironment();
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
    repository = SupabaseHuntRepository(Supabase.instance.client);
  });

  testWidgets('a player joins with a name and the rules hold', (tester) async {
    if (!_live) return;
    final auth = HuntAuth(AppConfig.fromEnvironment());
    await auth.join('Live Test');
    expect(repository.currentUserId, isNotNull);

    final snapshot = await repository.load();
    expect(snapshot.isActive, isTrue);
    expect(snapshot.isAdmin, isFalse);
    await repository.leaders();

    // A player cannot do anything an admin can.
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
    expect((await repository.load()).isAdmin, isTrue);

    final placed = await repository.placeItem(
      zone: 'd',
      kind: HuntItemKind.flag,
      x: 1.25,
      y: -0.5,
      z: 2,
      hint: 'Live test item',
    );
    addTearDown(() => repository.removeItem(placed.id));
    expect(placed.x, 1.25);
    expect(
      (await repository.load()).items.any((item) => item.id == placed.id),
      isTrue,
    );

    final find = await repository.collect(placed.id);
    expect(find.isAdmin, isTrue);
    expect(find.points, 0, reason: 'admins never score');

    await repository.removeItem(placed.id);
    expect(
      (await repository.load()).items.any((item) => item.id == placed.id),
      isFalse,
    );
  });
}
