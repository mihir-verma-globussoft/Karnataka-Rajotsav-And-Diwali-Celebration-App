/// What can be placed on the house. [id] matches the artwork it is drawn with.
enum DecorKind {
  diya('diya', 'Diya'),
  rangoli('rangoli', 'Rangoli'),
  lantern('lantern', 'Lantern'),
  garland('garland', 'Garland'),
  sparkler('sparkler', 'Sparkler');

  const DecorKind(this.id, this.label);

  final String id;
  final String label;
}

/// One decoration on the house. [x] and [y] are the centre, from 0 to 1 across
/// the picture.
class DecorItem {
  const DecorItem({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
  });

  final int id;
  final DecorKind kind;
  final double x;
  final double y;

  DecorItem at(double newX, double newY) =>
      DecorItem(id: id, kind: kind, x: newX, y: newY);
}

/// Most decorations on one house.
const int decorMax = 40;

/// Which way the arrow buttons move a decoration.
enum DecorDirection { left, right, up, down }

/// Immutable state of the house being decorated. Decorations later in
/// [items] are drawn on top. Moves that change nothing return `this`.
class DecorState {
  DecorState({List<DecorItem> items = const [], this.selectedId})
    : items = List<DecorItem>.unmodifiable(items);

  final List<DecorItem> items;

  /// The decoration being moved, or null.
  final int? selectedId;

  /// How far each arrow press moves a decoration.
  static const double nudgeStep = 0.03;

  /// Decorations stay at least this far from the edge, so they are never lost.
  static const double _margin = 0.05;

  bool get isEmpty => items.isEmpty;
  bool get isFull => items.length >= decorMax;
  DecorItem? get selected => byId(selectedId);

  DecorItem? byId(int? id) {
    if (id == null) return null;
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  // New decorations fan out from the middle so they never stack exactly.
  static const List<(double, double)> _spots = [
    (0, 0),
    (0.14, -0.1),
    (-0.14, -0.1),
    (0.14, 0.12),
    (-0.14, 0.12),
  ];

  /// Places a new [kind] near the middle and selects it.
  DecorState add(DecorKind kind) {
    if (isFull) return this;
    final spot = _spots[items.length % _spots.length];
    var id = items.isEmpty ? 1 : items.map((i) => i.id).reduce(_max) + 1;
    if (id < 1) id = 1;
    return DecorState(
      items: [
        ...items,
        DecorItem(id: id, kind: kind, x: 0.5 + spot.$1, y: 0.5 + spot.$2),
      ],
      selectedId: id,
    );
  }

  static int _max(int a, int b) => a > b ? a : b;

  double _clamp(double v) => v.clamp(_margin, 1 - _margin);

  /// Moves decoration [id] to ([x], [y]), keeping it on the picture.
  DecorState moveTo(int id, double x, double y) {
    final item = byId(id);
    if (item == null) return this;
    final nx = _clamp(x);
    final ny = _clamp(y);
    if (nx == item.x && ny == item.y) return this;
    return DecorState(
      items: [for (final i in items) i.id == id ? i.at(nx, ny) : i],
      selectedId: selectedId,
    );
  }

  /// Moves the selected decoration one step.
  DecorState nudge(DecorDirection direction) {
    final item = selected;
    if (item == null) return this;
    return switch (direction) {
      DecorDirection.left => moveTo(item.id, item.x - nudgeStep, item.y),
      DecorDirection.right => moveTo(item.id, item.x + nudgeStep, item.y),
      DecorDirection.up => moveTo(item.id, item.x, item.y - nudgeStep),
      DecorDirection.down => moveTo(item.id, item.x, item.y + nudgeStep),
    };
  }

  /// Selects [id] and brings it to the front; null clears the selection.
  DecorState select(int? id) {
    if (id == selectedId) return this;
    final item = byId(id);
    if (id != null && item == null) return this;
    if (item == null) return DecorState(items: items);
    return DecorState(
      items: [
        for (final i in items)
          if (i.id != id) i,
        item,
      ],
      selectedId: id,
    );
  }

  /// Removes the selected decoration.
  DecorState removeSelected() {
    final id = selectedId;
    if (id == null || byId(id) == null) return this;
    return DecorState(
      items: [
        for (final i in items)
          if (i.id != id) i,
      ],
    );
  }

  DecorState clear() => isEmpty ? this : DecorState();
}
