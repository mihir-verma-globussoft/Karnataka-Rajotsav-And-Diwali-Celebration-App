import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/player.dart';
import '../flappy_bird_providers.dart';
import 'widgets/arcade_widgets.dart';

class LeaderboardView extends ConsumerStatefulWidget {
  const LeaderboardView({required this.currentPlayer, super.key});

  final PlayerProfile currentPlayer;

  @override
  ConsumerState<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<LeaderboardView> {
  static const _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  final List<LeaderboardEntry> _entries = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future<void>.microtask(_refresh);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 280) _loadMore();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
      _hasMore = true;
    });
    try {
      final values = await ref
          .read(playerRepositoryProvider)
          .loadLeaderboard(offset: 0, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _error = null;
        _entries
          ..clear()
          ..addAll(values);
        _hasMore = values.length == _pageSize;
      });
      ref.invalidate(dashboardProvider);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final values = await ref
          .read(playerRepositoryProvider)
          .loadLeaderboard(offset: _entries.length, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _error = null;
        _entries.addAll(values);
        _hasMore = values.length == _pageSize;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _entries.isEmpty) return const LoadingView();
    if (_error != null && _entries.isEmpty) {
      return ErrorView(error: _error!, onRetry: _refresh);
    }
    if (_entries.isEmpty) {
      return RefreshIndicator.adaptive(
        onRefresh: _refresh,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: EmptyView(
                message: 'No scores yet. Be the first player on the board!',
                icon: Icons.emoji_events_outlined,
              ),
            ),
          ],
        ),
      );
    }
    final podium = _entries.take(3).toList();
    final remaining = _entries.skip(3).toList();
    return ArcadeBackground(
      child: RefreshIndicator.adaptive(
        onRefresh: _refresh,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            ref
                .watch(dashboardProvider)
                .maybeWhen(
                  data: (data) => ArcadePanel(
                    child: Text(
                      data.stats.globalRank == null
                          ? 'Play a game to earn your global rank.'
                          : 'Your current global rank: #${data.stats.globalRank}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final entry in podium)
                  _PodiumCard(
                    entry: entry,
                    isCurrent: entry.userId == widget.currentPlayer.id,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final entry in remaining) ...[
              _LeaderboardRow(
                entry: entry,
                isCurrent: entry.userId == widget.currentPlayer.id,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (_error != null)
              TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.refresh),
                label: const Text('Could not load more. Retry'),
              ),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
          ],
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.entry, required this.isCurrent});

  final LeaderboardEntry entry;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      _ => '🥉',
    };
    return SizedBox(
      width: 126,
      child: ArcadePanel(
        child: Column(
          children: [
            Text(medal, style: const TextStyle(fontSize: 30)),
            PlayerAvatar(
              username: entry.username,
              avatarUrl: entry.avatarUrl,
              radius: 26,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              entry.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
            Text('${entry.highScore}'),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.isCurrent});

  final LeaderboardEntry entry;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) => Material(
    color: isCurrent
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
    borderRadius: AppRadius.mdAll,
    child: ListTile(
      leading: SizedBox(
        width: 34,
        child: Text(
          '#${entry.rank}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(entry.username),
      subtitle: isCurrent ? const Text('You') : null,
      trailing: Text(
        '${entry.highScore}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
  );
}
