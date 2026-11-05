import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_tokens.dart';
import '../theme/arcade_tokens.dart';

/// "Continue with Google": a flat rounded button filled left to right with
/// the Deepavali tab's background colours (night, plum, maroon), the Google
/// logo, and cream Poppins text, with a thin gold edge and a soft shadow.
/// Grows with text size instead of clipping.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.loading,
    required this.onPressed,
    super.key,
  });

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ArcadeSizes.googleButtonMaxWidth,
        ),
        child: Semantics(
          button: true,
          enabled: onPressed != null,
          label: loading ? 'Signing in' : 'Continue with Google',
          excludeSemantics: true,
          // The shadow lives outside the Material: Ink clips shadows square.
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: ArcadeRadius.googleButtonAll,
              boxShadow: [
                BoxShadow(
                  color: FlappyPalette.black.withValues(
                    alpha: ArcadeOpacity.shadow,
                  ),
                  blurRadius: ArcadeSizes.googleButtonShadow,
                  offset: const Offset(0, ArcadeSizes.googleButtonShadowDrop),
                ),
              ],
            ),
            child: Material(
              color: FlappyPalette.clear,
              child: InkWell(
                onTap: loading ? null : onPressed,
                borderRadius: ArcadeRadius.googleButtonAll,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: ArcadeRadius.googleButtonAll,
                    border: Border.all(
                      color: AppColors.diwaliGold.withValues(
                        alpha: AppOpacity.border,
                      ),
                      width: ArcadeSizes.hairline,
                    ),
                    gradient: const LinearGradient(
                      // Left to right: the Deepavali page background colours.
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.diwaliNight,
                        AppColors.diwaliPlum,
                        AppColors.diwaliMaroon,
                      ],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: ArcadeSizes.googleButtonHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ArcadeSizes.googleButtonPaddingHorizontal,
                        vertical: ArcadeSizes.googleButtonPaddingVertical,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox.square(
                            dimension: ArcadeSizes.googleLogoSize,
                            child: loading
                                // Smaller than the logo box, so the button
                                // keeps its size while it spins.
                                ? const Center(
                                    child: SizedBox.square(
                                      dimension: ArcadeSizes.googleSpinnerSize,
                                      child: CircularProgressIndicator(
                                        strokeWidth:
                                            ArcadeSizes.googleSpinnerStroke,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.diwaliGold,
                                            ),
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    'assets/auth/google_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                          ),
                          const SizedBox(width: ArcadeSizes.googleLogoGap),
                          Flexible(
                            child: Text(
                              loading
                                  ? 'Signing in...'
                                  : 'Continue with Google',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: ArcadeText.googleButton,
                                fontWeight: FontWeight.w600,
                                color: AppColors.diwaliCream,
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
          ),
        ),
      ),
    );
  }
}
