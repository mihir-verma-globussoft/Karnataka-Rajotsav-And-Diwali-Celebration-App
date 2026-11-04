import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_diwali/domain/pacman_engine.dart';

void main() {
  test('starts ready with dots everywhere except walls and pacman', () {
    final e = PacmanEngine();
    expect(e.status, PacStatus.ready);
    expect(e.dots.contains(e.pacman), isFalse);
    expect(e.dots.intersection(e.walls), isEmpty);
  });

  test('pacman eats a dot, and cannot walk through walls', () {
    final e = PacmanEngine()..start();
    final before = e.dots.length;
    e.stepPacman();
    expect(e.pacman, const Cell(2, 14));
    expect(e.dots.length, before - 1);
    expect(e.score, 1);
    e.steer(PacDirection.up); // (2,13) is a wall: turn stays queued
    e.stepPacman();
    expect(e.facing, PacDirection.right);
  });

  test('touching a ghost loses; clearing dots wins', () {
    final e = PacmanEngine()..start();
    e.ghosts.first.cell = e.pacman.step(PacDirection.right);
    e.stepPacman();
    expect(e.status, PacStatus.lost);

    final w = PacmanEngine()..start();
    w.ghosts.clear();
    w.dots
      ..clear()
      ..add(w.pacman.step(PacDirection.right));
    w.stepPacman();
    expect(w.status, PacStatus.won);
  });

  test('ghosts always end on open cells', () {
    final e = PacmanEngine()..start();
    for (var i = 0; i < 200; i++) {
      e.ghosts.map((g) => g.cell).forEach((c) => expect(e.isWall(c), isFalse));
      e.stepGhosts();
      if (e.status != PacStatus.playing) {
        e.reset();
        e.start();
      }
    }
  });

  test('ghosts together roam most of the maze instead of one loop', () {
    final e = PacmanEngine(random: Random(7))..start();
    final open = <Cell>{
      for (var y = 0; y < PacmanEngine.rows; y++)
        for (var x = 0; x < PacmanEngine.columns; x++)
          if (!e.isWall(Cell(x, y))) Cell(x, y),
    };
    final seen = <Cell>{};
    for (var i = 0; i < 600; i++) {
      e.stepGhosts();
      seen.addAll(e.ghosts.map((g) => g.cell));
      e.status = PacStatus.playing; // ignore catches: only testing roaming
    }
    expect(seen.length / open.length, greaterThan(0.8));
  });

  test('a ghost and pacman swapping cells counts as caught', () {
    final e = PacmanEngine()..start();
    e.ghosts.removeRange(1, 3);
    final g = e.ghosts.first;
    g.cell = e.pacman.step(PacDirection.right);
    g.prev = g.cell.step(PacDirection.right);
    g.heading = PacDirection.left;
    e.stepPacman(); // pacman moves onto the ghost cell
    expect(e.status, PacStatus.lost);
  });

  test('canTurn: only a different way with an open cell', () {
    final e = PacmanEngine()..start();
    expect(e.canTurn(PacDirection.right), isFalse); // already facing it
    expect(e.canTurn(PacDirection.up), isTrue); // (1,13) is open
    expect(e.canTurn(PacDirection.down), isFalse); // the maze edge
  });
}
