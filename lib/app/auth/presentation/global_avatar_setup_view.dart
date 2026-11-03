import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../features/flappy_bird/domain/player.dart';
import '../../../features/flappy_bird/flappy_bird_providers.dart';
import '../../../features/flappy_bird/presentation/widgets/arcade_widgets.dart';

/// Global avatar setup view.
/// Allows new players to capture an avatar using the front camera OR pick one
/// from their photo gallery. Uploads the image to the player-avatars bucket.
class GlobalAvatarSetupView extends ConsumerStatefulWidget {
  const GlobalAvatarSetupView({
    required this.player,
    required this.onComplete,
    this.onCancel,
    super.key,
  });

  final PlayerProfile player;
  final ValueChanged<PlayerProfile> onComplete;
  final VoidCallback? onCancel;

  @override
  ConsumerState<GlobalAvatarSetupView> createState() =>
      _GlobalAvatarSetupViewState();
}

class _GlobalAvatarSetupViewState extends ConsumerState<GlobalAvatarSetupView> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _photo;
  String _contentType = 'image/jpeg';
  bool _picking = false;
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
      // Best effort recovery. Fresh capture remains available.
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _picking = true;
      _message = null;
    });
    try {
      final file = await _picker.pickImage(
        source: source,
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
              ? '${source == ImageSource.camera ? 'Camera' : 'Photos'} access is off. Enable it in device Settings.'
              : 'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}. Try again.';
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _message = 'Could not load photo. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _loadPhoto(XFile file) async {
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.lengthInBytes > 3 * 1024 * 1024) {
      setState(
        () =>
            _message = 'That photo is too large. Please select a smaller one.',
      );
      return;
    }
    final mime = file.mimeType?.toLowerCase();
    final ext = file.path.split('.').last.toLowerCase();
    final contentType = switch (mime) {
      'image/png' => 'image/png',
      'image/webp' => 'image/webp',
      _ => ext == 'png' ? 'image/png' : 'image/jpeg',
    };
    setState(() {
      _photo = bytes;
      _contentType = contentType;
      _message = null;
    });
  }

  Future<void> _save() async {
    final bytes = _photo;
    if (bytes == null) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final updated = await ref
          .read(playerRepositoryProvider)
          .updateCharacterAvatar(bytes, contentType: _contentType);
      ref.invalidate(flappyAuthStateProvider);
      widget.onComplete(updated);
    } on AppFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'Could not save your avatar. Check your connection and retry.',
        );
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
          constraints: const BoxConstraints(maxWidth: 420),
          child: ArcadePanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set up your avatar',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Take a selfie or choose a photo from your gallery. It represents you across all festival games and leaderboards.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                _AvatarPreview(
                  photoBytes: _photo,
                  fallbackUrl: widget.player.displayAvatarUrl,
                  username: widget.player.username,
                  busy: _picking,
                ),
                if (_message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (_photo == null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ArcadeActionButton(
                          label: 'TAKE SELFIE',
                          icon: Icons.camera_alt_outlined,
                          primary: true,
                          onPressed: _picking || _saving
                              ? null
                              : () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ArcadeActionButton(
                          label: 'FROM GALLERY',
                          icon: Icons.photo_library_outlined,
                          onPressed: _picking || _saving
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ArcadeActionButton(
                          label: 'RETAKE CAMERA',
                          icon: Icons.camera_alt_outlined,
                          onPressed: _saving
                              ? null
                              : () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ArcadeActionButton(
                          label: 'GALLERY',
                          icon: Icons.photo_library_outlined,
                          onPressed: _saving
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ArcadeActionButton(
                    label: _saving ? 'SAVING AVATAR...' : 'CONFIRM & CONTINUE',
                    icon: Icons.check_circle_outline,
                    primary: true,
                    onPressed: _saving ? null : () => _save(),
                  ),
                ],
                if (widget.onCancel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: _saving ? null : widget.onCancel,
                    child: const Text('Back'),
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

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.photoBytes,
    required this.fallbackUrl,
    required this.username,
    required this.busy,
  });

  final Uint8List? photoBytes;
  final String? fallbackUrl;
  final String username;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    const size = 150.0;
    Widget child;
    if (photoBytes != null) {
      child = Image.memory(photoBytes!, fit: BoxFit.cover);
    } else if (fallbackUrl != null) {
      child = Image.network(
        fallbackUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _InitialAvatar(username: username),
      );
    } else {
      child = _InitialAvatar(username: username);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FlappyPalette.gold,
        border: Border.all(color: FlappyPalette.festivalGold, width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x99ff9e32), blurRadius: 16, spreadRadius: 2),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (busy)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      username.isEmpty ? '?' : username.characters.first.toUpperCase(),
      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
    ),
  );
}
