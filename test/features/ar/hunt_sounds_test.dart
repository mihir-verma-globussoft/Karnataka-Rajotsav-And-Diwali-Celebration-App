import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/data/audioplayers_hunt_sounds.dart';

class _FakePlayer extends Fake implements AudioPlayer {
  final calls = <String>[];

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async =>
      calls.add(releaseMode.name);

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async => calls.add('play ${(source as AssetSource).path}');

  @override
  Future<void> stop() async => calls.add('stop');
}

void main() {
  test('the song loops', () async {
    final player = _FakePlayer();
    final sounds = AudioplayersHuntSounds(newMusicPlayer: () async => player);

    await sounds.startMusic();

    expect(player.calls, ['loop', 'play ${AudioplayersHuntSounds.musicAsset}']);
  });

  test('leaving while the song is still loading never plays it', () async {
    final player = _FakePlayer();
    final loading = Completer<AudioPlayer>();
    final sounds = AudioplayersHuntSounds(newMusicPlayer: () => loading.future);

    final starting = sounds.startMusic();
    final stopping = sounds.stopMusic();
    loading.complete(player);
    await Future.wait([starting, stopping]);

    expect(player.calls.where((call) => call.startsWith('play')), isEmpty);
  });

  test('starting twice while loading still makes one player', () async {
    var made = 0;
    final sounds = AudioplayersHuntSounds(
      newMusicPlayer: () async {
        made++;
        return _FakePlayer();
      },
    );

    await Future.wait([sounds.startMusic(), sounds.startMusic()]);

    expect(made, 1, reason: 'two players would play the song twice');
  });

  test('a song that cannot play never breaks the page', () async {
    final sounds = AudioplayersHuntSounds(
      newMusicPlayer: () async => throw Exception('No audio here'),
    );
    await sounds.startMusic();
    await sounds.stopMusic();
  });

  test('the song is the one already bundled with the app', () {
    expect(
      File('assets/${AudioplayersHuntSounds.musicAsset}').existsSync(),
      isTrue,
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/deepavali/audio/'),
    );
  });
}
