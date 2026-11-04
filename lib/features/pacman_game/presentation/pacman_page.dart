import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/pacman_tokens.dart';
import '../domain/pacman_game.dart';

/// Pac-Man screen: score bar, the maze (swipe to steer), arrow buttons and
/// overlays for start, level clear and game over. The game pauses when the
/// app goes to the background.
class PacmanPage extends ConsumerStatefulWidget {
  const PacmanPage({super.key});

  @override
  ConsumerState<PacmanPage> createState() => _PacmanPageState();
}

class _PacmanPageState extends ConsumerState<PacmanPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const String _bestKey = 'pacman_best_score';

  /// Finger travel that counts as a swipe.
  static const double _swipeDistance = AppSpacing.lg;

  final PacmanGame _game = PacmanGame();
  final ValueNotifier<double> _clock = ValueNotifier(0);
  late final Ticker _ticker = createTicker(_tick);
  Duration? _last;
  bool _resumed = true;
  int _best = 0;
  Offset _swipe = Offset.zero;

  // What the screen last showed, to rebuild only when it changes.
  GameState _shownState = GameState.ready;
  int _shownScore = 0;
  int _shownLives = PacmanGame.startingLives;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBest();
  }

  Future<void> _loadBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final best = prefs.getInt(_bestKey) ?? 0;
      if (mounted) setState(() => _best = math.max(_best, best));
    } on Object {
      // No storage: the best score just lasts for this visit.
    }
  }

  Future<void> _saveBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestKey, _best);
    } on Object {
      // Ignored: see _loadBest.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _syncTicker();
  }

  void _syncTicker() {
    final running =
        _game.state == GameState.playing || _game.state == GameState.dying;
    if (running && _resumed && !_ticker.isActive) {
      _last = null;
      _ticker.start();
    } else if (!(running && _resumed) && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == null
        ? 0.0
        : math.min(0.05, (elapsed - _last!).inMicroseconds / 1e6);
    _last = elapsed;
    _game.update(dt);
    _clock.value = elapsed.inMicroseconds / 1e6;
    if (_game.state != _shownState ||
        _game.score != _shownScore ||
        _game.lives != _shownLives) {
      _onChanged();
    }
  }

  void _onChanged() {
    final haptics = ref.read(hapticsProvider);
    if (_game.state != _shownState) {
      switch (_game.state) {
        case GameState.dying:
          haptics.error();
        case GameState.levelClear:
          haptics.success();
        case GameState.gameOver:
          haptics.warning();
        case GameState.ready || GameState.playing:
          break;
      }
    }
    if (_game.score > _best) _best = _game.score;
    if (_game.state == GameState.gameOver &&
        _shownState != GameState.gameOver) {
      _saveBest();
    }
    setState(() {
      _shownState = _game.state;
      _shownScore = _game.score;
      _shownLives = _game.lives;
    });
    _syncTicker();
  }

  void _start() {
    _game.start();
    _onChanged();
  }

  void _next() {
    _game.nextLevel();
    _onChanged();
  }

  void _steer(Dir d) {
    if (_game.state == GameState.ready) _start();
    _game.steer(d);
  }

  void _onPan(DragUpdateDetails d) {
    _swipe += d.delta;
    if (_swipe.distance < _swipeDistance) return;
    _steer(
      _swipe.dx.abs() > _swipe.dy.abs()
          ? (_swipe.dx > 0 ? Dir.right : Dir.left)
          : (_swipe.dy > 0 ? Dir.down : Dir.up),
    );
    _swipe = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    const onDark = AppColors.onNight;
    return Scaffold(
      backgroundColor: PacmanPalette.background,
      appBar: AppBar(
        title: const Text('Pac-Man'),
        backgroundColor: PacmanPalette.background,
        foregroundColor: onDark,
      ),
      body: SafeArea(
        child: ConstrainedBody(
          child: Column(
            children: [
              _Hud(game: _game, best: _best),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _game.maze.width / _game.maze.height,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (_) => _swipe = Offset.zero,
                            onPanUpdate: _onPan,
                            child: Semantics(
                              label:
                                  'Pac-Man maze. Score ${_game.score}, '
                                  '${_game.lives} lives left.',
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: _MazePainter(_game, _clock),
                                ),
                              ),
                            ),
                          ),
                          if (_game.state == GameState.ready)
                            _Overlay(
                              title: 'Ready?',
                              message:
                                  'Swipe on the maze or use the arrows to '
                                  'steer.',
                              button: 'Start',
                              onPressed: _start,
                            ),
                          if (_game.state == GameState.levelClear)
                            _Overlay(
                              title: 'Level ${_game.level} cleared!',
                              message:
                                  'Score ${_game.score}. Ghosts get '
                                  'faster next level.',
                              button: 'Next level',
                              onPressed: _next,
                            ),
                          if (_game.state == GameState.gameOver)
                            _Overlay(
                              title: 'Game over',
                              message:
                                  'Score ${_game.score}'
                                  '${_game.score >= _best && _best > 0 ? ' - a new best!' : ''}',
                              button: 'Play again',
                              onPressed: _start,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _DPad(onSteer: _steer),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

/// Score, best score, level and lives on one line. Scales down instead of
/// wrapping so the maze below keeps its room at large text sizes.
class _Hud extends StatelessWidget {
  const _Hud({required this.game, required this.best});

  final PacmanGame game;
  final int best;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget stat(String label, String value) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(color: AppColors.onNightMuted),
        ),
        Text(
          value,
          style: text.titleLarge?.copyWith(color: PacmanPalette.pacman),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            stat('SCORE', '${game.score}'),
            const SizedBox(width: AppSpacing.lg),
            stat('BEST', '$best'),
            const SizedBox(width: AppSpacing.lg),
            stat('LEVEL', '${game.level}'),
            const SizedBox(width: AppSpacing.lg),
            Semantics(
              label: '${game.lives} lives',
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < PacmanGame.startingLives; i++)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: Icon(
                          Icons.circle,
                          size: AppIconSizes.md,
                          color: i < game.lives
                              ? PacmanPalette.pacman
                              : PacmanPalette.wallFill,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.title,
    required this.message,
    required this.button,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.scrim,
        borderRadius: AppRadius.lgAll,
      ),
      child: Center(
        // Scales down rather than overflow on small screens or big text.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.headlineMedium?.copyWith(
                      color: PacmanPalette.pacman,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: AppColors.onNight),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: PacmanPalette.pacman,
                    foregroundColor: AppColors.ink,
                  ),
                  onPressed: onPressed,
                  child: Text(button),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Four big arrow buttons for players who prefer buttons to swiping.
class _DPad extends StatelessWidget {
  const _DPad({required this.onSteer});

  final void Function(Dir) onSteer;

  @override
  Widget build(BuildContext context) {
    Widget key(IconData icon, String label, Dir d) => Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: IconButton.filled(
        tooltip: label,
        onPressed: () => onSteer(d),
        style: IconButton.styleFrom(
          backgroundColor: PacmanPalette.wallFill,
          foregroundColor: PacmanPalette.pacman,
          side: const BorderSide(color: PacmanPalette.wallEdge),
          fixedSize: const Size.square(AppSizes.badgeLarge),
        ),
        icon: Icon(icon, size: AppIconSizes.lg),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        key(Icons.keyboard_arrow_up, 'Up', Dir.up),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            key(Icons.keyboard_arrow_left, 'Left', Dir.left),
            key(Icons.keyboard_arrow_down, 'Down', Dir.down),
            key(Icons.keyboard_arrow_right, 'Right', Dir.right),
          ],
        ),
      ],
    );
  }
}

class _MazePainter extends CustomPainter {
  _MazePainter(this.game, this.clock) : super(repaint: clock);

  final PacmanGame game;
  final ValueNotifier<double> clock;

  // Painter-local geometry, as fractions of one tile.
  static const double _wallRadius = 0.25;
  static const double _edgeWidth = 0.12;
  static const double _dotRadius = 0.12;
  static const double _pelletRadius = 0.3;
  static const double _pelletPulse = 0.07;
  static const double _pacRadius = 0.44;
  static const double _ghostRadius = 0.42;
  static const double _mouthSpeed = 14;
  static const double _mouthMax = 0.3;
  static const double _flashFrom = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final maze = game.maze;
    final cell = math.min(size.width / maze.width, size.height / maze.height);
    final t = clock.value;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(cell * _wallRadius * 2),
      ),
      Paint()..color = PacmanPalette.background,
    );
    _walls(canvas, cell);
    _dots(canvas, cell, t);
    for (final g in game.ghosts) {
      _ghost(canvas, cell, g, t);
    }
    _pac(canvas, cell, t);
  }

  Offset _centre(double cell, double x, double y) =>
      Offset((x + 0.5) * cell, (y + 0.5) * cell);

  void _walls(Canvas canvas, double cell) {
    final maze = game.maze;
    final fill = Paint()..color = PacmanPalette.wallFill;
    final edge = Paint()
      ..color = PacmanPalette.wallEdge
      ..strokeWidth = cell * _edgeWidth
      ..strokeCap = StrokeCap.round;
    for (var y = 0; y < maze.height; y++) {
      for (var x = 0; x < maze.width; x++) {
        if (!maze.isWall(x, y)) continue;
        final r = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        canvas.drawRect(r, fill);
        // A neon line only where a wall meets open floor.
        if (!maze.isWall(x, y - 1)) {
          canvas.drawLine(r.topLeft, r.topRight, edge);
        }
        if (!maze.isWall(x, y + 1)) {
          canvas.drawLine(r.bottomLeft, r.bottomRight, edge);
        }
        if (!maze.isWall(x - 1, y)) {
          canvas.drawLine(r.topLeft, r.bottomLeft, edge);
        }
        if (!maze.isWall(x + 1, y)) {
          canvas.drawLine(r.topRight, r.bottomRight, edge);
        }
      }
    }
  }

  void _dots(Canvas canvas, double cell, double t) {
    final paint = Paint()..color = PacmanPalette.dot;
    final pulse = math.sin(t * 8) * _pelletPulse;
    for (var y = 0; y < game.maze.height; y++) {
      for (var x = 0; x < game.maze.width; x++) {
        if (game.hasDot(x, y)) {
          canvas.drawCircle(
            _centre(cell, x.toDouble(), y.toDouble()),
            cell * _dotRadius,
            paint,
          );
        } else if (game.hasPower(x, y)) {
          canvas.drawCircle(
            _centre(cell, x.toDouble(), y.toDouble()),
            cell * (_pelletRadius + pulse),
            paint,
          );
        }
      }
    }
  }

  void _pac(Canvas canvas, double cell, double t) {
    final p = game.pac;
    final c = _centre(cell, p.x, p.y);
    final facing = switch (p.dir) {
      Dir.right || Dir.none => 0.0,
      Dir.down => math.pi / 2,
      Dir.left => math.pi,
      Dir.up => -math.pi / 2,
    };
    final moving = p.dir != Dir.none && game.state == GameState.playing;
    // Chomping while moving; opening wide to vanish when caught.
    final mouth = game.state == GameState.dying
        ? math.pi * game.deathProgress
        : math.pi *
              _mouthMax *
              (moving ? math.sin(t * _mouthSpeed).abs() : 0.5);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: cell * _pacRadius),
      facing + mouth,
      2 * math.pi - 2 * mouth,
      true,
      Paint()..color = PacmanPalette.pacman,
    );
  }

  void _ghost(Canvas canvas, double cell, Ghost g, double t) {
    if (game.state == GameState.dying) return;
    final c = _centre(cell, g.x, g.y);
    final r = cell * _ghostRadius;
    final scared = game.frightened > 0 && !g.eaten;
    if (!g.eaten) {
      final flash =
          scared && game.frightened < _flashFrom && (t * 6).floor().isEven;
      final colour = !scared
          ? PacmanPalette.ghosts[g.index % PacmanPalette.ghosts.length]
          : flash
          ? PacmanPalette.frightenedFlash
          : PacmanPalette.frightened;
      final body = Path()
        ..moveTo(c.dx - r, c.dy + r)
        ..lineTo(c.dx - r, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: r), math.pi, math.pi, false)
        ..lineTo(c.dx + r, c.dy + r)
        ..lineTo(c.dx + r * 0.66, c.dy + r * 0.7)
        ..lineTo(c.dx + r * 0.33, c.dy + r)
        ..lineTo(c.dx, c.dy + r * 0.7)
        ..lineTo(c.dx - r * 0.33, c.dy + r)
        ..lineTo(c.dx - r * 0.66, c.dy + r * 0.7)
        ..close();
      canvas.drawPath(body, Paint()..color = colour);
    }
    final white = Paint()..color = PacmanPalette.eyeWhite;
    final pupil = Paint()..color = PacmanPalette.pupil;
    for (final side in [-1.0, 1.0]) {
      final eye = Offset(c.dx + side * r * 0.35, c.dy - r * 0.15);
      if (scared) {
        canvas.drawCircle(eye, r * 0.13, white);
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: eye, width: r * 0.55, height: r * 0.7),
          white,
        );
        canvas.drawCircle(
          eye + Offset(g.dir.dx * r * 0.12, g.dir.dy * r * 0.14),
          r * 0.15,
          pupil,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MazePainter old) => true;
}
