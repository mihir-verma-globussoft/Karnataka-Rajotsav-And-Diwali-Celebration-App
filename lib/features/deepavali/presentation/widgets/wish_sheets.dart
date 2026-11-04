import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/sound.dart';
import '../../domain/wish.dart';
import '../sections/countdown_section.dart' show formatCivilDate;
import '../state/feedback.dart';
import '../state/wall_notifier.dart';
import '../theme/diwali_palette.dart';
import 'diwali_button.dart';
import 'diwali_sheet.dart';
import 'diya_art.dart';

/// Shown when a wish could not be saved to this device.
const String wishNotSavedMessage =
    'Couldn’t save your wish. Your diya stays lit for now.';

/// Opens the sheet where a wish is written and a diya is lit.
Future<void> showAddWishSheet(BuildContext context) =>
    showDiwaliSheet<void>(context, builder: (_) => const _AddWishSheet());

/// Opens one wish.
Future<void> showWishSheet(BuildContext context, Wish wish) =>
    showDiwaliSheet<void>(context, builder: (_) => _WishSheet(wish: wish));

class _AddWishSheet extends ConsumerStatefulWidget {
  const _AddWishSheet();

  @override
  ConsumerState<_AddWishSheet> createState() => _AddWishSheetState();
}

class _AddWishSheetState extends ConsumerState<_AddWishSheet> {
  final TextEditingController _text = TextEditingController();
  final TextEditingController _from = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    _from.dispose();
    super.dispose();
  }

  Future<void> _light() async {
    if (_busy || tidyWish(_text.text) == null) return;
    setState(() => _busy = true);
    // Grab these before the sheet closes.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final result = await ref
        .read(wallProvider.notifier)
        .add(_text.text, _from.text);
    navigator.pop();
    if (result != AddWishResult.empty) {
      ref.read(diwaliFeedbackProvider).both(Haptic.light, Sfx.diyaLight);
    }
    if (result == AddWishResult.notSaved) {
      messenger?.showSnackBar(
        const SnackBar(content: Text(wishNotSavedMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ready = tidyWish(_text.text) != null;
    return SingleChildScrollView(
      // Keeps the fields above the keyboard.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Make a wish',
              style: text.titleLarge?.copyWith(color: DiwaliPalette.gold),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your wish is saved on this phone only. Nobody else sees it.',
            style: text.bodyMedium?.copyWith(color: DiwaliPalette.creamMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _text,
            autofocus: true,
            maxLength: wishMax,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Your wish',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _from,
            maxLength: wishNameMax,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DiwaliButton(
            label: _busy ? 'Lighting…' : 'Light a diya',
            icon: Icons.local_fire_department_outlined,
            onPressed: ready && !_busy ? () => unawaited(_light()) : null,
          ),
        ],
      ),
    );
  }
}

class _WishSheet extends ConsumerWidget {
  const _WishSheet({required this.wish});

  final Wish wish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: DiyaArt(width: AppIconSizes.hero, ignite: 1)),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            header: true,
            child: Text(
              wish.text,
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(color: DiwaliPalette.cream),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              if (wish.from.isNotEmpty) '— ${wish.from}',
              'Lit on ${formatCivilDate(wish.litAt, weekday: false)}',
            ].join('\n'),
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: DiwaliPalette.creamMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          DiwaliButton(
            label: 'Remove this wish',
            icon: Icons.delete_outline,
            kind: DiwaliButtonKind.tertiary,
            onPressed: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              final navigator = Navigator.of(context);
              final saved = await ref
                  .read(wallProvider.notifier)
                  .remove(wish.id);
              navigator.pop();
              if (!saved) {
                messenger?.showSnackBar(
                  const SnackBar(content: Text('Couldn’t save that change.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
