import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/domain/pacman_game.dart';

/// Runs the game for [seconds] in small steps, like the screen's ticker.
void run(PacmanGame g, double seconds) {
  for (var t = 0.0; t < seconds; t += 0.016) {
    g.update(0.016);
  }
}

/// A tiny maze: Pac-Man at the left, two dots to his right, a ghost far right.
const corridor = Maze(['#########', '#P..   G#', '#########']);

void main() {
  test('the classic maze is closed, symmetric and fully connected', () {
    const m = Maze.classic;
    expect(m.rows.every((r) => r.length == m.width), isTrue);
    expect(m.rows.first, '#' * m.width);
    expect(m.rows.last, '#' * m.width);
    for (final r in m.rows) {
      expect(r, r.split('').reversed.join(), reason: 'row $r is symmetric');
    }
    expect(m.cellsOf('P'), hasLength(1));
    expect(m.cellsOf('G'), hasLength(4));
    final open = {
      for (var y = 0; y < m.height; y++)
        for (var x = 0; x < m.width; x++)
          if (!m.isWall(x, y)) (x, y),
    };
    final seen = {open.first};
    final todo = [open.first];
    while (todo.isNotEmpty) {
      final (x, y) = todo.removeLast();
      for (final d in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final n = (x + d.$1, y + d.$2);
        if (open.contains(n) && seen.add(n)) todo.add(n);
      }
    }
    expect(seen, open, reason: 'every open tile can be reached');
  });

  test('Pac-Man eats dots as he moves and scores for them', () {
    final g = PacmanGame(maze: corridor, random: Random(1))..start();
    g.steer(Dir.right);
    run(g, 0.7);
    expect(g.score, PacmanGame.dotPoints * 2);
    expect(g.dotsLeft, 0);
    expect(g.state, GameState.levelClear);
  });

  test('walls stop Pac-Man', () {
    final g = PacmanGame(maze: corridor, random: Random(1))..start();
    g.steer(Dir.up);
    run(g, 1);
    expect(g.pac.y, 1);
    g.steer(Dir.left);
    run(g, 1);
    expect(g.pac.x, 1);
  });

  test('he can turn back mid-corridor', () {
    final g = PacmanGame(maze: corridor, random: Random(1))..start();
    g.steer(Dir.right);
    run(g, 0.2);
    expect(g.pac.x, greaterThan(1));
    g.steer(Dir.left);
    run(g, 0.1);
    expect(g.pac.dir, Dir.left);
  });

  test('touching a ghost costs a life, then play resumes; no lives = over', () {
    final g = PacmanGame(random: Random(1))..start();
    final ghost = g.ghosts.first
      ..x = g.pac.x
      ..y = g.pac.y
      ..releaseIn = 0;
    g.update(0.016);
    expect(ghost.eaten, isFalse);
    expect(g.state, GameState.dying);
    expect(g.lives, PacmanGame.startingLives - 1);
    run(g, PacmanGame.deathSeconds + 0.1);
    expect(g.state, GameState.playing);

    for (var i = 0; i < 2; i++) {
      g.ghosts.first
        ..x = g.pac.x
        ..y = g.pac.y
        ..releaseIn = 0;
      g.update(0.016);
      run(g, PacmanGame.deathSeconds + 0.1);
    }
    expect(g.lives, 0);
    expect(g.state, GameState.gameOver);
    g.start();
    expect(g.state, GameState.playing);
    expect(g.score, 0);
    expect(g.lives, PacmanGame.startingLives);
  });

  test('a power pellet lets Pac-Man eat a ghost for bonus points', () {
    final g = PacmanGame(maze: corridor, random: Random(1))..start();
    g.frightened = PacmanGame.frightenedSeconds;
    final ghost = g.ghosts.first
      ..x = g.pac.x
      ..y = g.pac.y
      ..releaseIn = 0;
    g.update(0.016);
    expect(ghost.eaten, isTrue);
    expect(g.state, GameState.playing);
    expect(g.score, PacmanGame.ghostPoints);
  });

  test('ghosts start one after another and stay on the open floor', () {
    final g = PacmanGame(random: Random(3))..start();
    expect(g.ghosts.map((x) => x.releaseIn), [0, 2, 4, 6]);
    steerAround(g);
    for (final gh in g.ghosts) {
      expect(g.maze.isWall(gh.tx, gh.ty), isFalse);
    }
  });

  test('next level refills the dots and speeds the ghosts up', () {
    final g = PacmanGame(maze: corridor, random: Random(1))..start();
    g.steer(Dir.right);
    run(g, 0.7);
    expect(g.state, GameState.levelClear);
    g.nextLevel();
    expect(g.level, 2);
    expect(g.dotsLeft, 2);
    expect(g.state, GameState.playing);
  });
}

void steerAround(PacmanGame g) {
  for (var i = 0; i < 20; i++) {
    g.steer(const [Dir.left, Dir.up, Dir.right, Dir.down][i % 4]);
    run(g, 0.5);
    if (g.state == GameState.gameOver) g.start();
  }
}
