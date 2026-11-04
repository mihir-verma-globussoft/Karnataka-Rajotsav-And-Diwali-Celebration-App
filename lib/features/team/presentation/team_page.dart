import 'package:flutter/material.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../team_members.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  static const int _columns = 2;
  static const double _gap = AppSpacing.md;
  static const double _nameGap = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final nameHeight = MediaQuery.textScalerOf(context).scale(24);
    return Scaffold(
      appBar: AppBar(title: const Text('Our Team')),
      body: SafeArea(
        child: ConstrainedBody(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth =
                  (constraints.maxWidth - _gap * (_columns + 1)) / _columns;
              final rowHeight = tileWidth + _nameGap + nameHeight;
              // A last member left alone in a row is centred, not left-aligned.
              final lonely = teamMembers.length % _columns;
              final gridCount = teamMembers.length - lonely;
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(_gap, _gap, _gap, 0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _columns,
                        mainAxisSpacing: _gap,
                        crossAxisSpacing: _gap,
                        // Square photo + name line; follows the text scale.
                        mainAxisExtent: rowHeight,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _MemberTile(member: teamMembers[i]),
                        childCount: gridCount,
                      ),
                    ),
                  ),
                  if (lonely > 0)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: _gap),
                        child: Center(
                          child: SizedBox(
                            width: tileWidth,
                            height: rowHeight,
                            child: _MemberTile(member: teamMembers.last),
                          ),
                        ),
                      ),
                    ),
                  // Keeps the last row clear of the floating bar.
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSizes.floatingBarClearance),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: AppRadius.lgAll,
          child: _Photo(
            asset: member.photoAsset,
            alignment: member.photoAlignment,
          ),
        ),
      ),
      const SizedBox(height: TeamPage._nameGap),
      Text(
        member.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    ],
  );
}

class _Photo extends StatelessWidget {
  const _Photo({required this.asset, required this.alignment});

  final String? asset;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.secondaryContainer,
      child: Icon(
        Icons.person,
        size: AppIconSizes.xxl,
        color: scheme.onSecondaryContainer,
      ),
    );
    if (asset == null) return placeholder;
    return Image.asset(
      asset!,
      fit: BoxFit.cover,
      alignment: alignment,
      // Decode near display size, not full resolution.
      cacheWidth: AppSizes.photoDecodeWidth,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
