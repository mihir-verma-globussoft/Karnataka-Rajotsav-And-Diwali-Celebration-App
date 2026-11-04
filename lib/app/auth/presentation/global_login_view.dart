import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/arcade_tokens.dart';
import '../../../features/flappy_bird/domain/auth_repository.dart';
import '../../../features/flappy_bird/flappy_bird_providers.dart';

/// Global application login view with full-bleed Karnataka/Diwali poster
/// background and white pill Google sign-in button with official Google logo.
class GlobalLoginView extends ConsumerStatefulWidget {
  const GlobalLoginView({super.key});

  @override
  ConsumerState<GlobalLoginView> createState() => _GlobalLoginViewState();
}

class _GlobalLoginViewState extends ConsumerState<GlobalLoginView> {
  bool _loading = false;
  String? _message;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await ref.read(flappyAuthRepositoryProvider).signInWithGoogle();
      ref.invalidate(flappyAuthStateProvider);
    } on AuthCancelledException {
      if (mounted) setState(() => _message = 'Sign-in was cancelled.');
    } on AuthConfigurationException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on AppFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) setState(() => _message = 'Sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlappyPalette.night,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final screenAspect = screenWidth / screenHeight;
          const imageAspect = 576.0 / 1024.0;

          final double renderedHeight;
          final double offsetY;
          if (screenAspect < imageAspect) {
            renderedHeight = screenHeight;
            offsetY = 0;
          } else {
            renderedHeight = screenWidth / imageAspect;
            offsetY = (screenHeight - renderedHeight) / 2;
          }

          // Target smooth open floor area below the text line:
          final targetTop = offsetY + (775.0 / 1024.0) * renderedHeight;
          final buttonTop = targetTop.clamp(
            screenHeight * 0.60,
            screenHeight - 130.0,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed background poster image
              Positioned.fill(
                child: Image.asset(
                  'assets/auth/login_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              // Google Login button positioned right below the festival line
              Positioned(
                top: buttonTop,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: ArcadeSizes.panelMaxWidth,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _GoogleSignInButton(
                              loading: _loading,
                              onPressed: _loading ? null : _signIn,
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: FlappyPalette.black.withValues(
                                    alpha: ArcadeOpacity.border,
                                  ),
                                  borderRadius: AppRadius.mdAll,
                                  border: Border.all(
                                    color: FlappyPalette.errorAccent.withValues(
                                      alpha: ArcadeOpacity.error,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _message!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: FlappyPalette.white,
                                    fontSize: ArcadeText.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ArcadeSizes.googleButtonMaxWidth,
        ),
        child: SizedBox(
          width: double.infinity,
          height: ArcadeSizes.googleButtonHeight,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: ArcadeRadius.googleButtonAll,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: ArcadeRadius.googleButtonAll,
                  border: Border.all(
                    color: FlappyPalette.googleBorder,
                    width: ArcadeSizes.hairline,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: FlappyPalette.glowSoft,
                      blurRadius: ArcadeSizes.googleButtonElevation,
                    ),
                  ],
                  gradient: const LinearGradient(
                    colors: [
                      FlappyPalette.googleWarmSurface,
                      FlappyPalette.festivalGold,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (loading)
                      const SizedBox.square(
                        dimension: ArcadeSizes.googleLogoSize,
                        child: CircularProgressIndicator(
                          strokeWidth: ArcadeSizes.googleSpinnerStroke,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            FlappyPalette.googleBlue,
                          ),
                        ),
                      )
                    else
                      SizedBox.square(
                        dimension: ArcadeSizes.googleLogoSize,
                        child: ClipRect(
                          child: Transform.scale(
                            scale: ArcadeSizes.googleLogoPaintScale,
                            child: Image.asset(
                              'assets/auth/google_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: ArcadeSizes.googleLogoGap),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          loading ? 'Signing in...' : 'Continue with Google',
                          style: const TextStyle(
                            fontSize: ArcadeText.googleButton,
                            fontWeight: FontWeight.w700,
                            color: FlappyPalette.googleText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
