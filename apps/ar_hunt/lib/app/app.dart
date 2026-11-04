import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_tokens.dart';
import '../features/ar/presentation/ar_theme.dart';
import 'auth/join_gate.dart';
import 'router/app_router.dart';

/// Root widget of the standalone app. After merging, the main app's own root
/// takes over and this file is left behind.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Habba Hunt',
    theme: ArTheme.data,
    routerConfig: ref.watch(routerProvider),
    debugShowCheckedModeBanner: false,
    builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: AppTextScale.min,
        maxScaleFactor: AppTextScale.max,
        child: JoinGate(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
}
