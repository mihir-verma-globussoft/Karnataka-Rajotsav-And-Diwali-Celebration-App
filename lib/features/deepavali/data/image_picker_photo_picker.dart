import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/photo_booth.dart';

/// [PhotoPicker] backed by `image_picker`: the system camera or photo picker.
/// Android and iOS ask for camera access themselves the first time.
class ImagePickerPhotoPicker implements PhotoPicker {
  const ImagePickerPhotoPicker();

  /// Photos are scaled down on the way in, so a large camera picture cannot
  /// exhaust memory.
  static const double _maxSide = 1600;
  static const int _quality = 88;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxSide,
        maxHeight: _maxSide,
        imageQuality: _quality,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } on PlatformException catch (e) {
      throw PhotoPickException(switch (e.code) {
        'camera_access_denied' || 'photo_access_denied' => PhotoFailure.denied,
        'no_available_camera' => PhotoFailure.unavailable,
        _ => PhotoFailure.failed,
      });
    } on Object {
      throw const PhotoPickException(PhotoFailure.failed);
    }
  }
}
