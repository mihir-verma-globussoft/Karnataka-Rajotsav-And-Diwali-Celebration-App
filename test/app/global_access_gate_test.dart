import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/auth/global_auth_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/gate/data/event_gate_repository.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/gate/domain/event_gate_models.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/gate/event_gate_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/gate/presentation/global_application_access_gate.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/config/app_config.dart';

class _MockEventGateRepository implements EventGateRepository {
  _MockEventGateRepository({required this.status});

  EventGateStatus status;
  final StreamController<EventConfiguration> _controller =
      StreamController<EventConfiguration>.broadcast();

  @override
  Future<EventGateStatus> fetchStatus({
    String eventId = 'global_diwali',
  }) async => status;

  @override
  Stream<EventConfiguration> subscribeToConfigChanges({
    String eventId = 'global_diwali',
  }) => _controller.stream;

  void emitConfig(EventConfiguration config) => _controller.add(config);
}

void main() {
  const config = AppConfig(
    environment: AppEnvironment.dev,
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'publishable-key',
    googleWebClientId: 'web.apps.googleusercontent.com',
  );

  final playerWithoutAvatar = PlayerProfile(
    id: 'user-1',
    username: 'Test User',
    createdAt: DateTime.utc(2026),
  );

  final playerWithAvatar = PlayerProfile(
    id: 'user-1',
    username: 'Test User',
    characterAvatarUrl: 'avatar.jpg',
    createdAt: DateTime.utc(2026),
  );

  testWidgets('State 1: Unauthenticated user sees Google login screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          globalAuthStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(
          home: GlobalApplicationAccessGate(child: Text('PROTECTED APP')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('PROTECTED APP'), findsNothing);
  });

  testWidgets(
    'State 2: Authenticated user without avatar sees Avatar Setup with the selfie button',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            globalAuthStateProvider.overrideWith(
              (ref) => Stream.value(playerWithoutAvatar),
            ),
          ],
          child: const MaterialApp(
            home: GlobalApplicationAccessGate(child: Text('PROTECTED APP')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TAKE SELFIE'), findsOneWidget);
      expect(find.text('PROTECTED APP'), findsNothing);
    },
  );

  testWidgets(
    'State 3: Authenticated user with avatar sees Global Countdown when event is waiting',
    (tester) async {
      final now = DateTime.now().toUtc();
      final mockRepo = _MockEventGateRepository(
        status: EventGateStatus(
          id: 'global_diwali',
          eventName: 'Diwali 2026',
          serverTime: now,
          targetTime: now.add(const Duration(hours: 2)),
          isActive: true,
          testMode: false,
          isStarted: false,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            globalAuthStateProvider.overrideWith(
              (ref) => Stream.value(playerWithAvatar),
            ),
            eventGateRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: GlobalApplicationAccessGate(child: Text('PROTECTED APP')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CELEBRATION OPENS IN'), findsOneWidget);
      expect(find.text('DAYS'), findsOneWidget);
      expect(find.text('HOURS'), findsOneWidget);
      expect(find.text('MINS'), findsOneWidget);
      expect(find.text('SECS'), findsOneWidget);
      expect(find.text('PROTECTED APP'), findsNothing);
    },
  );

  testWidgets(
    'State 4: When event has started, main application shell unlocks',
    (tester) async {
      final now = DateTime.now().toUtc();
      final mockRepo = _MockEventGateRepository(
        status: EventGateStatus(
          id: 'global_diwali',
          eventName: 'Diwali 2026',
          serverTime: now,
          targetTime: now.subtract(const Duration(minutes: 10)),
          isActive: true,
          testMode: false,
          isStarted: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            globalAuthStateProvider.overrideWith(
              (ref) => Stream.value(playerWithAvatar),
            ),
            eventGateRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: GlobalApplicationAccessGate(child: Text('PROTECTED APP')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PROTECTED APP'), findsOneWidget);
      expect(find.text('CELEBRATION OPENS IN'), findsNothing);
    },
  );

  testWidgets(
    'State 5: When event is inactive, user sees Celebration Paused screen',
    (tester) async {
      final now = DateTime.now().toUtc();
      final mockRepo = _MockEventGateRepository(
        status: EventGateStatus(
          id: 'global_diwali',
          eventName: 'Diwali 2026',
          serverTime: now,
          targetTime: now.subtract(const Duration(hours: 1)),
          isActive: false, // Inactive!
          testMode: false,
          isStarted: false,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            globalAuthStateProvider.overrideWith(
              (ref) => Stream.value(playerWithAvatar),
            ),
            eventGateRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: GlobalApplicationAccessGate(child: Text('PROTECTED APP')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Celebration Paused'), findsOneWidget);
      expect(find.text('PROTECTED APP'), findsNothing);
    },
  );
}
