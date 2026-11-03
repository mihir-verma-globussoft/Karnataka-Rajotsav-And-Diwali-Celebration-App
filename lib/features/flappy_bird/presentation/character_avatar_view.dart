import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/player.dart';
import '../flappy_bird_providers.dart';
import 'widgets/arcade_widgets.dart';

class CharacterAvatarView extends ConsumerStatefulWidget {
  const CharacterAvatarView({
    required this.player,
    required this.onComplete,
    this.onCancel,
    super.key,
  });

  final PlayerProfile player;
  final ValueChanged<PlayerProfile> onComplete;
  final VoidCallback? onCancel;

  @override
  ConsumerState<CharacterAvatarView> createState() =>
      _CharacterAvatarViewState();
}

class _CharacterAvatarViewState extends ConsumerState<CharacterAvatarView> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _photo;
  String _contentType = 'image/jpeg';
  bool _capturing = false;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      Future<void>.microtask(_recoverInterruptedCapture);
    }
  }

  Future<void> _recoverInterruptedCapture() async {
    try {
      final response = await _picker.retrieveLostData();
      final files = response.files;
      if (!response.isEmpty && files != null && files.isNotEmpty) {
        await _loadPhoto(files.first);
      }
    } on Object {
      // Recovery is best effort. A fresh capture remains available.
    }
  }

  Future<void> _capture() async {
    setState(() {
      _capturing = true;
      _message = null;
    });
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (file != null) await _loadPhoto(file);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _message =
              error.code.contains('access') || error.code.contains('permission')
              ? 'Camera access is off. Enable it in system Settings and try again.'
              : 'The camera could not open. Please try again.';
        });
      }
    } on Object {
      if (mounted) {
        setState(
          () => _message = 'The camera could not open. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _loadPhoto(XFile file) async {
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
      setState(
        () => _message = 'That photo is too large. Please take another.',
      );
      return;
    }
    setState(() {
      _photo = bytes;
      _contentType = _safeImageType(file.mimeType);
      _message = null;
    });
  }

  Future<void> _save() async {
    final photo = _photo;
    if (photo == null) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final profile = await ref
          .read(playerRepositoryProvider)
          .updateCharacterAvatar(photo, contentType: _contentType);
      ref
        ..invalidate(flappyAuthStateProvider)
        ..invalidate(dashboardProvider)
        ..invalidate(playerProfileProvider);
      if (mounted) widget.onComplete(profile);
    } on AppFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) {
        setState(() => _message = 'Your photo could not be saved. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ArcadeBackground(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ArcadePanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.player.hasCharacterAvatar
                      ? 'Update your character'
                      : 'Create your character',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Take a photo with your camera. It becomes your flying character and public leaderboard avatar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  label: _photo == null
                      ? 'No player photo captured'
                      : 'Captured player photo preview',
                  image: true,
                  child: Container(
                    width: 164,
                    height: 164,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FlappyPalette.midnight,
                      border: Border.all(
                        color: FlappyPalette.festivalGold,
                        width: 5,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 16),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _photo == null
                        ? const Icon(
                            Icons.camera_alt_outlined,
                            size: 64,
                            color: Colors.white,
                          )
                        : Image.memory(
                            _photo!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _capturing || _saving ? null : _capture,
                    icon: _capturing
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined),
                    label: Text(_photo == null ? 'TAKE PHOTO' : 'RETAKE PHOTO'),
                  ),
                ),
                if (_photo != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('USE AS MY CHARACTER'),
                    ),
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (widget.onCancel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _saving ? null : widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String _safeImageType(String? value) => switch (value) {
  'image/png' => 'image/png',
  'image/webp' => 'image/webp',
  'image/heic' => 'image/heic',
  'image/heif' => 'image/heif',
  _ => 'image/jpeg',
};
