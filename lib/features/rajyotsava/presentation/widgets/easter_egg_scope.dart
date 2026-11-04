import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/easter_eggs.dart';
import '../../rajyotsava_providers.dart';
import 'collectible_reveal.dart';

/// Reveals a hidden collectible when the person shakes the phone on this
/// screen, and offers [EasterEggScope.of] for hidden taps to do the same.
///
/// The motion sensor runs only while the screen is on screen (its tab is
/// selected and no other screen is on top) and the app is in the
/// foreground. Shakes are ignored while the keyboard is open, and only one
/// reveal can be open at a time.
class EasterEggScope extends ConsumerStatefulWidget {
  const EasterEggScope({required this.child, super.key});

  final Widget child;

  /// Starts a discovery from a hidden interaction on this screen (a secret
  /// tap). Does nothing outside a scope.
  static Future<void> discover(BuildContext context) async {
    final state = context.findAncestorStateOfType<_EasterEggScopeState>();
    await state?._reveal();
  }

  @override
  ConsumerState<EasterEggScope> createState() => _EasterEggScopeState();
}

class _EasterEggScopeState extends ConsumerState<EasterEggScope> {
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<void>? _shakes;
  var _foreground = true;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        _sync();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  /// Listens to the sensor only while this screen is the one being seen.
  void _sync() {
    final active =
        _foreground &&
        Visibility.of(context) &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (active && _shakes == null) {
      _shakes = ref
          .read(shakeSourceProvider)
          .shakes()
          .listen((_) => _onShake());
    } else if (!active && _shakes != null) {
      unawaited(_shakes!.cancel());
      _shakes = null;
    }
  }

  void _onShake() {
    // Not while typing: shaking with the keyboard open is likely an accident.
    // Read from the window: a Scaffold above may hide the keyboard inset.
    if (View.of(context).viewInsets.bottom > 0) return;
    unawaited(ref.read(hapticsProvider).heavy());
    unawaited(_reveal());
  }

  Future<void> _reveal() async {
    // One reveal at a time across every Rajyotsava screen.
    final manager = ref.read(easterEggManagerProvider.notifier);
    if (manager.revealing || !mounted) return;
    manager.revealing = true;
    try {
      final reveal = await manager.discover();
      if (!mounted) return;
      final photos = ref.read(rajyotsavaContentProvider).photos;
      final photo = switch (reveal) {
        NewCollectible(:final collectible) => photos.byKey(
          collectible.photoKey,
        ),
        CollectionComplete() => null,
      };
      unawaited(ref.read(hapticsProvider).success());
      await showCollectibleReveal(
        context,
        reveal: reveal,
        photo: photo,
        total: ref.read(collectiblesProvider).length,
      );
    } finally {
      manager.revealing = false;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_shakes?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
