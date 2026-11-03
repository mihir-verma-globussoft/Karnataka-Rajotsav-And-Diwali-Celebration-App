import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import 'sections/countdown_section.dart';
import 'sections/destinations_section.dart';
import 'sections/diwali_section.dart';
import 'sections/explorer_section.dart';
import 'sections/hero_section.dart';
import 'theme/diwali_theme.dart';
import 'widgets/diwali_motion.dart';
import 'widgets/glow_background.dart';

/// Deepavali tab: one festive vertical scroll made of sections.
///
/// Uses a plain [ScrollView] + [Column] (not slivers) so every section key is
/// always mounted and `Scrollable.ensureVisible` works for the hero CTA.
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

  void _scrollTo(DiwaliSection section) {
    final target = _keys[section]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppDurations.slow,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomClearance =
        AppSizes.floatingBarClearance + MediaQuery.paddingOf(context).bottom;
    final top = MediaQuery.paddingOf(context).top;

    return Theme(
      data: DiwaliTheme.data,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // Light icons: the page is always dark, even in system light mode.
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: DiwaliMotionScope(
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
                          HeroSection(
                            scrollController: _scroll,
                            onBegin: () => _scrollTo(DiwaliSection.explorer),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          KeyedSubtree(
                            key: _keys[DiwaliSection.countdown],
                            child: CountdownSection(
                              onExplore: () =>
                                  _scrollTo(DiwaliSection.explorer),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          KeyedSubtree(
                            key: _keys[DiwaliSection.explorer],
                            child: const ExplorerSection(),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          KeyedSubtree(
                            key: _keys[DiwaliSection.destinations],
                            child: const DestinationsSection(),
                          ),
                          for (final s in DiwaliSection.values)
                            if (s != DiwaliSection.countdown &&
                                s != DiwaliSection.explorer &&
                                s != DiwaliSection.destinations) ...[
                              const SizedBox(height: AppSpacing.xl),
                              KeyedSubtree(
                                key: _keys[s],
                                child: SectionPlaceholder(section: s),
                              ),
                            ],
                        ],
                      ),
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
