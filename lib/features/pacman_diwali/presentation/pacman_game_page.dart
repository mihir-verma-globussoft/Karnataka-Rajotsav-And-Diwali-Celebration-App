import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/pacman_diwali_tokens.dart';
import '../domain/game_music.dart';
import '../domain/game_over_audio.dart';
import '../domain/pacman_engine.dart';
import '../domain/pacman_scoreboard.dart';
import '../pacman_diwali_feature.dart';
import '../pacman_providers.dart';
import 'diwali_sky.dart';
import 'pacman_roster.dart';

/// Classic Pac-Man on a small grid: swipe to steer, eat all dots, avoid ghosts.
class PacmanGamePage extends ConsumerStatefulWidget {
  const PacmanGamePage({super.key, this.setup});

  /// Chosen chasers and selfie; defaults to the first three and no selfie.
  final PacmanSetup? setup;

  @override
  ConsumerState<PacmanGamePage> createState() => _PacmanGamePageState();
}

class _PacmanGamePageState extends ConsumerState<PacmanGamePage>
    with SingleTickerProviderStateMixin {
  // Step lengths: ghosts are slower than the player so there is room to escape.
  static const int _pacMs = 280;
  static const int _ghostMs = 380;

  // A turn that lands late in a step does not wait for the next
  // tick: pacman moves at once, so steering feels immediate.
  static const double _earlyTurnFrom = 0.3;

  // How far a finger must travel before it counts as a swipe, in logical px.
  static const double _swipeDistance = 8;

  final Stopwatch _clock = Stopwatch()..start();
  int _pacStepAt = -100000;
  int _ghostStepAt = -100000;
  // Always repaint: fireworks and flickering diyas keep animating.
  late final Ticker _ticker = createTicker((_) => _repaint.ping());
  final List<_Burst> _bursts = [];

  /// Puts the toran just above the maze (which is centred, fit to width).
  static double _mazeToranTop(Size size) {
    final mazeH = math.min(
      size.height,
      size.width * PacmanEngine.rows / PacmanEngine.columns,
    );
    return math.max(14.0, (size.height - mazeH) / 2 - 6);
  }

  double _progress(int stepAt, int periodMs) =>
      ((_clock.elapsedMilliseconds - stepAt) / periodMs).clamp(0.0, 1.0);

  final _Repaint _repaint = _Repaint();
  late final PacmanEngine _engine = PacmanEngine(onChanged: _onEngineChanged);
  late final GameOverAudio _sound;
  late final GameMusic _music;
  late final PacmanScoreboard _board;
  bool _wasLost = false;
  bool _musicOn = false;
  PacStatus _prevStatus = PacStatus.ready;

  // The finished game's score on the leaderboard: saving, then the result.
  bool _saving = false;
  PacmanSaveOutcome? _saved;
  DateTime _startedAt = DateTime.now();
  final Stopwatch _round = Stopwatch();

  void _onEngineChanged() {
    _repaint.ping();
    final status = _engine.status;
    final lost = status == PacStatus.lost;
    if (lost && !_wasLost) {
      _sound.play();
    } else if (!lost && _wasLost) {
      _sound.stop();
    }
    _wasLost = lost;

    // The song plays only while a game is going, so the game-over sound is
    // heard on its own.
    final playing = status == PacStatus.playing;
    if (playing && !_musicOn) {
      _music.start();
    } else if (!playing && _musicOn) {
      _music.stop();
    }
    _musicOn = playing;

    final over = status == PacStatus.lost || status == PacStatus.won;
    final wasOver =
        _prevStatus == PacStatus.lost || _prevStatus == PacStatus.won;
    if (_prevStatus == PacStatus.ready && status == PacStatus.playing) {
      _startedAt = DateTime.now();
      _round
        ..reset()
        ..start();
    }
    if (over && !wasOver) {
      _round.stop();
      _saveScore();
    } else if (!over && wasOver) {
      _saving = false;
      _saved = null;
    }
    _prevStatus = status;
  }

  Future<void> _saveScore() async {
    if (!_board.isAvailable) return;
    _saving = true;
    _saved = null;
    final outcome = await _board.save(
      PacmanRound.finished(
        score: _engine.score,
        duration: _round.elapsed,
        startedAt: _startedAt,
      ),
    );
    if (mounted && outcome is PacmanSaved) {
      ref.read(arcadeScoreRevisionProvider.notifier).refresh();
    }
    // A new game may have started while the score was being sent.
    if (!mounted || !_saving) return;
    setState(() {
      _saving = false;
      _saved = outcome;
    });
  }

  String? get _scoreLine {
    if (_saving) return 'Saving your score…';
    return switch (_saved) {
      PacmanSaved(:final isNewBest, :final best, :final rounds) =>
        isNewBest
            ? '🏆 New personal best: $best!'
            : 'Your best: $best · Games played: $rounds',
      PacmanQueued() =>
        'Score saved on this phone. It is sent when you are online.',
      _ => null,
    };
  }

  Future<void> _openScores() async {
    // The scores screen has an app bar, so bring the system bars back.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!mounted) return;
    await context.push(PacmanDiwaliRoutes.scores);
    if (mounted) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  Timer? _pacTimer;
  Timer? _ghostTimer;
  bool _mouthOpen = true;
  List<ui.Image> _enemyFaces = const [];
  ui.Image? _selfieFace;

  Future<ui.Image> _decode(Uint8List bytes) async {
    // Decode small: the photos are far larger than a maze cell.
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 256);
    return (await codec.getNextFrame()).image;
  }

  Future<void> _loadFaces() async {
    final faces = <ui.Image>[];
    final picks = widget.setup?.enemyIndexes ?? const [0, 1, 2];
    for (final i in picks.take(3)) {
      final e = pacmanEnemies[i];
      final data = await rootBundle.load(e.sprite);
      faces.add(await _decode(data.buffer.asUint8List()));
    }
    final selfie = widget.setup?.selfie;
    final self = selfie == null ? null : await _decode(selfie);
    if (!mounted) return;
    setState(() {
      _enemyFaces = faces;
      _selfieFace = self;
    });
  }

  @override
  void initState() {
    super.initState();
    // Saved now: `ref` can't be used once the widget is being disposed.
    _sound = ref.read(gameOverAudioProvider);
    _music = ref.read(gameMusicProvider);
    _board = ref.read(pacmanScoreboardProvider);
    _board.sendPending();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadFaces();
    _ticker.start();
    _startPacTimer();
    _ghostTimer = Timer.periodic(const Duration(milliseconds: _ghostMs), (_) {
      _ghostStepAt = _clock.elapsedMilliseconds;
      _engine.stepGhosts();
    });
  }

  void _startPacTimer() {
    _pacTimer?.cancel();
    _pacTimer = Timer.periodic(
      const Duration(milliseconds: _pacMs),
      (_) => _stepPacman(),
    );
  }

  void _stepPacman() {
    _mouthOpen = !_mouthOpen;
    _pacStepAt = _clock.elapsedMilliseconds;
    _engine.stepPacman();
    final eaten = _engine.lastEaten;
    final now = _clock.elapsedMilliseconds;
    _bursts.removeWhere((b) => now - b.startMs > _Burst.lifeMs);
    if (eaten != null) _bursts.add(_Burst(eaten, now));
  }

  @override
  void dispose() {
    _sound.stop();
    _music.stop();
    _ticker.dispose();
    _pacTimer?.cancel();
    _ghostTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _repaint.dispose();
    for (final f in _enemyFaces) {
      f.dispose();
    }
    _selfieFace?.dispose();
    super.dispose();
  }

  Offset _swipe = Offset.zero;

  void _onPointerDown(PointerDownEvent _) => _swipe = Offset.zero;

  /// Adds up the finger's travel, so one clear swipe gives one clear
  /// direction instead of whatever the last tiny movement was. Raw pointer
  /// events: a pan gesture waits for the touch slop before it reports.
  void _onPointerMove(PointerMoveEvent d) {
    _swipe += d.delta;
    if (_swipe.distance < _swipeDistance) return;
    final direction = _swipe.dx.abs() > _swipe.dy.abs()
        ? (_swipe.dx > 0 ? PacDirection.right : PacDirection.left)
        : (_swipe.dy > 0 ? PacDirection.down : PacDirection.up);
    // Start counting again, so a long swipe can still change course.
    _swipe = Offset.zero;
    _steer(direction);
  }

  void _steer(PacDirection direction) {
    final turnsNow =
        _engine.status == PacStatus.playing && _engine.canTurn(direction);
    _engine.steer(direction);
    if (turnsNow && _progress(_pacStepAt, _pacMs) >= _earlyTurnFrom) {
      _stepPacman();
      // The next tick is a full step away again.
      _startPacTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PacmanColors.cFF12002B,
      body: ListenableBuilder(
        listenable: _repaint,
        builder: (context, _) => Stack(
          children: [
            const Positioned.fill(
              child: DiwaliSky(toranTop: _mazeToranTop, loop: true),
            ),
            Center(
              child: AspectRatio(
                aspectRatio: PacmanEngine.columns / PacmanEngine.rows,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _MazePainter(
                          _engine,
                          _mouthOpen,
                          _repaint,
                          _enemyFaces,
                          _selfieFace,
                          _clock,
                          _bursts,
                          () => _progress(_pacStepAt, _pacMs),
                          () => _progress(_ghostStepAt, _ghostMs),
                        ),
                      ),
                      if (_engine.status != PacStatus.playing)
                        _Overlay(
                          engine: _engine,
                          scoreLine: _scoreLine,
                          onScores: _board.isAvailable ? _openScores : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    const BackButton(color: PacmanColors.white),
                    Expanded(
                      child: Text(
                        '🪔 Diyas lit: ${_engine.score}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _gold,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(color: PacmanColors.orange, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _engine.status == PacStatus.paused
                          ? 'Resume'
                          : 'Pause',
                      color: PacmanColors.white,
                      icon: Icon(
                        _engine.status == PacStatus.paused
                            ? Icons.play_arrow
                            : Icons.pause,
                      ),
                      onPressed: _engine.togglePause,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    '🎆 Shubh Deepavali 🎇',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: PacmanColors.deepOrange, blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Maze wall geometry (cell-relative painting, so these are painter constants).
const double _wallRadius = 6;
const double _wallInnerRadius = 8;
const double _wallInset = 5;

const Color _gold = PacmanColors.cFFFFD54F;

/// A burst of sparks where a diya was just lit.
class _Burst {
  _Burst(this.at, this.startMs);
  static const int lifeMs = 800;
  final Cell at;
  final int startMs;
}

/// Bridges the pure-Dart engine's change callback to Flutter listeners.
class _Repaint extends ChangeNotifier {
  void ping() => notifyListeners();
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.engine, this.scoreLine, this.onScores});

  final PacmanEngine engine;

  /// Where the finished game landed on the leaderboard, once known.
  final String? scoreLine;

  /// Opens the scores screen; null when scores are not available.
  final VoidCallback? onScores;

  @override
  Widget build(BuildContext context) {
    final (title, button, action) = switch (engine.status) {
      PacStatus.ready => (
        '🪔 Happy Diwali! 🪔\nLight every diya and dodge the chasers',
        'Play',
        engine.start,
      ),
      PacStatus.paused => ('Paused', 'Resume', engine.togglePause),
      PacStatus.won => (
        '🎆 Happy Diwali! 🎆\nYou lit all ${engine.score} diyas!',
        'Play again',
        () {
          engine
            ..reset()
            ..start();
        },
      ),
      _ => (
        '💥 Caught! 💥\n${engine.score} diyas lit',
        'Restart',
        () {
          engine
            ..reset()
            ..start();
        },
      ),
    };
    return ColoredBox(
      color: PacmanColors.cAA12002B,
      child: Center(
        // Scrolls instead of overflowing on small phones at large text.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(color: PacmanColors.deepOrange, blurRadius: 10),
                  ],
                ),
              ),
              if (scoreLine != null &&
                  (engine.status == PacStatus.lost ||
                      engine.status == PacStatus.won)) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  scoreLine!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: PacmanColors.white),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: PacmanColors.deepOrange,
                ),
                onPressed: action,
                child: Text(button),
              ),
              if (onScores != null) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _gold,
                    side: const BorderSide(color: _gold),
                  ),
                  onPressed: onScores,
                  icon: const Icon(Icons.leaderboard_outlined),
                  label: const Text('Leaderboard'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MazePainter extends CustomPainter {
  _MazePainter(
    this.engine,
    this.mouthOpen,
    Listenable repaint,
    this.faces,
    this.selfie,
    this.clock,
    this.bursts,
    this.pacProgress,
    this.ghostProgress,
  ) : super(repaint: repaint);

  final PacmanEngine engine;
  final bool mouthOpen;
  final List<ui.Image> faces;
  final ui.Image? selfie;
  final Stopwatch clock;
  final List<_Burst> bursts;
  final double Function() pacProgress;
  final double Function() ghostProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / PacmanEngine.columns;
    final ch = size.height / PacmanEngine.rows;
    Rect rect(Cell c) => Rect.fromLTWH(c.x * cw, c.y * ch, cw, ch);
    // Slides between the previous and current cell for smooth movement.
    Rect moving(Cell from, Cell to, double p) => Rect.fromLTWH(
      (from.x + (to.x - from.x) * p) * cw,
      (from.y + (to.y - from.y) * p) * ch,
      cw,
      ch,
    );

    final now = clock.elapsedMilliseconds;
    final secs = now / 1000;

    // Walls: maroon and purple blocks with a gold edge and a tiny rangoli.
    final wallOuter = Paint()..color = PacmanColors.cFF8E1B3A;
    final wallInner = Paint()..color = PacmanColors.cFF4A148C;
    final wallEdge = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final petal = Paint()..color = PacmanColors.cFFFF80AB;
    final marigold = Paint()..color = PacmanColors.cFFFFA000;
    for (final w in engine.walls) {
      final r = rect(w).deflate(1);
      final outer = RRect.fromRectAndRadius(
        r,
        const Radius.circular(_wallRadius),
      );
      canvas.drawRRect(outer, wallOuter);
      canvas.drawRRect(outer, wallEdge);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          r.deflate(_wallInset),
          const Radius.circular(_wallInnerRadius),
        ),
        wallInner,
      );
      final c = r.center;
      for (final o in const [
        Offset(1, 0),
        Offset(-1, 0),
        Offset(0, 1),
        Offset(0, -1),
      ]) {
        canvas.drawCircle(c + o * (cw * 0.13), cw * 0.06, petal);
      }
      canvas.drawCircle(c, cw * 0.07, marigold);
    }

    // Dots are tiny flickering diyas.
    final bowl = Paint()..color = PacmanColors.cFFD2691E;
    final flame = Paint()..color = PacmanColors.cFFFF9800;
    final core = Paint()..color = PacmanColors.cFFFFEB3B;
    final glow = Paint()..color = PacmanColors.c33FFC107;
    for (final d in engine.dots) {
      final c = rect(d).center;
      final f = 1 + 0.18 * math.sin(secs * 9 + c.dx * 0.7 + c.dy * 0.3);
      canvas.drawCircle(c.translate(0, -cw * 0.08), cw * 0.2 * f, glow);
      canvas.drawArc(
        Rect.fromCenter(
          center: c.translate(0, cw * 0.06),
          width: cw * 0.34,
          height: cw * 0.22,
        ),
        0,
        math.pi,
        true,
        bowl,
      );
      final top = c.translate(0, -cw * 0.24 * f);
      final mid = c.translate(0, -cw * 0.06);
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(c.dx + cw * 0.12, c.dy - cw * 0.1, mid.dx, mid.dy)
          ..quadraticBezierTo(
            c.dx - cw * 0.12,
            c.dy - cw * 0.1,
            top.dx,
            top.dy,
          ),
        flame,
      );
      canvas.drawCircle(mid.translate(0, -cw * 0.03), cw * 0.035, core);
    }

    for (var i = 0; i < engine.ghosts.length; i++) {
      final g = engine.ghosts[i];
      final r = moving(g.prev, g.cell, ghostProgress()).deflate(cw * 0.04);
      if (i < faces.length) {
        _drawSprite(canvas, r, faces[i]);
      } else {
        _drawGhost(canvas, r, Color(g.colorValue));
      }
    }

    final r = moving(
      engine.prevPacman,
      engine.pacman,
      pacProgress(),
    ).deflate(cw * 0.08);
    if (selfie != null) {
      _drawFace(canvas, r, selfie!, 1.3, PacmanColors.c99FFD54F);
      _drawBursts(canvas, cw, ch, now);
      return;
    }
    final mouth = mouthOpen ? 0.55 : 0.05;
    canvas.save();
    canvas.translate(r.center.dx, r.center.dy);
    canvas.rotate(engine.facing.angle);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r.shortestSide / 2),
      mouth,
      2 * math.pi - 2 * mouth,
      true,
      Paint()..color = PacmanColors.yellow,
    );
    canvas.restore();
    _drawBursts(canvas, cw, ch, now);
  }

  /// Cracker sparks where diyas were just lit.
  void _drawBursts(Canvas canvas, double cw, double ch, int now) {
    const colors = [
      PacmanColors.cFFFFD54F,
      PacmanColors.cFFFF7043,
      PacmanColors.cFFFF80AB,
    ];
    for (final b in bursts) {
      final age = (now - b.startMs) / _Burst.lifeMs;
      if (age < 0 || age > 1) continue;
      final c = Offset((b.at.x + 0.5) * cw, (b.at.y + 0.5) * ch);
      for (var i = 0; i < 10; i++) {
        final a = i / 10 * 2 * math.pi;
        final dist = cw * (0.2 + age * 0.9);
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * dist,
          cw * 0.06 * (1 - age),
          Paint()..color = colors[i % 3].withValues(alpha: 1 - age),
        );
      }
    }
  }

  /// A ghost illustration: whole image, no clip, feet resting on the cell.
  void _drawSprite(Canvas canvas, Rect cell, ui.Image image) {
    final side = cell.shortestSide * 1.7;
    final box = Rect.fromCenter(
      center: cell.center.translate(0, -cell.height * 0.1),
      width: side,
      height: side,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      box,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  /// A photo as a circle, a little larger than a cell so the face is easy to
  /// recognise. The square crop leans upward to keep faces in portrait photos.
  void _drawFace(
    Canvas canvas,
    Rect cell,
    ui.Image image,
    double scale,
    Color glow,
  ) {
    final side = cell.shortestSide * scale;
    final circle = Rect.fromCenter(
      center: cell.center,
      width: side,
      height: side,
    );
    canvas.drawCircle(circle.center, side * 0.5, Paint()..color = glow);
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final crop = math.min(w, h);
    final src = Rect.fromLTWH((w - crop) / 2, (h - crop) * 0.2, crop, crop);
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    canvas.drawImageRect(
      image,
      src,
      circle,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  void _drawGhost(Canvas canvas, Rect r, Color color) {
    final body = Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.center.dy)
      ..arcToPoint(
        Offset(r.right, r.center.dy),
        radius: Radius.circular(r.width / 2),
      )
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.left + r.width * 0.75, r.bottom - r.height * 0.15)
      ..lineTo(r.center.dx, r.bottom)
      ..lineTo(r.left + r.width * 0.25, r.bottom - r.height * 0.15)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    final white = Paint()..color = PacmanColors.white;
    final pupil = Paint()..color = PacmanColors.blueDeep;
    for (final dx in [0.32, 0.68]) {
      final eye = Offset(r.left + r.width * dx, r.top + r.height * 0.42);
      canvas.drawCircle(eye, r.width * 0.13, white);
      canvas.drawCircle(eye, r.width * 0.06, pupil);
    }
  }

  @override
  bool shouldRepaint(_MazePainter old) =>
      old.mouthOpen != mouthOpen || old.faces != faces || old.selfie != selfie;
}
