import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/app.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/auth/global_auth_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_module.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/gate/data/event_gate_repository.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/gate/domain/event_gate_models.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/gate/event_gate_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/gate/presentation/startup_poster_view.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/config/app_config.dart';

class _Repo implements EventGateRepository {
  _Repo(this.status);
  final EventGateStatus status;

  @override
  Future<EventGateStatus> fetchStatus({
    String eventId = 'global_diwali',
  }) async => status;

  @override
  Stream<EventConfiguration> subscribeToConfigChanges({
    String eventId = 'global_diwali',
  }) => const Stream.empty();
}

/// The screens a player sees first (login, avatar setup, countdown, paused)
/// are built by the real [App], in `MaterialApp.router`'s `builder`, above the
/// router's Navigator. Testing them under a plain `MaterialApp(home: …)` hides
/// problems that only exist there, such as a missing Overlay for tooltips, so
/// these tests run the whole app.
void main() {
  const config = AppConfig(
    environment: AppEnvironment.dev,
    supabaseUrl: 'https://x.supabase.co',
    supabaseAnonKey: 'k',
    googleWebClientId: 'w',
  );
  final noAvatar = PlayerProfile(
    id: 'u',
    username: 'Test User',
    createdAt: DateTime.utc(2026),
  );
  final avatar = PlayerProfile(
    id: 'u',
    username: 'A Rather Long Player Name Here',
    characterAvatarUrl: 'a.jpg',
    createdAt: DateTime.utc(2026),
  );

  EventGateStatus status({bool active = true}) {
    final now = DateTime.now().toUtc();
    return EventGateStatus(
      id: 'g',
      eventName: 'Diwali',
      serverTime: now,
      targetTime: now.add(const Duration(days: 3, hours: 2)),
      isActive: active,
      testMode: false,
      isStarted: false,
    );
  }

  Widget app(PlayerProfile? player, EventGateStatus? gate) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      featureModulesProvider.overrideWithValue(featureModules),
      globalAuthStateProvider.overrideWith((ref) => Stream.value(player)),
      if (gate != null)
        eventGateRepositoryProvider.overrideWithValue(_Repo(gate)),
    ],
    child: const App(),
  );

  final screens = <String, Widget Function()>{
    'login': () => app(null, null),
    'avatar setup': () => app(noAvatar, null),
    'countdown': () => app(avatar, status()),
    'paused': () => app(avatar, status(active: false)),
  };

  for (final size in const [Size(320, 568), Size(360, 800), Size(412, 915)]) {
    for (final scale in const [1.0, 2.0]) {
      for (final screen in screens.entries) {
        testWidgets(
          '${screen.key} has no errors or overflow at $size, text x$scale',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
            tester.view.viewPadding = const FakeViewPadding(
              top: 24,
              bottom: 48,
            );
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(tester.platformDispatcher.clearAllTestValues);

            await tester.pumpWidget(screen.value());
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            expect(tester.takeException(), isNull);
            // Stop the countdown's timers before the test ends.
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 1));
          },
        );
      }
    }
  }

  testWidgets('the countdown has an Overlay for its sign-out tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(app(avatar, status()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('Sign out'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('while the sign-in state loads, the poster shows, not a blank '
      'screen', (tester) async {
    final never = StreamController<PlayerProfile?>();
    addTearDown(never.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          featureModulesProvider.overrideWithValue(featureModules),
          globalAuthStateProvider.overrideWith((ref) => never.stream),
        ],
        child: const App(),
      ),
    );
    await tester.pump();
    expect(find.byType(StartupPosterView), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/auth/login_bg.jpg',
      ),
      findsOneWidget,
    );
  });
}
