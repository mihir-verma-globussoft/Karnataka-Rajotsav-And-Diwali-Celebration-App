import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Window-width classes (Material 3 guidance).
enum WindowSize {
  compact,
  medium,
  expanded;

  static WindowSize fromWidth(double width) {
    if (width < 600) return compact;
    if (width < 840) return medium;
    return expanded;
  }
}

extension WindowSizeContext on BuildContext {
  /// Subscribes to size changes only; prefer [LayoutBuilder] when a widget
  /// should react to its own constraints rather than the whole window.
  WindowSize get windowSize =>
      WindowSize.fromWidth(MediaQuery.sizeOf(this).width);
}

/// Constrains page content to a readable width and centres it on large
/// screens, so layouts neither overflow small phones nor stretch on tablets.
class ConstrainedBody extends StatelessWidget {
  const ConstrainedBody({
    required this.child,
    this.maxWidth = AppSizes.maxContentWidth,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
