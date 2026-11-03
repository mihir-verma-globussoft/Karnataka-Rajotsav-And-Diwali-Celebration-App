import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/feature_module.dart';
import '../../../core/theme/app_tokens.dart';

/// App shell: a floating bottom bar switching between the tabs that features
/// provide. Tabs are built lazily on first visit and then kept alive.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;
  final Set<int> _visited = {0};

  @override
  Widget build(BuildContext context) {
    final tabs = [
      for (final m in ref.watch(featureModulesProvider))
        if (m.tab != null) m.tab!,
    ]..sort((a, b) => a.order.compareTo(b.order));
    if (tabs.isEmpty) return const Scaffold();
    final index = _index.clamp(0, tabs.length - 1);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BottomBar(
        layout: const BottomBarLayout.adaptive(
          maxWidth: AppSizes.bottomBarMaxWidth,
        ),
        showIcon: false,
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: AppRadius.xlAll,
            // A border instead of a shadow: the shadow rendered as a grey
            // rectangle behind the bar and was clipped at the system nav area.
            border: Border.all(color: scheme.outlineVariant),
          ),
        ),
        body: IndexedStack(
          index: index,
          children: [
            for (var i = 0; i < tabs.length; i++)
              _visited.contains(i) || i == index
                  ? Builder(builder: tabs[i].builder)
                  : const SizedBox.shrink(),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _TabButton(
                    key: ValueKey('tab-${tabs[i].label}'),
                    tab: tabs[i],
                    selected: i == index,
                    onTap: () => setState(() {
                      _index = i;
                      _visited.add(i);
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final FeatureTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: ExcludeSemantics(
        // GestureDetector, not InkWell: ink splashes/highlights painted a grey
        // overlay on the bar when switching tabs.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              // Fade from the same hue at alpha 0: animating from Colors.transparent
              // (transparent black) passes through grey.
              color: scheme.secondaryContainer.withValues(
                alpha: selected ? 1 : 0,
              ),
              borderRadius: AppRadius.lgAll,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? tab.selectedIcon : tab.icon, color: color),
                Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
