/// `--dart-define=HUNT_ADMIN=true` makes the admin build, with the placing
/// tools. Anything else is the user build, which never shows them.
const huntAdminBuild = bool.fromEnvironment('HUNT_ADMIN');

/// Items beyond this are not drawn. AR has no idea where the walls are, so
/// anything drawn further away would show through them and spoil the hunt.
const huntVisibleRadiusMetres = 6.0;

/// A player must be this close to collect an item, and looking at it.
const huntCollectRadiusMetres = 2.0;

/// How close the player is to the nearest item they have not found.
enum HuntHeat {
  cold('Cold'),
  warm('Getting warmer'),
  hot('Hot!'),
  burning('Right here!');

  const HuntHeat(this.label);

  final String label;

  static HuntHeat fromDistance(double metres) {
    if (metres <= huntCollectRadiusMetres) return burning;
    if (metres <= huntVisibleRadiusMetres) return hot;
    if (metres <= 12) return warm;
    return cold;
  }
}
