import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/background_song.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/kannada_speaker.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_providers.dart';

import '../../helpers.dart';

/// Behaves like the real player: play/pause report back through [playback].
class _FakeSong implements BackgroundSong {
  _FakeSong({this.available = true});

  final bool available;
  final _events = StreamController<SongPlayback>.broadcast(sync: true);
  final List<String> calls = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> play() async {
    calls.add('play');
    _events.add(SongPlayback.playing);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _events.add(SongPlayback.paused);
  }

  /// The system pausing it (a call) or the song reaching its end.
  void emit(SongPlayback playback) => _events.add(playback);

  @override
  Stream<SongPlayback> get playback => _events.stream;
}

class _QuietSpeaker implements KannadaSpeaker {
  final Completer<void> speaking = Completer<void>();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> speak(String text) => speaking.future;

  @override
  Future<void> stop() async {}
}

Future<_FakeSong> _pump(
  WidgetTester tester, {
  KannadaSpeaker? speaker,
  bool available = true,
}) async {
  tester.view.physicalSize = const Size(400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final song = _FakeSong(available: available);
  await tester.pumpWidget(
    testApp(
      overrides: [
        backgroundSongProvider.overrideWithValue(song),
        if (speaker != null) kannadaSpeakerProvider.overrideWithValue(speaker),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return song;
}

Future<void> _switchTab(WidgetTester tester, String tab) async {
  await tester.tap(find.byKey(ValueKey('tab-$tab')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('plays automatically on the Rajyotsava tab', (tester) async {
    final song = await _pump(tester);
    expect(song.calls, ['play']);
    expect(find.byTooltip('Mute song'), findsOneWidget);
    expect(find.byKey(const ValueKey('song-now-playing')), findsOneWidget);
  });

  testWidgets('mute stops it and it stays off until unmuted', (tester) async {
    final song = await _pump(tester);
    await tester.tap(find.byTooltip('Mute song'));
    await tester.pump();
    expect(song.calls, ['play', 'pause']);
    expect(find.byTooltip('Play song'), findsOneWidget);

    await _switchTab(tester, 'Games');
    await _switchTab(tester, 'Rajyotsava');
    expect(song.calls, ['play', 'pause']);

    await tester.tap(find.byTooltip('Play song'));
    await tester.pump();
    expect(song.calls, ['play', 'pause', 'play']);
  });

  testWidgets('pauses on other tabs and resumes on return', (tester) async {
    final song = await _pump(tester);
    await _switchTab(tester, 'Deepavali');
    expect(song.calls, ['play', 'pause']);
    await _switchTab(tester, 'Rajyotsava');
    expect(song.calls, ['play', 'pause', 'play']);
  });

  testWidgets('pauses on a sub-screen and resumes on back', (tester) async {
    final song = await _pump(tester);
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push<void>(RajyotsavaRoutes.learn)
        .ignore();
    await tester.pumpAndSettle();
    expect(song.calls.last, 'pause');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(song.calls.last, 'play');
  });

  testWidgets('a system pause is not a mute; it plays on the next visit', (
    tester,
  ) async {
    final song = await _pump(tester);
    song.emit(SongPlayback.paused);
    await tester.pump();
    expect(find.byTooltip('Mute song'), findsOneWidget);
    expect(song.calls, ['play']);
    await _switchTab(tester, 'Games');
    await _switchTab(tester, 'Rajyotsava');
    expect(song.calls, ['play', 'play']);
  });

  testWidgets('pauses while a wish is read aloud, then resumes', (
    tester,
  ) async {
    final speaker = _QuietSpeaker();
    final song = await _pump(tester, speaker: speaker);
    await tester.tap(
      find.byTooltip('Listen to ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವದ ಹಾರ್ದಿಕ ಶುಭಾಶಯಗಳು!'),
    );
    await tester.pump();
    expect(song.calls, ['play', 'pause']);
    speaker.speaking.complete();
    await tester.pump();
    expect(song.calls, ['play', 'pause', 'play']);
  });

  testWidgets('does not replay after it ends until the next visit', (
    tester,
  ) async {
    final speaker = _QuietSpeaker();
    final song = await _pump(tester, speaker: speaker);
    song.emit(SongPlayback.ended);
    await tester.pump();
    await tester.tap(
      find.byTooltip('Listen to ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವದ ಹಾರ್ದಿಕ ಶುಭಾಶಯಗಳು!'),
    );
    await tester.pump();
    speaker.speaking.complete();
    await tester.pump();
    expect(song.calls, ['play']);
  });

  testWidgets('without the song file: no song and no mute button', (
    tester,
  ) async {
    final song = await _pump(tester, available: false);
    expect(song.calls, isEmpty);
    expect(find.byKey(const ValueKey('song-mute')), findsNothing);
    expect(find.byKey(const ValueKey('song-now-playing')), findsNothing);
  });
}
