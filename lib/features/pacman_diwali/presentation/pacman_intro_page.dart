import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/pacman_diwali_tokens.dart';
import '../pacman_diwali_feature.dart';
import 'diwali_sky.dart';
import 'pacman_characters.dart';
import 'pacman_roster.dart';

const Color _gold = PacmanColors.cFFFFD54F;
const Color _night = PacmanColors.cFF12002B;
const Color _glow = PacmanColors.deepOrange;

/// Meet the chasers, pick three, then take a selfie: the selfie becomes the
/// player. Tap a character to watch it perform for a few seconds.
class PacmanIntroPage extends StatefulWidget {
  const PacmanIntroPage({super.key});

  @override
  State<PacmanIntroPage> createState() => _PacmanIntroPageState();
}

class _PacmanIntroPageState extends State<PacmanIntroPage> {
  static const int _needed = 3;

  bool _busy = false;
  final List<int> _picked = [];

  void _toggle(int i) {
    if (_picked.contains(i)) {
      setState(() => _picked.remove(i));
    } else if (_picked.length >= _needed) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Only 3 chasers. Unselect one to pick another.'),
          ),
        );
    } else {
      setState(() => _picked.add(i));
    }
  }

  Future<void> _takeSelfie() async {
    setState(() => _busy = true);
    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: PacmanSizes.selfieMaxWidth,
        imageQuality: 85,
      );
      if (shot == null || !mounted) return;
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      await context.push(
        PacmanDiwaliRoutes.play,
        extra: PacmanSetup(selfie: bytes, enemyIndexes: List.of(_picked)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _perform(PacmanEnemy enemy) => showDialog<void>(
    context: context,
    barrierColor: PacmanColors.black87,
    builder: (_) => _Showcase(enemy: enemy),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: _night,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: PacmanColors.transparent,
        elevation: 0,
        foregroundColor: PacmanColors.white,
        iconTheme: const IconThemeData(
          size: PacmanSizes.barIcon,
          color: PacmanColors.white,
        ),
        actionsIconTheme: const IconThemeData(
          size: PacmanSizes.barIcon,
          color: PacmanColors.white,
        ),
        title: const Text('Diwali Pac-Man'),
        actions: [
          IconButton(
            tooltip: 'Scores and leaderboard',
            onPressed: () => context.push(PacmanDiwaliRoutes.scores),
            icon: const Icon(Icons.leaderboard_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DiwaliSky(toranTop: _toranTopBelowBar(context)),
          ),
          SafeArea(
            child: ConstrainedBody(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        const SizedBox(height: _toranClearance),
                        Semantics(
                          header: true,
                          child: Text(
                            '🪔 Shubh Deepavali! 🪔',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: _gold,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(color: _glow, blurRadius: 12),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Pick $_needed chasers out of ${pacmanEnemies.length} '
                          '(${_picked.length}/$_needed).\n'
                          'Tap a card to see its power, tick the circle to pick.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: PacmanColors.white70,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (var i = 0; i < pacmanEnemies.length; i++)
                          _EnemyCard(
                            enemy: pacmanEnemies[i],
                            selected: _picked.contains(i),
                            pickKey: ValueKey('pick_$i'),
                            onTap: () => _perform(pacmanEnemies[i]),
                            onPick: () => _toggle(i),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _glow,
                          minimumSize: const Size.fromHeight(
                            AppSizes.minTouchTarget,
                          ),
                        ),
                        onPressed: _busy || _picked.length != _needed
                            ? null
                            : _takeSelfie,
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          size: PacmanSizes.buttonIcon,
                        ),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Selfie & play'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The toran hangs under the app bar, not behind its back button and title.
double Function(Size) _toranTopBelowBar(BuildContext context) {
  final top =
      MediaQuery.paddingOf(context).top + kToolbarHeight + PacmanSizes.toranGap;
  return (_) => top;
}

/// Room for the toran at the top of the scrolling content (the safe area
/// already clears the status bar).
const double _toranClearance = kToolbarHeight + PacmanSizes.toranBand;

const Animation<double> _still = AlwaysStoppedAnimation(0);

class _EnemyCard extends StatelessWidget {
  const _EnemyCard({
    required this.enemy,
    required this.selected,
    required this.pickKey,
    required this.onTap,
    required this.onPick,
  });

  final PacmanEnemy enemy;
  final bool selected;
  final Key pickKey;
  final VoidCallback onTap;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: selected ? PacmanColors.cCC4A1070 : PacmanColors.c99200040,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(
            color: selected ? PacmanColors.deepOrangeAccent : _gold,
            width: selected ? 3 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: PacmanSizes.cardStage,
                  height: PacmanSizes.cardStage,
                  child: CartoonCharacter(
                    kind: enemy.kind,
                    photoAsset: enemy.asset,
                    animation: _still,
                    active: false,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enemy.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        enemy.tagline,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: PacmanColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PowerChip(enemy: enemy),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '👆 Tap to see it in action',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: PacmanColors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: pickKey,
                  tooltip: selected ? 'Remove chaser' : 'Pick as chaser',
                  iconSize: AppIconSizes.lg,
                  color: selected ? PacmanColors.deepOrangeAccent : _gold,
                  icon: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  onPressed: onPick,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The character's superpower on a chip in its signature colour.
class _PowerChip extends StatelessWidget {
  const _PowerChip({required this.enemy});

  final PacmanEnemy enemy;

  @override
  Widget build(BuildContext context) {
    final color = Color(enemy.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: PacmanOpacity.chipFill),
        border: Border.all(color: color),
        borderRadius: AppRadius.mdAll,
      ),
      child: Text(
        enemy.power,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: PacmanColors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Big popup: the character performs for four seconds, then it closes.
class _Showcase extends StatefulWidget {
  const _Showcase({required this.enemy});

  final PacmanEnemy enemy;

  @override
  State<_Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<_Showcase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: PacmanDurations.performCycle,
  );
  Timer? _close;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _close = Timer(AppDurations.celebration, () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // With reduced motion the character holds a pose instead of looping.
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.value = 0.35;
    } else {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _close?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.enemy;
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: PacmanColors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: ClipRRect(
          borderRadius: AppRadius.xlAll,
          child: Stack(
            children: [
              const Positioned.fill(child: DiwaliSky(toranTop: _showcaseToran)),
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      e.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: _gold,
                        fontWeight: FontWeight.bold,
                        shadows: const [Shadow(color: _glow, blurRadius: 12)],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: PacmanSizes.popupStage,
                      height: PacmanSizes.popupStage,
                      child: CartoonCharacter(
                        kind: e.kind,
                        photoAsset: e.asset,
                        animation: _anim,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      e.tagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: PacmanColors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PowerChip(enemy: e),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      e.attack,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: PacmanColors.white70,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _showcaseToran(Size size) => AppSpacing.sm;
}
