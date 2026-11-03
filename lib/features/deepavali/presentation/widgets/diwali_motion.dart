import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/settings_notifier.dart';

/// Tells descendants whether the tab is live and whether decorative animation
/// may run, and provides the shared animation clock.
///
/// * [active]: the tab is visible (not hidden by the home shell) and the app
///   is resumed. Timers (countdown, games) should run only while active.
/// * [animate]: [active] and no reduced-motion request. Decorative loops run
///   only while this is true and must show a static equivalent otherwise.
/// * [clock]: elapsed seconds, driven by ONE ticker that runs only while
///   [animate] is true. Painters repaint from it instead of owning tickers.
class DiwaliMotion extends InheritedWidget {
  const DiwaliMotion({
    required this.active,
    required this.animate,
    required this.reduceMotion,
    required this.clock,
    required super.child,
    super.key,
  });

  final bool active;
  final bool animate;
  final bool reduceMotion;
  final ValueListenable<double> clock;

  static DiwaliMotion of(BuildContext context) {
    final m = context.dependOnInheritedWidgetOfExactType<DiwaliMotion>();
    assert(m != null, 'DiwaliMotion missing above ${context.widget}');
    return m!;
  }

  @override
  bool updateShouldNotify(DiwaliMotion old) =>
      active != old.active ||
      animate != old.animate ||
      reduceMotion != old.reduceMotion;
}

/// Computes [DiwaliMotion] from settings, OS preference, tab visibility and
/// app lifecycle.
class DiwaliMotionScope extends ConsumerStatefulWidget {
  const DiwaliMotionScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DiwaliMotionScope> createState() => _DiwaliMotionScopeState();
}

class _DiwaliMotionScopeState extends ConsumerState<DiwaliMotionScope>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  late final Ticker _ticker;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((elapsed) {
      _clock.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    });
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
    final resumed = state == AppLifecycleState.resumed;
    if (resumed != _resumed) setState(() => _resumed = resumed);
  }

  @override
  Widget build(BuildContext context) {
    final pref = ref.watch(diwaliSettingsProvider.select((s) => s.motion));
    final os = MediaQuery.disableAnimationsOf(context);
    // The user can force animations off, but never on against an OS request.
    final reduce = switch (pref) {
      MotionPreference.off => true,
      MotionPreference.on => os,
      MotionPreference.system => os,
    };
    final active = TickerMode.valuesOf(context).enabled && _resumed;
    final animate = active && !reduce;
    if (animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!animate && _ticker.isActive) {
      _ticker.stop();
    }
    return DiwaliMotion(
      active: active,
      animate: animate,
      reduceMotion: reduce,
      clock: _clock,
      child: widget.child,
    );
  }
}
