import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../team_members.dart';
import 'team_fireworks.dart';

/// Each member gets one of the festival accent colours, in turn.
Color memberAccent(int index) => const [
  AppColors.accentRed,
  AppColors.accentTeal,
  AppColors.accentViolet,
  AppColors.accentSaffron,
  AppColors.accentMagenta,
  AppColors.accentGreen,
][index % 6];

String memberHeroTag(TeamMember m) => 'team-${m.name}';

/// Opens the full-screen, swipeable view starting at [index].
void openMember(BuildContext context, int index) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      transitionDuration: AppDurations.medium,
      reverseTransitionDuration: AppDurations.medium,
      pageBuilder: (_, _, _) => _MemberPager(initial: index),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

/// A member photo, or a person icon when there is no (loadable) photo.
class MemberPhoto extends StatelessWidget {
  const MemberPhoto({super.key, required this.member, this.cacheWidth});

  final TeamMember member;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.secondaryContainer,
      child: Icon(
        Icons.person,
        size: AppIconSizes.xxl,
        color: scheme.onSecondaryContainer,
      ),
    );
    final asset = member.photoAsset;
    if (asset == null) return placeholder;
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: member.photoAlignment,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// Moves its child slightly against the scroll, so a photo seems to float
/// behind its frame. Clip it (ClipRRect) from outside.
class Parallax extends StatelessWidget {
  const Parallax({super.key, required this.child});

  final Widget child;

  static const double _zoom = 1.2;
  static const double _shift = 0.08;

  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final position = scrollable.position;
    return AnimatedBuilder(
      animation: position,
      child: Transform.scale(scale: _zoom, child: child),
      builder: (context, child) {
        final box = context.findRenderObject();
        final view = scrollable.context.findRenderObject();
        var t = 0.0;
        if (box is RenderBox &&
            view is RenderBox &&
            box.hasSize &&
            view.hasSize &&
            box.attached) {
          final centre = box
              .localToGlobal(box.size.center(Offset.zero), ancestor: view)
              .dy;
          t = ((centre / view.size.height) * 2 - 1).clamp(-1.0, 1.0);
        }
        return LayoutBuilder(
          builder: (context, c) => Transform.translate(
            offset: Offset(0, t * c.maxHeight * _shift),
            child: child,
          ),
        );
      },
    );
  }
}

/// Fades and slides its child up into place, once, after [delay]. Skipped
/// when the system asks for reduced motion.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  static const Offset _from = Offset(0, 0.15);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDurations.entrance + widget.delay,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMilliseconds / _c.duration!.inMilliseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _t,
    child: SlideTransition(
      position: Tween(begin: _from, end: Offset.zero).animate(_t),
      child: widget.child,
    ),
  );
}

class _MemberPager extends ConsumerStatefulWidget {
  const _MemberPager({required this.initial});

  final int initial;

  @override
  ConsumerState<_MemberPager> createState() => _MemberPagerState();
}

class _MemberPagerState extends ConsumerState<_MemberPager> {
  late final PageController _controller = PageController(
    initialPage: widget.initial,
  );
  late int _page = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text('${_page + 1} of ${teamMembers.length}'),
      ),
      body: FireworkShow(
        accent: memberAccent(_page),
        showKey: _page,
        onBurst: ref.read(hapticsProvider).heavy,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: teamMembers.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final m = teamMembers[i];
                    final accent = memberAccent(i);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1,
                          colors: [
                            accent.withValues(alpha: AppOpacity.glow),
                            AppColors.transparent,
                          ],
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: ConstrainedBody(
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: Hero(
                                  tag: memberHeroTag(m),
                                  child: DecoratedBox(
                                    position: DecorationPosition.foreground,
                                    decoration: BoxDecoration(
                                      borderRadius: AppRadius.xlAll,
                                      border: Border.all(
                                        color: accent,
                                        width: AppSizes.ring,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: AppRadius.xlAll,
                                      child: MemberPhoto(member: m),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Reveal(
                                delay: AppDurations.stagger,
                                child: Column(
                                  children: [
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        m.name,
                                        textAlign: TextAlign.center,
                                        style: text.headlineMedium,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Tap anywhere for fireworks. Swipe for the next member.',
                                      textAlign: TextAlign.center,
                                      style: text.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < teamMembers.length; i++)
                      AnimatedContainer(
                        duration: AppDurations.fast,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        width: i == _page ? AppSizes.dotActive : AppSizes.dot,
                        height: AppSizes.dot,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.lgAll,
                          color: i == _page
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
