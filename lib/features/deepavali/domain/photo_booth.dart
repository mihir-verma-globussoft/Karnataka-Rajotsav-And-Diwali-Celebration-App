import 'dart:typed_data';

/// The festive frames you can put round a photo.
enum PhotoFrame {
  diyas('Diyas'),
  lanterns('Lanterns'),
  rangoli('Rangoli'),
  garland('Garland');

  const PhotoFrame(this.label);
  final String label;
}

/// Where a photo comes from.
enum PhotoSource { camera, gallery }

/// Why a photo could not be taken or chosen.
enum PhotoFailure {
  /// The person said no to camera access.
  denied,

  /// This device has no camera (or it cannot be used).
  unavailable,

  /// Anything else.
  failed,
}

class PhotoPickException implements Exception {
  const PhotoPickException(this.failure);

  final PhotoFailure failure;

  @override
  String toString() => 'PhotoPickException($failure)';
}

/// Takes or chooses a photo. Returns null if the person backs out; throws
/// [PhotoPickException] when it cannot be done. The photo is kept in memory
/// only: nothing is uploaded or stored.
abstract interface class PhotoPicker {
  Future<Uint8List?> pick(PhotoSource source);
}
