import 'package:flutter/painting.dart' show Alignment;

/// One developer shown on the Team tab.
class TeamMember {
  const TeamMember({
    required this.name,
    this.photoAsset,
    this.photoAlignment = const Alignment(0, -0.6),
  });

  final String name;

  /// Asset path of the photo (e.g. `assets/team/developer_1.jpg`). When null
  /// or missing, a placeholder avatar is shown.
  final String? photoAsset;

  /// Which part of a non-square photo stays visible in the square crop.
  /// Defaults to near the top so faces are kept in portrait photos.
  final Alignment photoAlignment;
}

/// Edit this list to set real names and photos. Put the image files in
/// `assets/team/` (square, about 400x400 px, JPG/PNG/WebP).
const List<TeamMember> teamMembers = [
  TeamMember(name: 'Mihir Verma', photoAsset: 'assets/team/mihir.jpg'),
  TeamMember(name: 'Mohammed Sharuk', photoAsset: 'assets/team/sharukh.jpg'),
  TeamMember(
    name: 'Umashanker Yadav',
    photoAsset: 'assets/team/uma.jpg',
    photoAlignment: Alignment.bottomCenter,
  ),
  TeamMember(name: 'Chethan Nayak', photoAsset: 'assets/team/chethan.jpg'),
  TeamMember(
    name: 'Karan Singh',
    photoAsset: 'assets/team/karan.jpg',
    // Shifted up from the bottom edge to leave headroom above him, like Uma's.
    photoAlignment: Alignment(0, -0.15),
  ),
  TeamMember(name: 'Harsh Vardhan', photoAsset: 'assets/team/harsh.jpg'),
  TeamMember(name: 'Pavan Kulkarni', photoAsset: 'assets/team/pavan.jpg'),
];
