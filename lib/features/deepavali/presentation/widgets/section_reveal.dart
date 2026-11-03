import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import 'diwali_motion.dart';

/// Fades and slides a section into place the first time it scrolls into view.
/// It is always in the widget tree (so screen readers, scrolling to it and
/// tests all see it); only its look changes. With motion off it is simply
/// there.
class SectionReveal extends StatefulWidget {
  const SectionReveal({required this.child, super.key});

  final Widget child;

  @override
  State<SectionReveal> createState() => _SectionRevealState();
}

class _SectionRevealState extends State<SectionReveal> {
  ScrollPosition? _position;
  bool _revealed = false;

  /// How far a hidden section sits below its place, as a fraction of its own
  /// height.
  static const double _rise = 0.04;

  /// A section starts to appear once its top is this far up the screen.
  static const double _trigger = 0.92;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_check);
      _position = position;
      position?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (_revealed || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final screen = MediaQuery.sizeOf(context).height;
    if (top < screen * _trigger) setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    final motion = DiwaliMotion.of(context);
    // Nothing is hidden when motion is off, or when there is no scroll view to
    // reveal against.
    if (motion.reduceMotion || _position == null) return widget.child;
    return AnimatedOpacity(
      opacity: _revealed ? 1 : 0,
      duration: AppDurations.entrance,
      child: AnimatedSlide(
        offset: _revealed ? Offset.zero : const Offset(0, _rise),
        duration: AppDurations.entrance,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
