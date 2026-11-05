/// `--dart-define=HUNT_ADMIN=true` makes the admin build, with the placing
/// tools. Anything else is the user build, which never shows them.
const huntAdminBuild = bool.fromEnvironment('HUNT_ADMIN');

/// Items beyond this are not drawn. Closer than this, `ArItemSight` on each
/// platform decides, as most phones cannot sense a plain wall.
const huntVisibleRadiusMetres = 4.0;

/// The models are built larger than life; this draws the standard size at about
/// real life. An item's own size multiplies it.
const huntModelScale = 0.5;

/// The organiser's size slider, where 1 is the standard size.
const huntItemMinScale = 0.5;
const huntItemMaxScale = 2.0;

/// Stops on the slider. Each one redraws the preview, so not a continuous one.
const huntItemScaleSteps = 6;

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
