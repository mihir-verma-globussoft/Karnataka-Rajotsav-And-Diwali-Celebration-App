import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import 'sections/countdown_section.dart';
import 'sections/destinations_section.dart';
import 'sections/diwali_section.dart';
import 'sections/diya_game_section.dart';
import 'sections/explorer_section.dart';
import 'sections/greeting_section.dart';
import 'sections/hero_section.dart';
import 'sections/more_section.dart';
import 'sections/quiz_section.dart';
import 'sections/rangoli_section.dart';
import 'theme/diwali_theme.dart';
import 'widgets/deepavali_music.dart';
import 'widgets/diwali_motion.dart';
import 'widgets/glow_background.dart';
import 'widgets/section_reveal.dart';
import 'widgets/utility_bar.dart';

/// Deepavali tab: one festive vertical scroll made of sections.
///
/// Uses a plain [ScrollView] + [Column] (not slivers) so every section key is
/// always mounted and the hero CTA can scroll to any section.
class DeepavaliPage extends StatefulWidget {
  const DeepavaliPage({super.key});

  @override
  State<DeepavaliPage> createState() => _DeepavaliPageState();
}

class _DeepavaliPageState extends State<DeepavaliPage> {
  final ScrollController _scroll = ScrollController();
  final Map<DiwaliSection, GlobalKey> _keys = {
    for (final s in DiwaliSection.values) s: GlobalKey(debugLabel: s.name),
  };

  /// Scrolls so the section's top sits just below the status bar (where the
  /// page content starts), not underneath it and the mute button.
  void _scrollTo(DiwaliSection section) {
    final target = _keys[section]?.currentContext;
    if (target == null || !_scroll.hasClients) return;
    final box = target.findRenderObject();
    if (box is! RenderBox) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final inset = MediaQuery.paddingOf(context).top + AppSpacing.md;
    final position = _scroll.position;
    final offset = (viewport.getOffsetToReveal(box, 0).offset - inset).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(offset);
    } else {
      _scroll.animateTo(
        offset,
        duration: AppDurations.slow,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomClearance = AppSizes.floatingBarClearanceOf(context);
    final top = MediaQuery.paddingOf(context).top;

    return Theme(
      data: DiwaliTheme.data,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // Light icons: the page is always dark, even in system light mode.
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
        ),
        child: DiwaliMotionScope(
          child: DeepavaliMusic(
            child: Scaffold(
              body: Stack(
                children: [
                  const Positioned.fill(child: GlowBackground()),
                  SingleChildScrollView(
                    controller: _scroll,
                    child: ConstrainedBody(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          top + AppSpacing.md,
                          AppSpacing.md,
                          bottomClearance,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RepaintBoundary(
                              child: HeroSection(
                                scrollController: _scroll,
                                onBegin: () =>
                                    _scrollTo(DiwaliSection.explorer),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            KeyedSubtree(
                              key: _keys[DiwaliSection.countdown],
                              child: RepaintBoundary(
                                child: CountdownSection(
                                  onExplore: () =>
                                      _scrollTo(DiwaliSection.explorer),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            KeyedSubtree(
                              key: _keys[DiwaliSection.explorer],
                              child: const SectionReveal(
                                child: ExplorerSection(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            KeyedSubtree(
                              key: _keys[DiwaliSection.destinations],
                              child: const SectionReveal(
                                child: DestinationsSection(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            KeyedSubtree(
                              key: _keys[DiwaliSection.diyaGame],
                              child: const SectionReveal(
                                child: DiyaGameSection(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            KeyedSubtree(
                              key: _keys[DiwaliSection.quiz],
                              child: const SectionReveal(child: QuizSection()),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            KeyedSubtree(
                              key: _keys[DiwaliSection.rangoli],
                              child: const SectionReveal(
                                child: RangoliSection(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            KeyedSubtree(
                              key: _keys[DiwaliSection.greeting],
                              child: const SectionReveal(
                                child: GreetingSection(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            KeyedSubtree(
                              key: _keys[DiwaliSection.more],
                              child: const SectionReveal(child: MoreSection()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: top + AppSpacing.sm,
                    right: AppSpacing.md,
                    child: const MuteButton(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
