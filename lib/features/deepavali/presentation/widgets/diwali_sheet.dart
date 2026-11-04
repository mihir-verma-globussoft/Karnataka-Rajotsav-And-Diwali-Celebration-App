import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../theme/diwali_theme.dart';

/// Opens a bottom sheet with the Deepavali theme (sheets are built above the
/// page, so they would otherwise get the app theme). Safe-area handling comes
/// from [showAppSheet].
Future<T?> showDiwaliSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showAppSheet<T>(
  context,
  constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
  builder: (_) => Theme(
    data: DiwaliTheme.data,
    child: Builder(builder: builder),
  ),
);
