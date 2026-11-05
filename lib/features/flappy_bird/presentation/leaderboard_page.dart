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
    if (_scrollController.position.extentAfter < AppSpacing.xxl) _loadMore();
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

  Widget _screen(Widget child) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/flappy_bird/dashboard_background.png',
        fit: BoxFit.cover,
      ),
      SafeArea(child: child),
    ],
  );

  Widget _header(BuildContext context) => ArcadeNavigationHeader(
    title: 'Global ',
    highlight: 'Leaderboard',
    onBack: () => Navigator.maybePop(context),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading && _entries.isEmpty) {
      return _screen(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _header(context),
              const Expanded(child: LoadingView()),
            ],
          ),
        ),
      );
    }
    if (_error != null && _entries.isEmpty) {
      return _screen(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: ErrorView(error: _error!, onRetry: _refresh),
              ),
            ],
          ),
        ),
      );
    }
    if (_entries.isEmpty) {
      return _screen(
        RefreshIndicator.adaptive(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _header(context),
              const SizedBox(height: AppSpacing.xxl),
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      color: FlappyPalette.festivalGold,
                      size: AppIconSizes.xl,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'No scores yet. Be the first player on the board!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: FlappyPalette.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ordered = [..._entries]..sort((a, b) => a.rank.compareTo(b.rank));
    final podium = ordered.take(3).toList();
    final remaining = ordered.skip(3).toList();
    return _screen(
      RefreshIndicator.adaptive(
        onRefresh: _refresh,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: ArcadeSizes.panelMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    const SizedBox(height: AppSpacing.md),
                    ref
                        .watch(dashboardProvider)
                        .maybeWhen(
                          data: (data) => _RankCallout(
                            message: data.stats.globalRank == null
                                ? 'Play a game to earn your global rank.'
                                : 'Your current global rank: #${data.stats.globalRank}',
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: FlappyPalette.panel.withValues(
                          alpha: ArcadeOpacity.panel,
                        ),
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(
                          color: FlappyPalette.white.withValues(
                            alpha: ArcadeOpacity.hairline,
                          ),
                          width: ArcadeSizes.hairline,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Podium(
                            entries: podium,
                            currentPlayerId: widget.currentPlayer.id,
                          ),
                          if (remaining.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'ALL PLAYERS',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: FlappyPalette.white70,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: ArcadeText.unit,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          for (final entry in remaining) ...[
                            _LeaderboardRow(
                              entry: entry,
                              isCurrent:
                                  entry.userId == widget.currentPlayer.id,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ),
                    if (_error != null)
                      TextButton.icon(
                        onPressed: _loadMore,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Could not load more. Retry'),
                      ),
                    if (_loadingMore)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.currentPlayerId});

  final List<LeaderboardEntry> entries;
  final String currentPlayerId;

  @override
  Widget build(BuildContext context) {
    LeaderboardEntry? byRank(int rank) {
      for (final entry in entries) {
        if (entry.rank == rank) return entry;
      }
      return null;
    }

    Widget slot(LeaderboardEntry? entry, {required bool champion}) => Expanded(
      child: entry == null
          ? const SizedBox.shrink()
          : _PodiumCard(
              entry: entry,
              champion: champion,
              isCurrent: entry.userId == currentPlayerId,
            ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        slot(byRank(2), champion: false),
        const SizedBox(width: AppSpacing.sm),
        slot(byRank(1), champion: true),
        const SizedBox(width: AppSpacing.sm),
        slot(byRank(3), champion: false),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.champion,
    required this.isCurrent,
  });

  final LeaderboardEntry entry;
  final bool champion;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final accent = switch (entry.rank) {
      1 => FlappyPalette.festivalGold,
      2 => FlappyPalette.sparkPink,
      _ => FlappyPalette.bronze,
    };
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      _ => '🥉',
    };
    return SizedBox(
      height: champion
          ? ArcadeSizes.podiumChampionHeight
          : ArcadeSizes.podiumCardHeight,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: isCurrent ? FlappyPalette.festivalGold : accent,
            width: ArcadeSizes.goldBorder,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              FlappyPalette.panel.withValues(alpha: ArcadeOpacity.card),
              accent.withValues(alpha: ArcadeOpacity.splashHighlight),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: ArcadeOpacity.half),
              blurRadius: AppSpacing.md,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(medal, style: const TextStyle(fontSize: ArcadeText.body)),
              PlayerAvatar(
                username: entry.username,
                avatarUrl: entry.avatarUrl,
                radius: ArcadeSizes.podiumAvatarRadius,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                entry.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FlappyPalette.white,
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
              Text(
                '${entry.highScore}',
                style: const TextStyle(
                  color: FlappyPalette.festivalGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
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
  Widget build(BuildContext context) {
    final accent = isCurrent
        ? FlappyPalette.festivalGold
        : FlappyPalette.sparkPink;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: accent.withValues(
            alpha: isCurrent ? ArcadeOpacity.border : ArcadeOpacity.hairline,
          ),
          width: isCurrent ? ArcadeSizes.goldBorder : ArcadeSizes.hairline,
        ),
        gradient: LinearGradient(
          colors: [
            FlappyPalette.panel.withValues(alpha: ArcadeOpacity.card),
            accent.withValues(alpha: ArcadeOpacity.splashHighlight),
          ],
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: ArcadeSizes.rankWidth,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(color: accent, fontWeight: FontWeight.w800),
            ),
          ),
          PlayerAvatar(
            username: entry.username,
            avatarUrl: entry.avatarUrl,
            radius: ArcadeSizes.podiumAvatarRadius,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: isCurrent
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FlappyPalette.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'You',
                        style: TextStyle(
                          color: FlappyPalette.festivalGold,
                          fontSize: ArcadeText.tiny,
                        ),
                      ),
                    ],
                  )
                : Text(
                    entry.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FlappyPalette.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.highScore}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: FlappyPalette.festivalGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'TOTAL',
                style: TextStyle(
                  color: FlappyPalette.white70,
                  fontSize: ArcadeText.tiny,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankCallout extends StatelessWidget {
  const _RankCallout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      borderRadius: AppRadius.lgAll,
      border: Border.all(
        color: FlappyPalette.festivalGold,
        width: ArcadeSizes.goldBorder,
      ),
      gradient: LinearGradient(
        colors: [
          FlappyPalette.panel.withValues(alpha: ArcadeOpacity.card),
          FlappyPalette.festivalGold.withValues(
            alpha: ArcadeOpacity.splashHighlight,
          ),
        ],
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.military_tech_rounded,
          color: FlappyPalette.festivalGold,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: FlappyPalette.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
