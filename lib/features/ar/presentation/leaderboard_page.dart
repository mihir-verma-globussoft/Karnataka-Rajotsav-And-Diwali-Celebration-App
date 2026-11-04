import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_value_view.dart';
import '../ar_providers.dart';
import '../domain/hunt_models.dart';
import 'widgets/hunt_widgets.dart';

/// shortcut: shows the top 50 only, plenty for one office; add paging if the
/// hunt ever opens up to more people than that.
class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final you = ref.watch(huntRepositoryProvider).currentUserId;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Leaderboard')),
      body: NightBackground(
        child: SafeArea(
          child: AsyncValueView<List<HuntLeader>>(
            value: ref.watch(huntLeadersProvider),
            onRetry: () => ref.invalidate(huntLeadersProvider),
            isEmpty: (rows) => rows.isEmpty,
            emptyMessage: 'No one on the board yet. Be the first!',
            data: (rows) => RefreshIndicator.adaptive(
              onRefresh: () => ref.refresh(huntLeadersProvider.future),
              child: ConstrainedBody(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: rows.length,
                  itemBuilder: (context, index) => HuntLeaderRow(
                    leader: rows[index],
                    isYou: rows[index].userId == you,
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
