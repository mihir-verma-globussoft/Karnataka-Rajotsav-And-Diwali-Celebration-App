import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'providers.dart';
import 'router/app_router.dart';

/// Root widget. Watches only the router and theme mode so the rest of the tree
/// is not rebuilt by unrelated state.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Rajotsav & Diwali',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
      // Cap system text scaling so layouts stay usable at extreme settings
      // while still honouring accessibility preferences up to 2x.
      builder: (context, child) {
        final icons = Theme.brightnessOf(context) == Brightness.dark
            ? Brightness.light
            : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          // Transparent system bars so no strip shows under the floating bar.
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            statusBarIconBrightness: icons,
            systemNavigationBarIconBrightness: icons,
          ),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 1,
            maxScaleFactor: 2,
            child: child!,
          ),
        );
      },
    );
  }
}
