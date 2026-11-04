import 'dart:math' as math;

/// Pure game rules for Pac-Man: no Flutter, so it is easy to test.
///
/// Positions are in tile units: tile (3, 5) has its centre at x=3, y=5 and
/// every actor moves between tile centres, turning only when it is on one.
enum Dir {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0),
  none(0, 0);

  const Dir(this.dx, this.dy);
  final int dx;
  final int dy;

  Dir get opposite => switch (this) {
    up => down,
    down => up,
    left => right,
    right => left,
    none => none,
  };
}

enum GameState { ready, playing, dying, levelClear, gameOver }

/// The maze: `#` wall, `.` dot, `o` power pellet, `P` Pac-Man's start,
/// `G` a ghost's start, space = empty floor.
class Maze {
  const Maze(this.rows);

  final List<String> rows;

  int get width => rows.first.length;
  int get height => rows.length;

  bool isWall(int x, int y) =>
      x < 0 || y < 0 || x >= width || y >= height || rows[y][x] == '#';

  Iterable<(int, int)> cellsOf(String c) sync* {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (rows[y][x] == c) yield (x, y);
      }
    }
  }

  static const classic = Maze([
    '#################',
    '#o.............o#',
    '#.###.#####.###.#',
    '#...............#',
    '#.###.#.#.#.###.#',
    '#.......G.......#',
    '#.###.#####.###.#',
    '#.....G.G.G.....#',
    '#.###.#####.###.#',
    '#...............#',
    '#.###.#.#.#.###.#',
    '#...............#',
    '#.###.#####.###.#',
    '#.......P.......#',
    '#.###.#####.###.#',
    '#o.............o#',
    '#################',
  ]);
}

class Actor {
  Actor(this.x, this.y, [this.dir = Dir.none]);

  double x;
  double y;
  Dir dir;

  bool get atCentre => x == x.roundToDouble() && y == y.roundToDouble();
  int get tx => x.round();
  int get ty => y.round();
}

class Ghost extends Actor {
  Ghost(super.x, super.y, this.index, {this.releaseIn = 0})
    : homeX = x.round(),
      homeY = y.round();

  final int index;
  final int homeX;
  final int homeY;

  /// Seconds before it leaves its start tile.
  double releaseIn;

  /// Only its eyes remain; it hurries back home, then revives.
  bool eaten = false;
}

class PacmanGame {
  PacmanGame({this.maze = Maze.classic, math.Random? random})
    : _rng = random ?? math.Random() {
    _loadLevel();
  }

  final Maze maze;
  final math.Random _rng;

  // Tuning, in tiles per second and seconds.
  static const double pacSpeed = 5.5;
  static const double ghostSpeed = 4.4;
  static const double ghostSpeedPerLevel = 0.25;
  static const double ghostSpeedMax = 6;
  static const double frightenedSpeed = 3;
  static const double eyesSpeed = 10;
  static const double frightenedSeconds = 6;
  static const double frightenedMin = 2.5;
  static const double hitRadius = 0.6;
  static const double releaseGap = 2;
  static const double deathSeconds = 1.2;
  static const int startingLives = 3;
  static const int dotPoints = 10;
  static const int powerPoints = 50;
  static const int ghostPoints = 200;

  /// How randomly each ghost wanders instead of chasing (0..1).
  static const List<double> _wander = [0.15, 0.3, 0.45, 0.25];

  late Actor pac;
  late List<Ghost> ghosts;
  final Set<int> _dots = {};
  final Set<int> _powers = {};

  int score = 0;
  int lives = startingLives;
  int level = 1;
  GameState state = GameState.ready;

  /// Seconds of "ghosts are edible" left.
  double frightened = 0;
  int _combo = 0;
  double _deathTimer = 0;
  Dir wanted = Dir.none;

  int get dotsLeft => _dots.length + _powers.length;
  bool hasDot(int x, int y) => _dots.contains(y * maze.width + x);
  bool hasPower(int x, int y) => _powers.contains(y * maze.width + x);

  /// 0..1 through Pac-Man's death animation.
  double get deathProgress =>
      state == GameState.dying ? 1 - _deathTimer / deathSeconds : 0;

  double get _ghostSpeed =>
      math.min(ghostSpeedMax, ghostSpeed + ghostSpeedPerLevel * (level - 1));

  void _loadLevel() {
    _dots.clear();
    _powers.clear();
    for (final (x, y) in maze.cellsOf('.')) {
      _dots.add(y * maze.width + x);
    }
    for (final (x, y) in maze.cellsOf('o')) {
      _powers.add(y * maze.width + x);
    }
    _resetPositions();
  }

  void _resetPositions() {
    final (px, py) = maze.cellsOf('P').first;
    pac = Actor(px.toDouble(), py.toDouble());
    wanted = Dir.none;
    var i = 0;
    ghosts = [
      for (final (x, y) in maze.cellsOf('G'))
        Ghost(x.toDouble(), y.toDouble(), i, releaseIn: releaseGap * i++),
    ];
    frightened = 0;
    _combo = 0;
  }

  /// Starts (or restarts after game over) a game.
  void start() {
    if (state == GameState.gameOver) {
      score = 0;
      lives = startingLives;
      level = 1;
      _loadLevel();
    }
    if (state == GameState.ready || state == GameState.gameOver) {
      state = GameState.playing;
    }
  }

  void nextLevel() {
    if (state != GameState.levelClear) return;
    level++;
    _loadLevel();
    state = GameState.playing;
  }

  /// Asks Pac-Man to turn; it does so at the next tile centre it can.
  void steer(Dir d) {
    if (d == Dir.none) return;
    wanted = d;
    // Turning back on itself is allowed mid-corridor.
    if (pac.dir != Dir.none && d == pac.dir.opposite) pac.dir = d;
  }

  void update(double dt) {
    if (state == GameState.dying) {
      _deathTimer -= dt;
      if (_deathTimer <= 0) {
        if (lives <= 0) {
          state = GameState.gameOver;
        } else {
          _resetPositions();
          state = GameState.playing;
        }
      }
      return;
    }
    if (state != GameState.playing) return;
    if (frightened > 0) {
      frightened = math.max(0, frightened - dt);
      if (frightened == 0) _combo = 0;
    }
    _advance(pac, pacSpeed * dt, _choosePac);
    _eat();
    for (final g in ghosts) {
      if (g.releaseIn > 0) {
        g.releaseIn -= dt;
        continue;
      }
      final speed = g.eaten
          ? eyesSpeed
          : frightened > 0
          ? frightenedSpeed
          : _ghostSpeed;
      _advance(g, speed * dt, (a) => _chooseGhost(a as Ghost));
    }
    _collide();
    if (state == GameState.playing && dotsLeft == 0) {
      state = GameState.levelClear;
    }
  }

  void _eat() {
    final key = pac.ty * maze.width + pac.tx;
    if (_dots.remove(key)) score += dotPoints;
    if (_powers.remove(key)) {
      score += powerPoints;
      frightened = math.max(frightenedMin, frightenedSeconds - (level - 1) / 2);
      _combo = 0;
    }
  }

  void _collide() {
    for (final g in ghosts) {
      if (g.eaten) continue;
      final close = math.sqrt(
        math.pow(g.x - pac.x, 2) + math.pow(g.y - pac.y, 2),
      );
      if (close >= hitRadius) continue;
      if (frightened > 0) {
        g.eaten = true;
        score += ghostPoints * (1 << _combo);
        _combo++;
      } else {
        lives--;
        state = GameState.dying;
        _deathTimer = deathSeconds;
        return;
      }
    }
  }

  bool _free(Actor a, Dir d) =>
      d != Dir.none && !maze.isWall(a.tx + d.dx, a.ty + d.dy);

  Dir _choosePac(Actor a) {
    if (_free(a, wanted)) return wanted;
    if (_free(a, a.dir)) return a.dir;
    return Dir.none;
  }

  Dir _chooseGhost(Ghost g) {
    if (g.eaten && g.tx == g.homeX && g.ty == g.homeY) g.eaten = false;
    final options = [
      for (final d in [Dir.up, Dir.left, Dir.down, Dir.right])
        if (_free(g, d) && d != g.dir.opposite) d,
    ];
    if (options.isEmpty) {
      return _free(g, g.dir.opposite) ? g.dir.opposite : Dir.none;
    }
    if (g.eaten) return _closest(g, options, g.homeX, g.homeY);
    if (frightened > 0 || _rng.nextDouble() < _wander[g.index % 4]) {
      return options[_rng.nextInt(options.length)];
    }
    // Pink aims a few tiles ahead of Pac-Man, the others at him.
    final ahead = g.index == 1 ? 4 : 0;
    return _closest(
      g,
      options,
      pac.tx + pac.dir.dx * ahead,
      pac.ty + pac.dir.dy * ahead,
    );
  }

  Dir _closest(Ghost g, List<Dir> options, int tx, int ty) {
    Dir best = options.first;
    var bestD = double.infinity;
    for (final d in options) {
      final dist =
          math.pow(g.tx + d.dx - tx, 2).toDouble() +
          math.pow(g.ty + d.dy - ty, 2).toDouble();
      if (dist < bestD) {
        bestD = dist;
        best = d;
      }
    }
    return best;
  }

  /// Moves [a] up to [dist] tiles, asking [choose] for a direction each time
  /// it reaches a tile centre.
  void _advance(Actor a, double dist, Dir Function(Actor) choose) {
    while (dist > 1e-9) {
      if (a.atCentre) {
        a.dir = choose(a);
        if (a.dir == Dir.none) return;
      }
      final d = _toNextCentre(a);
      final step = math.min(dist, d);
      a.x += a.dir.dx * step;
      a.y += a.dir.dy * step;
      dist -= step;
      if (step == d) {
        a.x = a.x.roundToDouble();
        a.y = a.y.roundToDouble();
      }
    }
  }

  double _toNextCentre(Actor a) {
    if (a.dir.dx != 0) {
      final next = a.dir.dx > 0 ? a.x.floor() + 1 : a.x.ceil() - 1;
      return (next - a.x).abs();
    }
    final next = a.dir.dy > 0 ? a.y.floor() + 1 : a.y.ceil() - 1;
    return (next - a.y).abs();
  }
}
