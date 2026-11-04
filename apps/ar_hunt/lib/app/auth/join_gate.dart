import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/state_views.dart';
import '../../features/ar/ar_providers.dart';
import '../../features/ar/domain/hunt_models.dart';
import '../../features/ar/presentation/widgets/hunt_widgets.dart';
import 'hunt_auth.dart';

/// Shows [child] once this phone has joined, and asks for a name until then.
class JoinGate extends ConsumerWidget {
  const JoinGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(huntSessionProvider, (previous, next) {
      if (previous?.value?.user.id != next.value?.user.id) {
        ref
          ..invalidate(huntSnapshotProvider)
          ..invalidate(huntLeadersProvider);
      }
    });
    return ref
        .watch(huntSessionProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => const Scaffold(body: LoadingView()),
          error: (_, _) => _joinPage(),
          data: (session) => session == null ? _joinPage() : child,
        );
  }
}

/// This gate sits above the app's navigator, and a text field needs an overlay
/// above it to work.
Widget _joinPage() => Overlay(
  initialEntries: [OverlayEntry(builder: (context) => const JoinPage())],
);

class JoinPage extends ConsumerStatefulWidget {
  const JoinPage({super.key});

  @override
  ConsumerState<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends ConsumerState<JoinPage> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final problem = huntNameProblem(_name.text);
    if (problem != null) {
      setState(() => _message = problem);
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(huntAuthProvider).join(_name.text);
    } on AppFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) setState(() => _message = 'Could not join. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: NightBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.lg * 2,
                ),
                child: Center(
                  child: ConstrainedBody(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HuntItemArt(
                              HuntItemKind.diya,
                              size: AppIconSizes.hero,
                            ),
                            SizedBox(width: AppSpacing.md),
                            HuntItemArt(
                              HuntItemKind.flag,
                              size: AppIconSizes.hero,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Semantics(
                          header: true,
                          child: Text(
                            'Habba Hunt',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Find the diyas and Kannada flags hidden around the '
                          'office. What should we call you on the leaderboard?',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          key: const ValueKey('join-name'),
                          controller: _name,
                          enabled: !_busy,
                          maxLength: 24,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.givenName],
                          onSubmitted: (_) => _join(),
                          decoration: const InputDecoration(
                            labelText: 'Your name',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton(
                          key: const ValueKey('join'),
                          onPressed: _busy ? null : _join,
                          child: Text(_busy ? 'Joining…' : 'Start playing'),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _message!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
