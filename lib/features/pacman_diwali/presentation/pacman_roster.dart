import 'dart:typed_data';

import 'pacman_characters.dart';

/// A character the player can pick as a chaser: photo, name, powers and the
/// cartoon performance shown on the intro page.
class PacmanEnemy {
  const PacmanEnemy({
    required this.name,
    required this.asset,
    required this.sprite,
    required this.kind,
    required this.tagline,
    required this.power,
    required this.attack,
    required this.colorValue,
  });

  final String name;
  final String asset;

  /// Full ghost illustration used in the maze (transparent background).
  final String sprite;
  final CartoonKind kind;
  final String tagline;
  final String power;
  final String attack;

  /// Signature colour: glow in the maze and the power chip on the card.
  final int colorValue;
}

/// Pick three of these as the ghosts. Names can be edited freely.
const List<PacmanEnemy> pacmanEnemies = [
  PacmanEnemy(
    name: 'Uma Shanker – The Destroyer',
    asset: 'assets/pacman/enemy6.png',
    sprite: 'assets/pacman/ghost5.png',
    kind: CartoonKind.destroyer,
    tagline: 'One stomp. Total destruction!',
    power: 'Earthquake Power',
    attack:
        'Earthquake Slam: shakes the ground and throws enemies into the air',
    colorValue: 0xFFFB8C00,
  ),
  PacmanEnemy(
    name: 'Chethan Khali',
    asset: 'assets/pacman/enemy1.png',
    sprite: 'assets/pacman/ghost1.png',
    kind: CartoonKind.fireBreather,
    tagline: 'Breathes fire. Do not get toasted!',
    power: 'Fire Breathing',
    attack: 'Fire Blast: burns everything in his path',
    colorValue: 0xFFE53935,
  ),
  PacmanEnemy(
    name: 'Baby Monster Mihir',
    asset: 'assets/pacman/enemy2.png',
    sprite: 'assets/pacman/ghost2.png',
    kind: CartoonKind.monster,
    tagline: 'A little monster with a big swinging sword.',
    power: 'Monster Sword',
    attack: 'Sword Swing: slashes enemies with a giant sword',
    colorValue: 0xFF8E24AA,
  ),
  PacmanEnemy(
    name: 'Karan Halku',
    asset: 'assets/pacman/enemy3.png',
    sprite: 'assets/pacman/ghost3.png',
    kind: CartoonKind.hulk,
    tagline: 'Hulk mode: smashes everything!',
    power: 'Hulk Strength',
    attack: 'Hulk Smash: crushes everything nearby',
    colorValue: 0xFF43A047,
  ),
  PacmanEnemy(
    name: 'Harsh – Thunder Man',
    asset: 'assets/pacman/enemy4.png',
    sprite: 'assets/pacman/ghost4.png',
    kind: CartoonKind.thunderMan,
    tagline: 'Too fast to catch. Too powerful to stop!',
    power: 'Lightning Speed',
    attack: 'Thunder Dash: moves at lightning speed and shocks enemies',
    colorValue: 0xFFFFC107,
  ),
  PacmanEnemy(
    name: 'Sharukh – The King',
    asset: 'assets/pacman/enemy5.png',
    sprite: 'assets/pacman/ghost6.png',
    kind: CartoonKind.theKing,
    tagline: 'King of hearts. Destroyer of enemies!',
    power: 'Charm Power',
    attack: 'King Pose: freezes enemies with a magical heart-wave',
    colorValue: 0xFF1E88E5,
  ),
];

/// What the intro page hands to the game.
class PacmanSetup {
  const PacmanSetup({required this.selfie, required this.enemyIndexes});

  /// Camera image used as the player, or null for the classic yellow disc.
  final Uint8List? selfie;

  /// Indexes into [pacmanEnemies]; the first three become the ghosts.
  final List<int> enemyIndexes;
}
