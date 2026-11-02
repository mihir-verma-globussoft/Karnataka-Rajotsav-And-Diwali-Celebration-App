import 'package:flutter/material.dart';

import '../errors/app_failure.dart';
import '../theme/app_tokens.dart';

/// Standard loading indicator.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator.adaptive());
}

/// Standard empty state.
class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _Message(icon: icon, message: message);
}

/// Standard error state with optional retry.
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.error,
    this.onRetry,
    this.retryLabel = 'Retry',
    super.key,
  });

  final Object error;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => _Message(
    icon: Icons.error_outline,
    message: error is AppFailure
        ? (error as AppFailure).message
        : const UnexpectedFailure().message,
    action: onRetry == null
        ? null
        : OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Scrollable so large text scales or landscape never overflow.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (action != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
