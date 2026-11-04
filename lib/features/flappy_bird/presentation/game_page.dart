import 'dart:async';

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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
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
      unawaited(_playSystemSound(SystemSoundType.alert));
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

  void _tap() {
    if (_game.phase == GamePhase.gameOver) return;
    _game.tap();
    unawaited(_playSystemSound(SystemSoundType.click));
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
          const DiwaliBackdrop(),
          RepaintBoundary(child: CustomPaint(painter: _GamePainter(_game))),
          _PlayerCharacter(
            game: _game,
            boardSize: constraints.biggest,
            username: widget.player.username,
            avatarUrl: widget.player.displayAvatarUrl,
          ),
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: '${_game.lives} of ${GameSession.maxLives} lives left',
                  child: Row(
                    children: List.generate(
                      GameSession.maxLives,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: _LifeHeart(active: index < _game.lives),
                      ),
                    ),
                  ),
                ),
                ArcadePanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    '${_game.score}',
                    semanticsLabel: 'Score ${_game.score}',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
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

class _GamePainter extends CustomPainter {
  const _GamePainter(this.game);

  final GameSession game;

  @override
  void paint(Canvas canvas, Size size) {
    final pipePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          FlappyPalette.pipeShadow,
          FlappyPalette.pipe,
          FlappyPalette.saffron,
        ],
      ).createShader(Offset.zero & size);
    final pipeOutline = Paint()
      ..color = FlappyPalette.pipeShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
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
      canvas.drawRect(top, pipePaint);
      canvas.drawRect(bottom, pipePaint);
      canvas.drawRect(top, pipeOutline);
      canvas.drawRect(bottom, pipeOutline);
      _decoratePillar(canvas, top);
      _decoratePillar(canvas, bottom);
    }
  }

  void _decoratePillar(Canvas canvas, Rect rect) {
    final band = Paint()
      ..color = FlappyPalette.festivalGold.withValues(
        alpha: ArcadeOpacity.garland,
      );
    for (double y = rect.top + 18; y < rect.bottom; y += 38) {
      canvas.drawRect(Rect.fromLTWH(rect.left, y, rect.width, 4), band);
    }
    final bead = Paint()..color = FlappyPalette.bead;
    for (double x = rect.left + 7; x < rect.right; x += 14) {
      canvas.drawCircle(Offset(x, rect.bottom - 7), 3, bead);
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
    final width = GameSession.birdWidth * boardSize.width;
    final height = GameSession.birdHeight * boardSize.height;
    return Positioned(
      left: GameSession.birdX * boardSize.width,
      top: game.birdY * boardSize.height,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: game.birdVelocity.clamp(-0.5, 0.7).toDouble() * .5,
        child: RepaintBoundary(
          child: Semantics(
            label: '$username flying character',
            image: true,
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
                        style: const TextStyle(fontWeight: FontWeight.w900),
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
        ),
      ),
    );
  }
}
