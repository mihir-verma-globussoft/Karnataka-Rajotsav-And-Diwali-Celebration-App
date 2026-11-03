import 'dart:typed_data';

/// Hands a finished picture to the system share sheet. The share sheet also
/// offers "save" on both Android and iOS, so no separate gallery permission
/// is needed.
abstract interface class ImageSharer {
  /// Shares [png] under a friendly [fileName], with optional caption [text].
  /// Closing the share sheet without choosing anything is not an error.
  /// Throws if the picture cannot be shared.
  Future<void> sharePng(
    Uint8List png, {
    required String fileName,
    String? text,
  });
}
