import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../ar_providers.dart';
import '../../domain/ar_scene.dart';
import '../../domain/hunt_models.dart';
import '../../domain/hunt_rules.dart';
import '../ar_models.dart';

/// Builds the live camera. Tests override it, as there is no camera to show.
typedef ArCameraBuilder = Widget Function(
  Map<String, Object> creationParams,
  void Function(int viewId) onCreated,
);

final arCameraBuilderProvider = Provider<ArCameraBuilder>(
  (ref) =>
      (creationParams, onCreated) =>
          _NativeArView(creationParams: creationParams, onCreated: onCreated),
);

/// Built once: the models never change while the app runs.
final Map<String, Object> _modelsWire = {
  for (final kind in HuntItemKind.values) kind.name: huntModel(kind).toWire(),
};

/// The camera and everything drawn in it, filling its parent. All taps come in
/// through [ArSceneController.tap] from a Flutter gesture layer above this.
class ArCameraView extends ConsumerWidget {
  const ArCameraView({required this.placing, required this.onScene, super.key});

  /// Admin mode: also looks for surfaces to place things on.
  final bool placing;
  final void Function(ArSceneController scene) onScene;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(arCameraBuilderProvider)({
        'placing': placing,
        'reduceMotion': MediaQuery.disableAnimationsOf(context),
        'visibleRadius': huntVisibleRadiusMetres,
        'pickRadius': AppSizes.arPickRadius,
        'posters': [
          for (final zone in huntZones)
            {
              'id': zone.id,
              'asset': zone.posterAsset,
              'width': huntPosterWidthMetres,
            },
        ],
        'models': _modelsWire,
        'sparkColors': [
          for (final color in const [
            AppColors.diwaliGold,
            AppColors.diwaliSaffron,
            AppColors.kannadaYellow,
            AppColors.kannadaRed,
            AppColors.diwaliCream,
          ])
            color.toARGB32(),
        ],
      }, (viewId) => onScene(ref.read(arSceneFactoryProvider)(viewId)));
}

class _NativeArView extends StatelessWidget {
  const _NativeArView({required this.creationParams, required this.onCreated});

  final Map<String, Object> creationParams;
  final void Function(int viewId) onCreated;

  @override
  Widget build(BuildContext context) => switch (defaultTargetPlatform) {
    TargetPlatform.android => PlatformViewLink(
      viewType: arViewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      ),
      // ARCore draws into a GLSurfaceView, which needs hybrid composition.
      onCreatePlatformView: (params) =>
          PlatformViewsService.initExpensiveAndroidView(
              id: params.id,
              viewType: arViewType,
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () => params.onFocusChanged(true),
            )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..addOnPlatformViewCreatedListener(onCreated)
            ..create(),
    ),
    TargetPlatform.iOS => UiKitView(
      viewType: arViewType,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      onPlatformViewCreated: onCreated,
    ),
    _ => const SizedBox.expand(),
  };
}
