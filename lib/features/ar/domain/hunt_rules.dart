/// One app for everyone: the placing tools are in every build, locked behind
/// the organiser PIN. `--dart-define=HUNT_ADMIN=false` leaves them out.
const huntAdminBuild = bool.fromEnvironment('HUNT_ADMIN', defaultValue: true);

/// Items beyond this are not drawn. Closer than this, items are shown unless
/// `ArItemSight` on each platform has confirmed a real surface is in front of
/// them: a hit test finding nothing is never read as a wall, so an item with
/// no data about it yet is drawn, not hidden.
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
