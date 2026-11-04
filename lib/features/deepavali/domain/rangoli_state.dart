import 'dart:math';

import 'rangoli_geometry.dart';

/// Number of colours in the palette. Colours are palette indexes here; the
/// presentation layer decides what they look like.
const int rangoliPaletteSize = 8;

/// Most undo steps kept.
const int rangoliUndoDepth = 50;

/// Immutable rangoli editor state. Every method returns the new state; moves
/// that change nothing return `this`.
class RangoliState {
  RangoliState({
    List<int?>? cells,
    this.colour = 0,
    this.symmetry = true,
    List<List<int?>> undoStack = const [],
  }) : cells = List<int?>.unmodifiable(
         cells ?? List<int?>.filled(RangoliGeometry.cellCount, null),
       ),
       _undo = List<List<int?>>.unmodifiable(undoStack) {
    assert(this.cells.length == RangoliGeometry.cellCount);
  }

  /// Palette index per cell; null is unpainted.
  final List<int?> cells;

  /// Selected palette index, or null for the eraser.
  final int? colour;

  /// Paint a cell together with its quarter-turn copies.
  final bool symmetry;

  final List<List<int?>> _undo;

  bool get isEmpty => cells.every((c) => c == null);
  int get paintedCount => cells.where((c) => c != null).length;
  bool get canUndo => _undo.isNotEmpty;
  int get undoDepth => _undo.length;

  RangoliState _next({
    List<int?>? cells,
    int? Function()? colour,
    bool? symmetry,
    bool pushUndo = false,
  }) {
    var stack = _undo;
    if (pushUndo) {
      stack = [..._undo, this.cells];
      if (stack.length > rangoliUndoDepth) {
        stack = stack.sublist(stack.length - rangoliUndoDepth);
      }
    }
    return RangoliState(
      cells: cells ?? this.cells,
      colour: colour == null ? this.colour : colour(),
      symmetry: symmetry ?? this.symmetry,
      undoStack: stack,
    );
  }

  RangoliState select(int? paletteIndex) {
    assert(
      paletteIndex == null ||
          (paletteIndex >= 0 && paletteIndex < rangoliPaletteSize),
    );
    return paletteIndex == colour ? this : _next(colour: () => paletteIndex);
  }

  RangoliState setSymmetry({required bool on}) =>
      on == symmetry ? this : _next(symmetry: on);

  /// Paints (or erases) the cell at [index] and, with symmetry on, its copies.
  RangoliState tap(int index) {
    if (index < 0 || index >= RangoliGeometry.cellCount) return this;
    final targets = symmetry ? RangoliGeometry.symmetric(index) : [index];
    final next = List<int?>.of(cells);
    var changed = false;
    for (final t in targets) {
      if (next[t] != colour) {
        next[t] = colour;
        changed = true;
      }
    }
    return changed ? _next(cells: next, pushUndo: true) : this;
  }

  RangoliState undo() {
    if (_undo.isEmpty) return this;
    return RangoliState(
      cells: _undo.last,
      colour: colour,
      symmetry: symmetry,
      undoStack: _undo.sublist(0, _undo.length - 1),
    );
  }

  /// Clears everything (can be undone).
  RangoliState reset() => isEmpty
      ? this
      : _next(
          cells: List<int?>.filled(RangoliGeometry.cellCount, null),
          pushUndo: true,
        );

  /// A symmetrical random design: each ring gets two colours (alternate
  /// sectors), so it looks the same turned by a quarter. The same [seed]
  /// always gives the same design.
  RangoliState randomize(int seed) {
    final rng = Random(seed);
    int pick([int? not]) {
      var c = rng.nextInt(rangoliPaletteSize);
      while (c == not) {
        c = rng.nextInt(rangoliPaletteSize);
      }
      return c;
    }

    final next = List<int?>.filled(RangoliGeometry.cellCount, null);
    next[0] = pick();
    for (var ring = 1; ring < RangoliGeometry.rings; ring++) {
      final a = pick();
      final b = pick(a);
      for (var s = 0; s < RangoliGeometry.sectors; s++) {
        next[RangoliGeometry.indexOf(ring, s)] = s.isEven ? a : b;
      }
    }
    return _next(cells: next, pushUndo: true);
  }
}
