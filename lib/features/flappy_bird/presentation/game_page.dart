import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/game_result.dart';
import '../domain/game_session.dart';
import '../domain/player.dart';
import '../flappy_bird_feature.dart';
import '../flappy_bird_providers.dart';
import 'widgets/arcade_widgets.dart';

class FlappyGameView extends ConsumerStatefulWidget {
  const FlappyGameView({required this.player, super.key});

  final PlayerProfile player;

  @override
  ConsumerState<FlappyGameView> createState() => _FlappyGameViewState();
}

class _FlappyGameViewState extends ConsumerState<FlappyGameView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  final GameSession _game = GameSession();
  Duration? _previousTick;
  bool _submitting = false;
  bool _submitted = false;
  GameSubmission? _submission;
  String? _submissionMessage;
  bool _avatarPrecached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game.startNewGame();
    _ticker = createTicker(_tick)..start();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: FlappyPalette.midnight.withValues(alpha: 0),
        systemNavigationBarColor: FlappyPalette.midnight.withValues(alpha: 0),
        systemNavigationBarDividerColor: FlappyPalette.midnight.withValues(
          alpha: 0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    unawaited(ref.read(flappyBackgroundMusicProvider).stop());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final avatarUrl = widget.player.displayAvatarUrl;
    if (!_avatarPrecached && avatarUrl != null) {
      _avatarPrecached = true;
      unawaited(precacheImage(NetworkImage(avatarUrl), context));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _game.resumeAfterLifecycle();
      _previousTick = null;
      if (!_ticker.isActive) _ticker.start();
      setState(() {});
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _game.pauseForLifecycle();
      _ticker.stop();
      unawaited(ref.read(flappyBackgroundMusicProvider).pause());
    }
  }

  void _tick(Duration elapsed) {
    final previous = _previousTick;
    _previousTick = elapsed;
    if (previous == null || !mounted) return;
    final oldPhase = _game.phase;
    _game.update((elapsed - previous).inMicroseconds / 1000000);
    if (_game.phase != oldPhase &&
        (_game.phase == GamePhase.lifeLost ||
            _game.phase == GamePhase.gameOver)) {
      unawaited(ref.read(flappyBackgroundMusicProvider).stop());
      unawaited(_playDeathSound());
    }
    if (_game.phase == GamePhase.gameOver && !_submitted && !_submitting) {
      unawaited(_submitScore());
      _ticker.stop();
    }
    setState(() {});
  }

  Future<void> _playSystemSound(SystemSoundType type) async {
    final preferences = ref.read(gamePreferencesProvider).value;
    if (preferences?.soundEffectsEnabled ?? true) {
      await SystemSound.play(type);
    }
  }

  Future<void> _startBackgroundMusic() async {
    final preferences = await ref.read(gamePreferencesProvider.future);
    if (preferences.backgroundMusicEnabled) {
      await ref.read(flappyBackgroundMusicProvider).play();
    }
  }

  Future<void> _playDeathSound() async {
    final preferences = ref.read(gamePreferencesProvider).value;
    if (preferences?.soundEffectsEnabled ?? true) {
      await ref.read(flappyDeathAudioProvider).play();
    }
  }

  void _tap() {
    if (_game.phase == GamePhase.gameOver) return;
    if (_game.phase == GamePhase.paused) {
      _resumeGame();
      return;
    }
    final phaseBeforeTap = _game.phase;
    _game.tap();
    if (phaseBeforeTap == GamePhase.ready ||
        phaseBeforeTap == GamePhase.lifeLost) {
      unawaited(_startBackgroundMusic());
    }
    unawaited(_playSystemSound(SystemSoundType.click));
    setState(() {});
  }

  void _togglePause() {
    if (_game.phase == GamePhase.playing) {
      _game.pause();
      unawaited(ref.read(flappyBackgroundMusicProvider).pause());
    } else if (_game.phase == GamePhase.paused) {
      _resumeGame();
      return;
    }
    setState(() {});
  }

  void _resumeGame() {
    _game.resume();
    _previousTick = null;
    unawaited(_startBackgroundMusic());
    setState(() {});
  }

  Future<void> _submitScore() async {
    final result = _game.result;
    setState(() {
      _submitting = true;
      _submissionMessage = null;
    });
    try {
      final value = await ref
          .read(scoreSubmissionServiceProvider)
          .submit(result);
      if (!mounted || _game.gameId != result.gameId) return;
      setState(() {
        _submission = value;
        _submitted = true;
        _submissionMessage = 'Score saved';
      });
      ref.invalidate(dashboardProvider);
    } on Object catch (error) {
      if (!mounted || _game.gameId != result.gameId) return;
      setState(() {
        _submitted = false;
        _submissionMessage = error is AppFailure
            ? error.message
            : 'Score pending — tap Retry when online.';
      });
    } finally {
      // The Diwali arcade section may still be listening below this route.
      if (mounted) ref.invalidate(recentScoreProvider);
      if (mounted && _game.gameId == result.gameId) {
        setState(() => _submitting = false);
      }
    }
  }

  void _playAgain() {
    unawaited(ref.read(flappyBackgroundMusicProvider).stop());
    _game.startNewGame();
    _previousTick = null;
    _submitting = false;
    _submitted = false;
    _submission = null;
    _submissionMessage = null;
    if (!_ticker.isActive) _ticker.start();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/flappy_bird/game_background.png',
            fit: BoxFit.cover,
          ),
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _FirecrackerPainter(
                  elapsed: _game.elapsed,
                  active: _game.phase == GamePhase.playing,
                ),
              ),
            ),
          ),
          RepaintBoundary(child: CustomPaint(painter: _GamePainter(_game))),
          _PlayerCharacter(
            game: _game,
            boardSize: constraints.biggest,
            username: widget.player.username,
            avatarUrl: widget.player.displayAvatarUrl,
          ),
          Positioned(
            top: 0,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GameHeader(
                    score: _game.score,
                    paused: _game.phase == GamePhase.paused,
                    onBack: () => context.canPop()
                        ? context.pop()
                        : context.go(FlappyBirdRoutes.root),
                    onPause: _togglePause,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _LifeCluster(lives: _game.lives),
                  ),
                ],
              ),
            ),
          ),
          if (_game.phase == GamePhase.ready ||
              _game.phase == GamePhase.lifeLost ||
              _game.phase == GamePhase.paused)
            _ReadyOverlay(game: _game),
          if (_game.phase == GamePhase.gameOver)
            _GameOverOverlay(
              score: _game.score,
              livesUsed: _game.livesUsed,
              submission: _submission,
              submissionMessage: _submissionMessage,
              submitting: _submitting,
              onRetry: _submitScore,
              onPlayAgain: _playAgain,
              onHome: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(FlappyBirdRoutes.root);
                }
              },
              onLeaderboard: () => context.push(FlappyBirdRoutes.leaderboard),
            ),
        ],
      ),
    ),
  );
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.score,
    required this.paused,
    required this.onBack,
    required this.onPause,
  });

  final int score;
  final bool paused;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSizes.minTouchTarget,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox.square(
            dimension: AppSizes.minTouchTarget,
            child: IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: FlappyPalette.white,
              ),
            ),
          ),
        ),
        Semantics(
          label: 'Score $score',
          child: Text(
            '🐦  Score: $score',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: FlappyPalette.festivalGold,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(
                  color: FlappyPalette.glow,
                  blurRadius: ArcadeSizes.scoreGlow,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox.square(
            dimension: AppSizes.minTouchTarget,
            child: IconButton(
              tooltip: paused ? 'Resume game' : 'Pause game',
              onPressed: onPause,
              icon: Icon(
                paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: FlappyPalette.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _LifeCluster extends StatelessWidget {
  const _LifeCluster({required this.lives});

  final int lives;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$lives of ${GameSession.maxLives} lives left',
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: FlappyPalette.panel.withValues(alpha: ArcadeOpacity.scrimLight),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: FlappyPalette.festivalGold.withValues(
            alpha: ArcadeOpacity.hairline,
          ),
          width: ArcadeSizes.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          GameSession.maxLives,
          (index) => Padding(
            padding: EdgeInsets.only(
              right: index == GameSession.maxLives - 1 ? 0 : AppSpacing.xs,
            ),
            child: _LifeHeart(active: index < lives),
          ),
        ),
      ),
    ),
  );
}

class _LifeHeart extends StatelessWidget {
  const _LifeHeart({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 260),
    transitionBuilder: (child, animation) => ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: animation, child: child),
    ),
    child: Icon(
      active
          ? Icons.local_fire_department
          : Icons.local_fire_department_outlined,
      key: ValueKey(active),
      color: active ? FlappyPalette.festivalGold : FlappyPalette.white38,
      size: ArcadeSizes.lifeIcon,
    ),
  );
}

class _ReadyOverlay extends StatelessWidget {
  const _ReadyOverlay({required this.game});

  final GameSession game;

  @override
  Widget build(BuildContext context) {
    final message = switch (game.phase) {
      GamePhase.lifeLost => 'Life lost • ${game.lives} remaining',
      GamePhase.paused => 'Game paused',
      _ => 'Tap to light up the sky',
    };
    return Center(
      child: ArcadePanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text('Tap anywhere to continue'),
          ],
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.livesUsed,
    required this.submission,
    required this.submissionMessage,
    required this.submitting,
    required this.onRetry,
    required this.onPlayAgain,
    required this.onHome,
    required this.onLeaderboard,
  });

  final int score;
  final int livesUsed;
  final GameSubmission? submission;
  final String? submissionMessage;
  final bool submitting;
  final VoidCallback onRetry;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;
  final VoidCallback onLeaderboard;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ArcadeSizes.panelMaxWidth),
        child: ArcadePanel(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GAME OVER',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Final score: $score'),
              Text('Personal best: ${submission?.highScore ?? '—'}'),
              Text('Lives used: $livesUsed'),
              if (submission?.isNewHighScore ?? false)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'NEW HIGH SCORE!',
                    style: TextStyle(
                      color: FlappyPalette.pipeShadow,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (submissionMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(submissionMessage!, textAlign: TextAlign.center),
              ],
              if (submitting)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: CircularProgressIndicator.adaptive(),
                )
              else if (submission == null)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.sync),
                  label: const Text('Retry score save'),
                ),
              const SizedBox(height: AppSpacing.sm),
              ArcadeActionButton(
                label: 'PLAY AGAIN',
                icon: Icons.replay,
                primary: true,
                onPressed: onPlayAgain,
              ),
              const SizedBox(height: AppSpacing.sm),
              ArcadeActionButton(
                label: 'LEADERBOARD',
                icon: Icons.leaderboard_outlined,
                onPressed: onLeaderboard,
              ),
              const SizedBox(height: AppSpacing.sm),
              ArcadeActionButton(
                label: 'HOME',
                icon: Icons.home_outlined,
                onPressed: onHome,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Ambient festival firecrackers animated from the game clock, so they pause
/// alongside gameplay and never affect collision or score calculations.
class _FirecrackerPainter extends CustomPainter {
  const _FirecrackerPainter({required this.elapsed, required this.active});

  final Duration elapsed;
  final bool active;

  static const _centers = <Offset>[
    Offset(.12, .20),
    Offset(.84, .29),
    Offset(.38, .13),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    final seconds = elapsed.inMilliseconds / Duration.millisecondsPerSecond;
    for (var index = 0; index < _centers.length; index++) {
      final phase = (seconds + index * 1.1) % 3.6;
      if (phase > 1.5) continue;
      final progress = phase / 1.5;
      final opacity = (1 - progress).clamp(0.0, 1.0).toDouble();
      final center = Offset(
        _centers[index].dx * size.width,
        _centers[index].dy * size.height,
      );
      final maxRadius = size.shortestSide * .13;
      final color = switch (index) {
        0 => FlappyPalette.festivalGold,
        1 => FlappyPalette.sparkPink,
        _ => FlappyPalette.saffron,
      };
      final paint = Paint()
        ..color = color.withValues(alpha: opacity * ArcadeOpacity.garland)
        ..strokeWidth = ArcadeSizes.hairline * 2
        ..strokeCap = StrokeCap.round;
      for (var spark = 0; spark < 14; spark++) {
        final angle = spark * math.pi * 2 / 14;
        final direction = Offset(math.cos(angle), math.sin(angle));
        final inner = center + direction * (maxRadius * progress * .3);
        final outer = center + direction * (maxRadius * progress);
        canvas.drawLine(inner, outer, paint);
        canvas.drawCircle(outer, ArcadeSizes.hairline * 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FirecrackerPainter oldDelegate) =>
      oldDelegate.elapsed != elapsed || oldDelegate.active != active;
}

class _GamePainter extends CustomPainter {
  const _GamePainter(this.game);

  final GameSession game;

  @override
  void paint(Canvas canvas, Size size) {
    for (final pipe in game.pipes) {
      final x = pipe.x * size.width;
      final width = GameSession.pipeWidth * size.width;
      final gapTop = (pipe.gapCenter - GameSession.pipeGap / 2) * size.height;
      final gapBottom =
          (pipe.gapCenter + GameSession.pipeGap / 2) * size.height;
      final top = Rect.fromLTWH(x, 0, width, gapTop);
      final bottom = Rect.fromLTRB(
        x,
        gapBottom,
        x + width,
        GameSession.groundY * size.height,
      );
      _drawPillar(canvas, top);
      _drawPillar(canvas, bottom);
    }
  }

  void _drawPillar(Canvas canvas, Rect rect) {
    final pillar = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(AppRadius.sm),
    );
    final silhouette = Path()..addRRect(pillar);
    canvas.drawShadow(
      silhouette,
      FlappyPalette.pipeShadow.withValues(alpha: ArcadeOpacity.shadow),
      ArcadeSizes.obstacleShadow,
      false,
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          FlappyPalette.pipeShadow,
          FlappyPalette.pipe,
          FlappyPalette.saffron,
        ],
      ).createShader(rect);
    final outline = Paint()
      ..color = FlappyPalette.pipeShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = ArcadeSizes.obstacleOutline;
    canvas
      ..drawRRect(pillar, paint)
      ..drawRRect(pillar, outline);
    _decoratePillar(canvas, rect);
  }

  void _decoratePillar(Canvas canvas, Rect rect) {
    final band = Paint()
      ..color = FlappyPalette.festivalGold.withValues(
        alpha: ArcadeOpacity.garland,
      );
    for (
      double y = rect.top + ArcadeSizes.obstacleBandStart;
      y < rect.bottom;
      y += ArcadeSizes.obstacleBandGap
    ) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rect.left,
            y,
            rect.width,
            ArcadeSizes.obstacleBandHeight,
          ),
          const Radius.circular(AppRadius.xs),
        ),
        band,
      );
    }
    final bead = Paint()..color = FlappyPalette.bead;
    for (
      double x = rect.left + ArcadeSizes.obstacleBeadInset;
      x < rect.right;
      x += ArcadeSizes.obstacleBeadGap
    ) {
      canvas.drawCircle(
        Offset(x, rect.bottom - ArcadeSizes.obstacleBeadInset),
        ArcadeSizes.obstacleBeadRadius,
        bead,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GamePainter oldDelegate) => true;
}

class _PlayerCharacter extends StatelessWidget {
  const _PlayerCharacter({
    required this.game,
    required this.boardSize,
    required this.username,
    required this.avatarUrl,
  });

  final GameSession game;
  final Size boardSize;
  final String username;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final avatarDiameter = (GameSession.birdHeight * boardSize.height)
        .clamp(ArcadeSizes.birdMinSize, ArcadeSizes.birdMaxSize)
        .toDouble();
    final wingWidth = avatarDiameter * 1.8;
    final wingHeight = avatarDiameter * 1.35;
    return Positioned(
      left:
          GameSession.birdX * boardSize.width -
          (wingWidth - avatarDiameter) / 2,
      top: game.birdY * boardSize.height - (wingHeight - avatarDiameter) / 2,
      width: wingWidth,
      height: wingHeight,
      child: Transform.rotate(
        angle: game.birdVelocity.clamp(-0.5, 0.7).toDouble() * .5,
        child: RepaintBoundary(
          child: Semantics(
            label: '$username flying character',
            image: true,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _WingPainter()),
                ),
                SizedBox(
                  width: avatarDiameter,
                  height: avatarDiameter,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FlappyPalette.gold,
                      border: Border.all(
                        color: FlappyPalette.festivalGold,
                        width: ArcadeSizes.ringThin,
                      ),
                      boxShadow: const [
                        BoxShadow(color: FlappyPalette.glow, blurRadius: 10),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: avatarUrl == null
                        ? Center(
                            child: Text(
                              username.isEmpty
                                  ? '?'
                                  : username.characters.first.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          )
                        : Image.network(
                            avatarUrl!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.low,
                            errorBuilder: (_, _, _) => const Icon(Icons.person),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WingPainter extends CustomPainter {
  const _WingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [FlappyPalette.festivalGold, FlappyPalette.white],
      ).createShader(Offset.zero & size);
    final outline = Paint()
      ..color = FlappyPalette.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = ArcadeSizes.hairline;
    final center = Offset(size.width / 2, size.height / 2);
    final left = Path()
      ..moveTo(center.dx - size.width * .08, center.dy)
      ..quadraticBezierTo(
        size.width * .08,
        size.height * .08,
        size.width * .03,
        size.height * .46,
      )
      ..quadraticBezierTo(
        size.width * .28,
        size.height * .30,
        center.dx - size.width * .12,
        center.dy + size.height * .08,
      )
      ..close();
    final right = Path()
      ..moveTo(center.dx + size.width * .08, center.dy)
      ..quadraticBezierTo(
        size.width * .92,
        size.height * .08,
        size.width * .97,
        size.height * .46,
      )
      ..quadraticBezierTo(
        size.width * .72,
        size.height * .30,
        center.dx + size.width * .12,
        center.dy + size.height * .08,
      )
      ..close();
    canvas
      ..drawPath(left, paint)
      ..drawPath(right, paint)
      ..drawPath(left, outline)
      ..drawPath(right, outline);
  }

  @override
  bool shouldRepaint(covariant _WingPainter oldDelegate) => false;
}
