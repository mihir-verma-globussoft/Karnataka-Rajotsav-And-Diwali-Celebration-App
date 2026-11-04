import 'dart:math' as math;

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
/// Allows new players to capture an avatar using the front camera. Uploads the
/// image to the player-avatars bucket.
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
        maxWidth: ArcadeSizes.photoCaptureSide,
        maxHeight: ArcadeSizes.photoCaptureSide,
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = math.max(box.maxWidth / 848, box.maxHeight / 1855);
      final canvasW = 848 * scale, canvasH = 1855 * scale;
      final left = (box.maxWidth - canvasW) / 2,
          top = (box.maxHeight - canvasH) / 2;
      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/avatar_setup_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: left + 245 * scale,
            top: top + 850 * scale,
            width: 358 * scale,
            height: 358 * scale,
            child: GestureDetector(
              onTap: _picking || _saving
                  ? null
                  : () => _pickImage(ImageSource.camera),
              child: _AvatarPreview(
                photoBytes: _photo,
                fallbackUrl: widget.player.displayAvatarUrl,
                username: widget.player.username,
                busy: _picking,
              ),
            ),
          ),
          Positioned(
            left: left + 96 * scale,
            top: top + 1260 * scale,
            width: 656 * scale,
            height: 124 * scale,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _photo == null
                    ? (_picking || _saving
                          ? null
                          : () => _pickImage(ImageSource.camera))
                    : (_saving ? null : _save),
                borderRadius: BorderRadius.circular(64 * scale),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(64 * scale),
                    border: Border.all(
                      color: FlappyPalette.festivalGold,
                      width: ArcadeSizes.goldBorder * scale,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: FlappyPalette.glow,
                        blurRadius: 20 * scale,
                        spreadRadius: 2 * scale,
                      ),
                    ],
                    gradient: const LinearGradient(
                      colors: [FlappyPalette.festivalGold, FlappyPalette.gold],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _photo == null
                            ? Icons.camera_alt_outlined
                            : Icons.check_circle_outline,
                        color: FlappyPalette.ink,
                        size: 30 * scale,
                      ),
                      SizedBox(width: AppSpacing.md * scale),
                      Text(
                        _photo == null
                            ? (_picking ? 'OPENING CAMERA…' : 'TAKE SELFIE')
                            : (_saving ? 'SAVING AVATAR…' : 'USE THIS IMAGE'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: FlappyPalette.ink,
                          fontSize: 25 * scale,
                          letterSpacing: AppSpacing.xs * scale,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_photo != null)
            Positioned(
              left: left + 300 * scale,
              top: top + 1210 * scale,
              width: 248 * scale,
              height: 48 * scale,
              child: TextButton(
                onPressed: _saving
                    ? null
                    : () => _pickImage(ImageSource.camera),
                child: const Text('RETAKE SELFIE'),
              ),
            ),
          if (_message != null)
            Positioned(
              left: left + 100 * scale,
              top: top + 1390 * scale,
              width: 648 * scale,
              child: Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (widget.onCancel != null)
            Positioned(
              left: 0,
              top: MediaQuery.paddingOf(context).top,
              child: IconButton(
                onPressed: _saving ? null : widget.onCancel,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
        ],
      );
    },
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
        border: Border.all(
          color: FlappyPalette.festivalGold,
          width: ArcadeSizes.ring,
        ),
        boxShadow: const [
          BoxShadow(color: FlappyPalette.glow, blurRadius: 16, spreadRadius: 2),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (busy)
            Container(
              color: FlappyPalette.black45,
              child: const Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlappyPalette.white,
                  ),
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
      style: const TextStyle(
        fontSize: ArcadeText.initial,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
