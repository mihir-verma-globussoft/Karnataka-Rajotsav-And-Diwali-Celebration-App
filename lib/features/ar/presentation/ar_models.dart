import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../../core/theme/app_tokens.dart';
import '../domain/ar_mesh.dart';
import '../domain/hunt_models.dart';

/// The 3D models the hunt draws, in metres, with the base at y = 0. They are
/// built here once and sent to the native view, so both platforms show the
/// same thing. Slightly larger than life, so they can be spotted across a room.
ArModel huntModel(HuntItemKind kind) => switch (kind) {
  HuntItemKind.diya => _diya(),
  HuntItemKind.flag => _flag(),
};

int _argb(Color color, [double opacity = 1]) =>
    color.withValues(alpha: opacity).toARGB32();

ArModel _diya() {
  // Shifted so the model turns around its visual middle, not the bowl's.
  const shift = -0.04;
  const center = [shift, 0.0, 0.0];
  // The lip is pinched out to one side, where the wick rests.
  double pinch(double angle) =>
      1 + 0.38 * math.pow(math.max(0.0, math.cos(angle)), 8);

  const wickX = shift + 0.125;
  const flameBase = [wickX, 0.085, 0.0];
  const flameProfile = [
    (0.0, 0.0),
    (0.020, 0.012),
    (0.026, 0.030),
    (0.020, 0.055),
    (0.008, 0.080),
    (0.0, 0.105),
  ];

  return ArModel(
    height: 0.19,
    parts: [
      lathe(
        const [
          (0, 0),
          (0.045, 0),
          (0.07, 0.012),
          (0.095, 0.035),
          (0.112, 0.062),
          (0.112, 0.068),
          (0.104, 0.070),
          (0.092, 0.052),
          (0.06, 0.035),
          (0, 0.03),
        ],
        argb: _argb(AppColors.arClay),
        center: center,
        radiusScale: pinch,
        segments: 48,
      ),
      lathe(
        const [
          (0.1135, 0.060),
          (0.1155, 0.066),
          (0.1135, 0.072),
          (0.1055, 0.0735),
        ],
        argb: _argb(AppColors.diwaliGold),
        center: center,
        radiusScale: pinch,
        segments: 48,
      ),
      lathe(
        const [(0.094, 0.050), (0, 0.050)],
        argb: _argb(AppColors.arOil),
        center: center,
        radiusScale: pinch,
        segments: 48,
      ),
      lathe(
        const [(0.008, 0.045), (0.006, 0.085), (0, 0.092)],
        argb: _argb(AppColors.diwaliCream),
        center: const [wickX, 0, 0],
        segments: 10,
      ),
      lathe(
        flameProfile,
        argb: _argb(AppColors.diwaliOrange),
        center: flameBase,
        segments: 16,
        unlit: true,
        flicker: true,
        pivot: flameBase,
      ),
      lathe(
        [for (final (r, y) in flameProfile) (r * 0.55, y * 0.6)],
        argb: _argb(AppColors.diwaliFlameCore),
        center: [wickX, flameBase[1] + 0.004, 0],
        segments: 12,
        unlit: true,
        flicker: true,
        pivot: flameBase,
      ),
      sphere(
        0.10,
        argb: _argb(AppColors.diwaliGold, AppOpacity.arHaloInner),
        center: const [wickX, 0.125, 0],
        unlit: true,
        flicker: true,
        pivot: const [wickX, 0.125, 0],
      ),
      sphere(
        0.18,
        argb: _argb(AppColors.diwaliSaffron, AppOpacity.arHaloOuter),
        center: const [wickX, 0.125, 0],
        unlit: true,
      ),
    ],
  );
}

ArModel _flag() {
  const shift = -0.10;
  const clothLeft = shift + 0.008;
  const clothRight = shift + 0.368;
  const clothBottom = 0.36;
  const clothMiddle = 0.48;
  const clothTop = 0.60;
  double ripple(double x) =>
      0.018 * math.sin((x - clothLeft) * 18) * (x - clothLeft) / 0.36;

  return ArModel(
    height: 0.62,
    parts: [
      lathe(
        const [(0, 0), (0.06, 0), (0.06, 0.012), (0.012, 0.022), (0, 0.022)],
        argb: _argb(AppColors.arPoleBase),
        center: const [shift, 0, 0],
        segments: 24,
      ),
      lathe(
        const [(0.008, 0), (0.008, 0.62)],
        argb: _argb(AppColors.diwaliGoldDeep),
        center: const [shift, 0, 0],
        segments: 12,
      ),
      sphere(
        0.016,
        argb: _argb(AppColors.diwaliGold),
        center: const [shift, 0.63, 0],
        rings: 6,
        segments: 10,
      ),
      cloth(
        left: clothLeft,
        right: clothRight,
        bottom: clothMiddle,
        top: clothTop,
        ripple: ripple,
        argb: _argb(AppColors.kannadaYellow),
      ),
      cloth(
        left: clothLeft,
        right: clothRight,
        bottom: clothBottom,
        top: clothMiddle,
        ripple: ripple,
        argb: _argb(AppColors.kannadaRed),
      ),
      sphere(
        0.34,
        argb: _argb(AppColors.diwaliGold, AppOpacity.arHaloOuter),
        center: const [shift + 0.18, clothMiddle, 0],
        unlit: true,
      ),
    ],
  );
}
