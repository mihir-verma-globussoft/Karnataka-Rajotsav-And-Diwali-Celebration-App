import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/game_session.dart';

void main() {
  late GameSession game;

  setUp(() {
    game = GameSession(random: Random(1))
      ..startNewGame(id: '00000000-0000-4000-8000-000000000001');
  });

  test('a new game starts ready with exactly three lives', () {
    expect(game.phase, GamePhase.ready);
    expect(game.lives, 3);
    expect(game.score, 0);
  });

  test('three distinct collisions consume three lives and end the game', () {
    for (var expected = 2; expected >= 0; expected--) {
      game.tap();
      expect(game.registerCollision(), isTrue);
      expect(game.lives, expected);
    }
    expect(game.phase, GamePhase.gameOver);
    expect(game.livesUsed, 3);
  });

  test('duplicate collision callbacks consume only one life', () {
    game.tap();
    expect(game.registerCollision(), isTrue);
    expect(game.registerCollision(), isFalse);
    expect(game.lives, 2);
  });

  test('lives never become negative', () {
    for (var i = 0; i < 8; i++) {
      game.tap();
      game.registerCollision();
    }
    expect(game.lives, 0);
  });

  test('starting another game resets lives and score', () {
    game.tap();
    game.registerCollision();
    game.startNewGame(id: '00000000-0000-4000-8000-000000000002');
    expect(game.lives, 3);
    expect(game.score, 0);
    expect(game.phase, GamePhase.ready);
  });

  test('application interruption resets to a safe ready state', () {
    game.tap();
    game.update(0.02);
    game.pauseForLifecycle();
    expect(game.phase, GamePhase.paused);
    expect(game.lives, 3);
    game.resumeAfterLifecycle();
    expect(game.phase, GamePhase.ready);
  });
}
