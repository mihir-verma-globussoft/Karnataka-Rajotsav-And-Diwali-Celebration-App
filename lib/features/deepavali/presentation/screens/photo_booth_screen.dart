import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../deepavali_providers.dart';
import '../../domain/photo_booth.dart';
import '../theme/diwali_palette.dart';
import '../theme/diwali_theme.dart';
import '../widgets/diwali_button.dart';
import '../widgets/glow_background.dart';
import '../widgets/photo_frame_view.dart';
import '../widgets/picture_capture.dart';

/// Full-screen photo booth: take or choose a photo, pick a festive frame and
/// share it. The photo stays on this phone unless you share it.
class PhotoBoothScreen extends StatelessWidget {
  const PhotoBoothScreen({super.key});

  @override
  Widget build(BuildContext context) => Theme(
    data: DiwaliTheme.data,
    child: const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: _PhotoBoothBody(),
    ),
  );
}

class _PhotoBoothBody extends ConsumerStatefulWidget {
  const _PhotoBoothBody();

  @override
  ConsumerState<_PhotoBoothBody> createState() => _PhotoBoothBodyState();
}

class _PhotoBoothBodyState extends ConsumerState<_PhotoBoothBody> {
  final GlobalKey _boundary = GlobalKey(debugLabel: 'photo-booth');
  Uint8List? _photo;
  PhotoFrame _frame = PhotoFrame.diyas;
  PhotoFailure? _problem;
  bool _busy = false;
  bool _exporting = false;

  /// Widest the framed photo is drawn.
  static const double _maxWidth = 340;

  Future<void> _pick(PhotoSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final bytes = await ref.read(photoPickerProvider).pick(source);
      if (!mounted) return;
      setState(() {
        if (bytes != null) _photo = bytes;
      });
    } on PhotoPickException catch (e) {
      if (mounted) setState(() => _problem = e.failure);
    } on Object {
      if (mounted) setState(() => _problem = PhotoFailure.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final sharer = ref.read(imageSharerProvider);
    if (sharer == null || _exporting || _photo == null) return;
    setState(() => _exporting = true);
    await shareBoundaryPicture(
      sharer: sharer,
      boundary: _boundary,
      fileName: 'deepavali-photo.png',
      text: 'Happy Deepavali!',
      messenger: ScaffoldMessenger.maybeOf(context),
      onRetry: () => unawaited(_share()),
    );
    if (mounted) setState(() => _exporting = false);
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  String? get _problemText => switch (_problem) {
    null => null,
    PhotoFailure.denied =>
      'Camera access is off. You can allow it in your phone’s Settings, or '
          'choose a photo from your gallery instead.',
    PhotoFailure.unavailable =>
      'No camera is available on this device. Choose a photo from your '
          'gallery instead.',
    PhotoFailure.failed => 'Something went wrong. Please try again.',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canShare = ref.watch(imageSharerProvider) != null;
    final photo = _photo;
    final problem = _problemText;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: GlowBackground()),
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBody(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            onPressed: _back,
                            icon: const Icon(Icons.arrow_back),
                          ),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                'Photo booth',
                                style: text.titleLarge?.copyWith(
                                  color: DiwaliPalette.gold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        photo == null
                            ? 'Take a festive photo or choose one from your '
                                  'gallery, then add a Deepavali frame. Your '
                                  'photo stays on this phone unless you share '
                                  'it.'
                            : 'Pick a frame, then share your photo.',
                        style: text.bodyMedium?.copyWith(
                          color: DiwaliPalette.creamMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (photo != null) ...[
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _maxWidth,
                            ),
                            child: RepaintBoundary(
                              key: _boundary,
                              child: PhotoFrameView(
                                photo: photo,
                                frame: _frame,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Semantics(
                          label: 'Frame',
                          container: true,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final f in PhotoFrame.values)
                                ChoiceChip(
                                  label: Text(f.label),
                                  selected: f == _frame,
                                  onSelected: (_) => setState(() => _frame = f),
                                  showCheckmark: false,
                                  selectedColor: DiwaliPalette.gold.withValues(
                                    alpha: AppOpacity.subtle,
                                  ),
                                  side: BorderSide(
                                    color: f == _frame
                                        ? DiwaliPalette.gold
                                        : DiwaliPalette.goldBorder,
                                  ),
                                  labelStyle: text.labelLarge?.copyWith(
                                    color: f == _frame
                                        ? DiwaliPalette.gold
                                        : DiwaliPalette.cream,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (problem != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            problem,
                            style: text.bodyMedium?.copyWith(
                              color: DiwaliPalette.saffron,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          DiwaliButton(
                            label: photo == null ? 'Take a photo' : 'Retake',
                            icon: Icons.photo_camera_outlined,
                            onPressed: _busy
                                ? null
                                : () => unawaited(_pick(PhotoSource.camera)),
                          ),
                          DiwaliButton(
                            label: 'Choose from gallery',
                            icon: Icons.photo_library_outlined,
                            kind: DiwaliButtonKind.secondary,
                            onPressed: _busy
                                ? null
                                : () => unawaited(_pick(PhotoSource.gallery)),
                          ),
                          if (photo != null && canShare)
                            DiwaliButton(
                              label: _exporting ? 'Preparing…' : 'Share photo',
                              icon: Icons.ios_share,
                              onPressed: _exporting ? null : _share,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
