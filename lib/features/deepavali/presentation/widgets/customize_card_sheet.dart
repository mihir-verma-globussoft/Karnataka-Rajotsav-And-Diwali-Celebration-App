import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/greeting.dart';
import '../state/greeting_notifier.dart';
import '../theme/diwali_palette.dart';
import 'diwali_button.dart';
import 'diwali_sheet.dart';

/// Opens the sheet where the message and sender name are edited.
Future<void> showCustomizeCardSheet(BuildContext context) =>
    showDiwaliSheet<void>(context, builder: (_) => const _CustomizeSheet());

class _CustomizeSheet extends ConsumerStatefulWidget {
  const _CustomizeSheet();

  @override
  ConsumerState<_CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends ConsumerState<_CustomizeSheet> {
  late final TextEditingController _message;
  late final TextEditingController _from;

  @override
  void initState() {
    super.initState();
    final card = ref.read(greetingProvider);
    _message = TextEditingController(text: card.message);
    _from = TextEditingController(text: card.from);
  }

  @override
  void dispose() {
    _message.dispose();
    _from.dispose();
    super.dispose();
  }

  void _preset(String wish) {
    _message.text = wish;
    ref.read(greetingProvider.notifier).setMessage(wish);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(greetingProvider.notifier);
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
              'Customise your card',
              style: text.titleLarge?.copyWith(color: DiwaliPalette.gold),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Pick a wish', style: text.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final wish in greetingPresets)
                ActionChip(label: Text(wish), onPressed: () => _preset(wish)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _message,
            maxLength: greetingMessageMax,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Your message',
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.setMessage,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _from,
            maxLength: greetingNameMax,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'From (optional)',
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.setFrom,
          ),
          const SizedBox(height: AppSpacing.sm),
          DiwaliButton(
            label: 'Done',
            icon: Icons.check,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
