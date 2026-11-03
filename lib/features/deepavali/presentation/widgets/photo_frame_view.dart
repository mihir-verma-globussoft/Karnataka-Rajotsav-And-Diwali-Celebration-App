import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/photo_booth.dart';
import '../theme/diwali_palette.dart';
import 'diya_art.dart';
import 'object_art.dart';

/// A photo with a festive frame and a "Happy Deepavali!" banner, 4:5. It is a
/// picture (shared as an image), so its text ignores the phone's text size.
class PhotoFrameView extends StatelessWidget {
  const PhotoFrameView({required this.photo, required this.frame, super.key});

  final Uint8List photo;
  final PhotoFrame frame;

  static const double aspect = 4 / 5;

  // Layout, as fractions of the picture width.
  static const double _bannerScale = 0.075;
  static const double _bannerPad = 0.035;
  static const double _decorScale = 0.3;
  static const double _garlandInset = 0.05;
  static const double _garlandRise = 0.2;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspect,
    child: Semantics(
      image: true,
      label: 'Your photo in a ${frame.label} frame, Happy Deepavali',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final text = Theme.of(context).textTheme;
            return MediaQuery.withNoTextScaling(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: DiwaliPalette.night,
                    child: Image.memory(
                      photo,
                      fit: BoxFit.cover,
                      // Decode near the display size, not the camera's.
                      cacheWidth: (w * 3).round(),
                      gaplessPlayback: true,
                      errorBuilder: (context, e, s) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: DiwaliPalette.creamMuted,
                          size: AppIconSizes.hero,
                        ),
                      ),
                    ),
                  ),
                  ..._decor(w, c.maxHeight),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            DiwaliPalette.night.withValues(alpha: 0),
                            DiwaliPalette.night.withValues(
                              alpha: AppOpacity.strong,
                            ),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          w * _bannerPad,
                          w * _bannerPad * 2,
                          w * _bannerPad,
                          w * _bannerPad,
                        ),
                        child: Text(
                          'Happy Deepavali!',
                          textAlign: TextAlign.center,
                          style: text.headlineSmall?.copyWith(
                            fontSize: w * _bannerScale,
                            fontWeight: FontWeight.w700,
                            color: DiwaliPalette.gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  List<Widget> _decor(double w, double h) {
    final d = w * _decorScale;
    return switch (frame) {
      PhotoFrame.diyas => [
        Positioned(
          left: 0,
          right: 0,
          bottom: w * (_bannerScale + _bannerPad * 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 5; i++)
                DiyaArt(width: w * (i.isEven ? 0.13 : 0.1), ignite: 1),
            ],
          ),
        ),
      ],
      PhotoFrame.lanterns => [
        Positioned(
          left: -d * 0.1,
          top: -d * 0.12,
          width: d,
          height: d,
          child: const ObjectArt(id: 'lantern', revealed: true),
        ),
        Positioned(
          right: -d * 0.1,
          top: -d * 0.12,
          width: d,
          height: d,
          child: const ObjectArt(id: 'lantern', revealed: true),
        ),
      ],
      PhotoFrame.rangoli => [
        Positioned(
          left: -d * 0.2,
          bottom: w * (_bannerScale + _bannerPad * 2) - d * 0.2,
          width: d,
          height: d,
          child: const ObjectArt(id: 'rangoli', revealed: true),
        ),
        Positioned(
          right: -d * 0.2,
          bottom: w * (_bannerScale + _bannerPad * 2) - d * 0.2,
          width: d,
          height: d,
          child: const ObjectArt(id: 'rangoli', revealed: true),
        ),
      ],
      PhotoFrame.garland => [
        Positioned(
          left: w * _garlandInset,
          top: -w * _garlandRise,
          width: w * (1 - 2 * _garlandInset),
          height: w * (1 - 2 * _garlandInset),
          child: const ObjectArt(id: 'garland', revealed: true),
        ),
      ],
    };
  }
}
