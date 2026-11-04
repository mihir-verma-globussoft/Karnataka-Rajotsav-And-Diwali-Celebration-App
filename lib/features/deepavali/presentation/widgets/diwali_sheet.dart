import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../theme/diwali_theme.dart';

/// Opens a bottom sheet with the Deepavali theme (sheets are built above the
/// page, so they would otherwise get the app theme).
Future<T?> showDiwaliSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
  builder: (sheetContext) => Theme(
    data: DiwaliTheme.data,
    child: Builder(builder: builder),
  ),
);
