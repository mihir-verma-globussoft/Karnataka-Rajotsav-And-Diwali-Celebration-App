import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Standard "permission denied" state used by any feature needing the camera,
/// microphone etc. [onOpenSettings] is supplied by the feature (the permission
/// plugin is chosen by the owner and kept out of `core`).
class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({
    required this.message,
    this.onOpenSettings,
    this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.center,
                    children: [
                      if (onRetry != null)
                        OutlinedButton(
                          onPressed: onRetry,
                          child: const Text('Try again'),
                        ),
                      if (onOpenSettings != null)
                        FilledButton(
                          onPressed: onOpenSettings,
                          child: const Text('Open settings'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
