import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../domain/image_sharer.dart';

/// Captures the picture inside [boundaryKey] as PNG bytes. Pictures are drawn
/// on an opaque background, so the PNG is never transparent. [pixelRatio] is
/// kept modest so low-memory phones are safe.
Future<Uint8List> captureBoundaryPng(
  GlobalKey boundaryKey, {
  double pixelRatio = 3,
}) async {
  final object = boundaryKey.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) {
    throw StateError('The picture is not on screen.');
  }
  final image = await object.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Could not encode the picture.');
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Captures [boundary] and hands it to [sharer]. Failures show a SnackBar
/// with Retry; closing the share sheet is silent. Returns true if shared.
Future<bool> shareBoundaryPicture({
  required ImageSharer sharer,
  required GlobalKey boundary,
  required String fileName,
  required ScaffoldMessengerState? messenger,
  required VoidCallback onRetry,
  String? text,
}) async {
  try {
    final png = await captureBoundaryPng(boundary);
    await sharer.sharePng(png, fileName: fileName, text: text);
    return true;
  } on Object {
    messenger?.showSnackBar(
      SnackBar(
        content: const Text('Could not share the picture.'),
        action: SnackBarAction(label: 'Retry', onPressed: onRetry),
      ),
    );
    return false;
  }
}
