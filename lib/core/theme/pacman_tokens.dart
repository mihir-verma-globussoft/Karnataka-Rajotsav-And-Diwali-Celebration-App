import 'package:flutter/painting.dart';

/// Colours of the Pac-Man game: a neon-blue maze on near-black. Always dark,
/// like an arcade cabinet. Text on [background] uses `AppColors.onNight`
/// (above 7:1); [pacman] on [wallFill] is above 7:1 too.
abstract final class PacmanPalette {
  static const background = Color(0xff05051a);
  static const wallFill = Color(0xff0b0b3b);
  static const wallEdge = Color(0xff2f5bff);
  static const dot = Color(0xffffe6b8);
  static const pacman = Color(0xffffd21f);

  /// The four ghosts, in order: red, pink, cyan, orange.
  static const ghostRed = Color(0xffff3b30);
  static const ghostPink = Color(0xffff8cc6);
  static const ghostCyan = Color(0xff35e0e0);
  static const ghostOrange = Color(0xffffa630);
  static const ghosts = [ghostRed, ghostPink, ghostCyan, ghostOrange];

  /// A ghost that can be eaten, and its warning flash.
  static const frightened = Color(0xff2234d6);
  static const frightenedFlash = Color(0xfff4f4ff);

  static const eyeWhite = Color(0xffffffff);
  static const pupil = Color(0xff1b2bdb);
}
