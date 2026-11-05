import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_value_view.dart';
import '../ar_providers.dart';
import '../domain/hunt_models.dart';
import '../domain/hunt_repository.dart';
import 'widgets/hunt_celebration.dart';
import 'widgets/hunt_widgets.dart';

/// With [celebrate], for someone who has found everything, the board also
/// plays the song, sets off crackers and names the winner.
///
/// shortcut: shows the top 50 only, plenty for one office; add paging if the
/// hunt ever opens up to more people than that.
class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({this.celebrate = false, super.key});

  final bool celebrate;

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  late final HuntSounds _sounds = ref.read(huntSoundsProvider);
  AppLifecycleListener? _lifecycle;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    if (!widget.celebrate) return;
    unawaited(_sounds.startMusic());
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(_sounds.stopMusic()),
      onShow: () {
        if (!_muted) unawaited(_sounds.startMusic());
      },
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    if (widget.celebrate) unawaited(_sounds.stopMusic());
    super.dispose();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    unawaited(_muted ? _sounds.stopMusic() : _sounds.startMusic());
  }

  @override
  Widget build(BuildContext context) {
    final you = ref.watch(huntRepositoryProvider).currentUserId;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          if (widget.celebrate)
            IconButton(
              tooltip: _muted ? 'Play the song' : 'Mute the song',
              icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
              onPressed: _toggleMute,
            ),
        ],
      ),
      body: NightBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.celebrate) const HuntCrackers(),
            SafeArea(
              child: AsyncValueView<List<HuntLeader>>(
                value: ref.watch(huntLeadersProvider),
                onRetry: () => ref.invalidate(huntLeadersProvider),
                isEmpty: (rows) => rows.isEmpty,
                emptyMessage: 'No one on the board yet. Be the first!',
                data: (rows) => RefreshIndicator.adaptive(
                  onRefresh: () => ref.refresh(huntLeadersProvider.future),
                  child: ConstrainedBody(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        if (widget.celebrate) ...[
                          HuntWinnerBanner(
                            winner: rows.first,
                            isYou: rows.first.userId == you,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        for (final row in rows)
                          HuntLeaderRow(leader: row, isYou: row.userId == you),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
