import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import 'easter_egg_scope.dart';
import 'rajyotsava_motion.dart';

/// A hidden way to find an easter egg: tapping [child] [taps] times in quick
/// succession (or long-pressing it, with [longPress]) reveals a collectible
/// through the screen's [EasterEggScope], with the same no-repeat rule as a
/// shake. The only hint is a small pulse after the second tap.
class SecretTap extends StatefulWidget {
  const SecretTap({
    required this.child,
    this.taps = 5,
    this.longPress = false,
    super.key,
  });

  final Widget child;
  final int taps;
  final bool longPress;

  /// Taps must come within this long of each other to count.
  static const Duration gap = Duration(milliseconds: 900);

  @override
  State<SecretTap> createState() => _SecretTapState();
}

class _SecretTapState extends State<SecretTap> {
  var _count = 0;
  DateTime? _last;
  var _pulse = false;

  /// How much the child grows on a hinting tap.
  static const double _pulseScale = 1.08;

  void _tap() {
    final now = DateTime.now();
    if (_last == null || now.difference(_last!) > SecretTap.gap) _count = 0;
    _last = now;
    _count++;
    if (_count >= widget.taps) {
      _count = 0;
      _found();
      return;
    }
    if (_count >= 2 && !reduceMotion(context)) setState(() => _pulse = true);
  }

  void _found() => EasterEggScope.discover(context);

  @override
  Widget build(BuildContext context) => GestureDetector(
    // Taps still reach anything inside that handles them itself.
    behavior: HitTestBehavior.translucent,
    onTap: widget.longPress ? null : _tap,
    onLongPress: widget.longPress ? _found : null,
    child: AnimatedScale(
      scale: _pulse ? _pulseScale : 1,
      duration: AppDurations.fast,
      // Grow, then settle back.
      onEnd: () {
        if (_pulse) setState(() => _pulse = false);
      },
      child: widget.child,
    ),
  );
}
