import 'package:flutter/widgets.dart';

/// Gives everything inside it an [Overlay].
///
/// The access gate (login, avatar setup, countdown, paused) is built in
/// `MaterialApp.router`'s `builder`, which sits above the router's Navigator
/// and so has no Overlay of its own. Tooltips (the sign-out button), menus and
/// text selection all need one: without it they throw "No Overlay widget
/// found", and the broken layout shows up as a huge overflow.
class RootOverlay extends StatefulWidget {
  const RootOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<RootOverlay> createState() => _RootOverlayState();
}

class _RootOverlayState extends State<RootOverlay> {
  late final OverlayEntry _entry = OverlayEntry(
    builder: (context) => widget.child,
  );

  @override
  void didUpdateWidget(RootOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    // An entry must leave its overlay before it is disposed.
    _entry
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}
