import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:share_plus/share_plus.dart';

import '../domain/image_sharer.dart';

/// [ImageSharer] backed by `share_plus` (the system share sheet).
class SharePlusImageSharer implements ImageSharer {
  const SharePlusImageSharer();

  static const String _folder = 'deepavali_share';

  /// Radius of the invisible anchor the iPad share popover points at.
  static const double _anchorRadius = 1;

  @override
  Future<void> sharePng(
    Uint8List png, {
    required String fileName,
    String? text,
  }) async {
    final file = await _write(png, fileName);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png', name: fileName)],
        text: text,
        // iPad needs somewhere to anchor the share sheet.
        sharePositionOrigin: _origin(),
      ),
    );
  }

  /// Writes the picture to a fixed temp folder. The previous picture is
  /// cleared first, but never straight after sharing: the receiving app may
  /// still be reading the file.
  Future<File> _write(Uint8List png, String fileName) async {
    final dir = Directory('${Directory.systemTemp.path}/$_folder');
    try {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } on Object {
      // A leftover file is harmless; it is overwritten below.
    }
    await dir.create(recursive: true);
    final file = File('${dir.path}/$fileName');
    return file.writeAsBytes(png, flush: true);
  }

  /// A small rectangle in the middle of the screen.
  static ui.Rect? _origin() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return null;
    final view = views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    return ui.Rect.fromCircle(
      center: ui.Offset(size.width / 2, size.height / 2),
      radius: _anchorRadius,
    );
  }
}
