import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/arcade_tokens.dart';

/// Shown while the app works out who is signed in: the festival poster (the
/// same artwork as the native launch splash and the login screen), with a
/// spinner. It stops the screen going blank between the launch splash and the
/// first real screen.
class StartupPosterView extends StatelessWidget {
  const StartupPosterView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FlappyPalette.night,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/auth/login_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            // The poster is a bundled asset: show it straight away.
            gaplessPlayback: true,
          ),
        ),
        const SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(FlappyPalette.gold),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
