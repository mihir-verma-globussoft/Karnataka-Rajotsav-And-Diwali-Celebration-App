import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/ar_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_availability.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_platform.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/games/domain/games_audio.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/games/games_providers.dart';

import '../../helpers.dart';

class _FakeAr implements ArPlatform {
  @override
  Future<ArAvailability> checkAvailability() async =>
      ArAvailability.unavailable;

  @override
  Future<ArAvailability> prepare() async => ArAvailability.unavailable;

  @override
  Future<void> openSettings() async {}
}

class _FakeGamesAudio implements GamesAudio {
  _FakeGamesAudio({this.available = true});

  final bool available;
  final _events = StreamController<GamesAudioPlayback>.broadcast(sync: true);
  final List<String> calls = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> play() async {
    calls.add('play');
    _events.add(GamesAudioPlayback.playing);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _events.add(GamesAudioPlayback.paused);
  }

  void emit(GamesAudioPlayback playback) => _events.add(playback);

  @override
  Stream<GamesAudioPlayback> get playback => _events.stream;
}

Future<_FakeGamesAudio> _pumpGames(
  WidgetTester tester, {
  bool available = true,
}) async {
  tester.view.physicalSize = const Size(400, 3000);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final audio = _FakeGamesAudio(available: available);
  await tester.pumpWidget(
    testApp(
      overrides: [
        arPlatformProvider.overrideWithValue(_FakeAr()),
        gamesAudioProvider.overrideWithValue(audio),
      ],
    ),
  );
  await tester.pumpAndSettle();

  // Tap into Games tab
  await tester.tap(find.byKey(const ValueKey('tab-Games')));
  await tester.pumpAndSettle();
  return audio;
}

Future<void> _switchTab(WidgetTester tester, String tab) async {
  await tester.tap(find.byKey(ValueKey('tab-$tab')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('plays automatically when user opens the Games tab', (
    tester,
  ) async {
    final audio = await _pumpGames(tester);
    expect(audio.calls, ['play']);
    expect(find.byKey(const ValueKey('games-audio-mute')), findsOneWidget);
    expect(find.byTooltip('Mute audio'), findsOneWidget);
  });

  testWidgets('mute stops it and unmuting resumes playback', (tester) async {
    final audio = await _pumpGames(tester);
    await tester.tap(find.byTooltip('Mute audio'));
    await tester.pump();
    expect(audio.calls, ['play', 'pause']);
    expect(find.byTooltip('Play audio'), findsOneWidget);

    await tester.tap(find.byTooltip('Play audio'));
    await tester.pump();
    expect(audio.calls, ['play', 'pause', 'play']);
  });

  testWidgets('pauses on other tabs and resumes when returning to Games tab', (
    tester,
  ) async {
    final audio = await _pumpGames(tester);
    expect(audio.calls, ['play']);

    await _switchTab(tester, 'Rajyotsava');
    expect(audio.calls, ['play', 'pause']);

    await _switchTab(tester, 'Games');
    expect(audio.calls, ['play', 'pause', 'play']);
  });

  testWidgets('pauses when opening a game and resumes on back', (tester) async {
    final audio = await _pumpGames(tester);
    expect(audio.calls, ['play']);

    await tester.tap(find.text('Flappy Bird'));
    await tester.pumpAndSettle();
    expect(audio.calls, ['play', 'pause']);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(audio.calls, ['play', 'pause', 'play']);
  });

  testWidgets('without audio file: no playback and no mute button', (
    tester,
  ) async {
    final audio = await _pumpGames(tester, available: false);
    expect(audio.calls, isEmpty);
    expect(find.byKey(const ValueKey('games-audio-mute')), findsNothing);
  });
}
