/// The short sound effects of the Deepavali tab.
enum Sfx {
  /// A diya is lit (diya game, a wish on the wall).
  diyaLight('diya_light'),

  /// A gust of wind in the diya game.
  gust('gust'),

  /// A win or a high score.
  win('win'),

  /// A correct answer.
  correct('correct'),

  /// A wrong answer.
  wrong('wrong'),

  /// A small tap: colouring a shape, placing a decoration, choosing a design.
  tap('tap');

  const Sfx(this.fileStem);

  /// File name without extension, inside `assets/deepavali/audio/`.
  final String fileStem;
}

/// File name (without extension) of the background song.
const String musicFileStem = 'music';

/// Where the audio files live, relative to the project root.
const String audioAssetFolder = 'assets/deepavali/audio';

/// Extensions the app accepts, in order of preference.
const List<String> audioExtensions = ['mp3', 'ogg', 'm4a', 'aac', 'wav'];

/// Which audio files are actually bundled. Missing files are simply left out:
/// the matching sound stays silent and the mute button is hidden if there is
/// nothing to play at all.
class AudioCatalog {
  const AudioCatalog({this.effects = const {}, this.music});

  /// Builds the catalogue from the list of bundled asset keys (as given by
  /// Flutter's asset manifest, e.g. `assets/deepavali/audio/tap.mp3`).
  factory AudioCatalog.fromAssets(Iterable<String> assetKeys) {
    final keys = assetKeys.toSet();
    String? find(String stem) {
      for (final ext in audioExtensions) {
        final key = '$audioAssetFolder/$stem.$ext';
        if (keys.contains(key)) return key;
      }
      return null;
    }

    return AudioCatalog(
      effects: {for (final s in Sfx.values) s: ?find(s.fileStem)},
      music: find(musicFileStem),
    );
  }

  /// Asset key per available effect.
  final Map<Sfx, String> effects;

  /// Asset key of the background song, or null.
  final String? music;

  bool get hasMusic => music != null;
  bool has(Sfx sfx) => effects.containsKey(sfx);

  /// Is there anything to play? If not, sound controls are hidden.
  bool get isEmpty => effects.isEmpty && music == null;
}

/// Plays the tab's sounds. Implementations must not throw: a sound that cannot
/// play is just silent.
abstract interface class DeepavaliAudio {
  /// Reads which files are bundled.
  Future<AudioCatalog> catalog();

  /// Plays one effect once, quietly, over any music.
  Future<void> playEffect(Sfx sfx);

  /// Starts or resumes the background song.
  Future<void> playMusic();

  /// Pauses the background song (it resumes from the same place).
  Future<void> pauseMusic();

  /// Releases players.
  Future<void> dispose();
}
