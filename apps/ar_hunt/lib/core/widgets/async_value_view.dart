import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state_views.dart';

/// Renders the standard loading / error / empty / data states for an
/// [AsyncValue], so every feature presents them identically.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.isEmpty,
    this.emptyMessage = 'Nothing here yet.',
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// Optional predicate; when true the empty state is shown.
  final bool Function(T data)? isEmpty;
  final String emptyMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnReload: true,
    loading: () => const LoadingView(),
    error: (error, _) => ErrorView(error: error, onRetry: onRetry),
    data: (d) => (isEmpty?.call(d) ?? false)
        ? EmptyView(message: emptyMessage)
        : data(d),
  );
}
