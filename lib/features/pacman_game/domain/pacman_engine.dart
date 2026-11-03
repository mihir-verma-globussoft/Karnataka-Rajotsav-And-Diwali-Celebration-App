import 'dart:math';

enum PacDirection {
  left(-1, 0),
  right(1, 0),
  up(0, -1),
  down(0, 1);

  const PacDirection(this.dx, this.dy);
  final int dx;
  final int dy;

  /// Clockwise quarter turns from "facing right".
  double get angle => switch (this) {
    PacDirection.right => 0,
    PacDirection.down => 1.5707963267948966,
    PacDirection.left => 3.141592653589793,
    PacDirection.up => 4.71238898038469,
  };
}

enum PacStatus { ready, playing, paused, won, lost }

/// Maze position as (column, row).
class Cell {
  const Cell(this.x, this.y);
  final int x;
  final int y;

  Cell step(PacDirection d) => Cell(x + d.dx, y + d.dy);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// How a ghost picks its way at junctions.
enum GhostStyle { chaser, wanderer, patroller }

class Ghost {
  Ghost(this.cell, this.heading, this.colorValue, this.style) : prev = cell;
  Cell cell;
  Cell prev;
  Cell? target;
  int stepsOnTarget = 0;
  PacDirection heading;
  final int colorValue;
  final GhostStyle style;
}

/// Pure game rules (no Flutter widgets or timers) so they are unit-testable.
/// The 11x16 maze layout is from github.com/Raj2503/Pacman-Flutter (MIT).
/// Ghosts never reverse mid-corridor; at junctions each follows its own style
/// (chase the player, wander, or patrol to random spots).
class PacmanEngine {
  PacmanEngine({this.onChanged, Random? random})
    : _random = random ?? Random() {
    _setup();
  }

  /// Called after every state change so a UI can repaint.
  final void Function()? onChanged;
  final Random _random;

  void notifyListeners() => onChanged?.call();

  static const int columns = 11;
  static const int rows = 16;

  static const List<int> _walls = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    22,
    33,
    44,
    55,
    66,
    77,
    99,
    110,
    121,
    132,
    143,
    154,
    165,
    166,
    167,
    168,
    169,
    170,
    171,
    172,
    173,
    174,
    175,
    164,
    153,
    142,
    131,
    120,
    109,
    87,
    76,
    65,
    54,
    43,
    32,
    21,
    78,
    79,
    80,
    100,
    101,
    102,
    84,
    85,
    86,
    106,
    107,
    108,
    24,
    35,
    46,
    57,
    30,
    41,
    52,
    63,
    81,
    70,
    59,
    61,
    72,
    83,
    26,
    28,
    37,
    38,
    39,
    123,
    134,
    145,
    129,
    140,
    151,
    103,
    114,
    125,
    105,
    116,
    127,
    147,
    148,
    149,
  ];

  static Cell _fromIndex(int i) => Cell(i % columns, i ~/ columns);

  final Set<Cell> walls = {for (final i in _walls) _fromIndex(i)};

  late Cell pacman;
  late Cell prevPacman;

  /// Cell whose dot was eaten on the latest pacman step, else null.
  Cell? lastEaten;
  late PacDirection facing;
  PacDirection? _queued;
  late List<Ghost> ghosts;
  late Set<Cell> dots;
  int score = 0;
  PacStatus status = PacStatus.ready;

  bool isWall(Cell c) =>
      c.x < 0 || c.y < 0 || c.x >= columns || c.y >= rows || walls.contains(c);

  void reset() {
    _setup();
    notifyListeners();
  }

  void _setup() {
    pacman = _fromIndex(columns * 14 + 1);
    prevPacman = pacman;
    facing = PacDirection.right;
    _queued = null;
    ghosts = [
      Ghost(
        _fromIndex(columns * 2 - 2),
        PacDirection.left,
        0xFFE53935,
        GhostStyle.chaser,
      ),
      Ghost(
        _fromIndex(columns * 9 - 1),
        PacDirection.left,
        0xFFFF80AB,
        GhostStyle.wanderer,
      ),
      Ghost(
        _fromIndex(columns * 11 - 2),
        PacDirection.down,
        0xFF26C6DA,
        GhostStyle.patroller,
      ),
    ];
    dots = {
      for (var i = 0; i < columns * rows; i++)
        if (!_walls.contains(i)) _fromIndex(i),
    }..remove(pacman);
    score = 0;
    status = PacStatus.ready;
  }

  void start() {
    if (status == PacStatus.ready) {
      status = PacStatus.playing;
      notifyListeners();
    }
  }

  void togglePause() {
    if (status == PacStatus.playing) {
      status = PacStatus.paused;
    } else if (status == PacStatus.paused) {
      status = PacStatus.playing;
    } else {
      return;
    }
    notifyListeners();
  }

  /// Swipe input: remembered until the corridor allows the turn.
  void steer(PacDirection d) {
    _queued = d;
    start();
  }

  void stepPacman() {
    if (status != PacStatus.playing) return;
    final queued = _queued;
    if (queued != null && !isWall(pacman.step(queued))) {
      facing = queued;
      _queued = null;
    }
    prevPacman = pacman;
    lastEaten = null;
    final next = pacman.step(facing);
    if (!isWall(next)) pacman = next;
    if (dots.remove(pacman)) {
      score++;
      lastEaten = pacman;
    }
    _resolve();
    notifyListeners();
  }

  void stepGhosts() {
    if (status != PacStatus.playing) return;
    for (final g in ghosts) {
      _moveGhost(g);
    }
    _resolve();
    notifyListeners();
  }

  void _moveGhost(Ghost g) {
    g.prev = g.cell;
    // Never turn back on the way, unless it is a dead end.
    final back = _reverse(g.heading);
    var options = [
      for (final d in PacDirection.values)
        if (d != back && !isWall(g.cell.step(d))) d,
    ];
    if (options.isEmpty) {
      if (isWall(g.cell.step(back))) return;
      options = [back];
    }
    final d = options.length == 1 ? options.first : _choose(g, options);
    g.cell = g.cell.step(d);
    g.heading = d;
  }

  PacDirection _choose(Ghost g, List<PacDirection> options) {
    Cell? goal;
    var focus = 0.0;
    switch (g.style) {
      case GhostStyle.chaser:
        goal = pacman;
        focus = 0.7;
      case GhostStyle.wanderer:
        break;
      case GhostStyle.patroller:
        // Head for a random far-off spot, then pick another one.
        final t = g.target;
        if (t == null || t == g.cell || ++g.stepsOnTarget > 30) {
          g.target = _randomOpenCell();
          g.stepsOnTarget = 0;
        }
        goal = g.target;
        focus = 0.85;
    }
    if (goal == null || _random.nextDouble() > focus) {
      return options[_random.nextInt(options.length)];
    }
    int dist(PacDirection d) {
      final c = g.cell.step(d);
      return (c.x - goal!.x).abs() + (c.y - goal.y).abs();
    }

    return options.reduce((a, b) => dist(a) <= dist(b) ? a : b);
  }

  Cell _randomOpenCell() {
    while (true) {
      final c = Cell(_random.nextInt(columns), _random.nextInt(rows));
      if (!isWall(c)) return c;
    }
  }

  static PacDirection _reverse(PacDirection d) => switch (d) {
    PacDirection.up => PacDirection.down,
    PacDirection.down => PacDirection.up,
    PacDirection.left => PacDirection.right,
    PacDirection.right => PacDirection.left,
  };

  void _resolve() {
    // Also catch pacman and a ghost swapping cells in the same step.
    final caught = ghosts.any(
      (g) => g.cell == pacman || (g.cell == prevPacman && g.prev == pacman),
    );
    if (caught) {
      status = PacStatus.lost;
    } else if (dots.isEmpty) {
      status = PacStatus.won;
    }
  }
}
