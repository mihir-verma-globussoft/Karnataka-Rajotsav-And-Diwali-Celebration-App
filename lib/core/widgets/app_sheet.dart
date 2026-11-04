import 'package:flutter/material.dart';

/// The only way the app opens a bottom sheet.
///
/// Material's `useSafeArea` protects just the top edge, so a sheet's last
/// button (Close, Save…) would slide under the Android back/home buttons or
/// the gesture bar. This wraps every sheet's content so it stays clear of the
/// bottom inset, and the sheet grows to fit its content and scrolls on short
/// screens. `test/architecture_test.dart` fails if `showModalBottomSheet` is
/// called anywhere else.
///
/// If the content already uses a [SafeArea] that is fine: nested safe areas
/// do not add the inset twice.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool showDragHandle = false,
  BoxConstraints? constraints,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: showDragHandle,
  constraints: constraints,
  builder: (sheetContext) =>
      SafeArea(top: false, child: Builder(builder: builder)),
);
