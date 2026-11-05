# Habba Hunt: the AR Game

The AR entry under the Games tab. Players walk around the office and use their camera to find diyas and Kannada flags, with a shared leaderboard.

The screens are Flutter (`lib/features/ar/`). The camera and 3D drawing are native: ARCore (`android/.../ar/`) and ARKit (`ios/Runner/Ar/`).

## How it works

- **Posters:** four printed start-point posters go on office walls. Every item is saved as a position measured from a poster, which is how all phones agree on where it is.
- **Admin:** scans a poster from within 2.5 m, taps anywhere, sets the size, saves. A tap rests the item on a table, floor, wall or any object with detail on it; where the phone finds nothing it floats a metre ahead and stays there. To resize a saved item, remove it and place it again.
- **Players:** scan any poster, walk around, collect what they find. 10 points each, 15 for the first to find it. An item must be within 2 m and on screen to be collected.
- **Finishing:** finding everything leads to the leaderboard with the song (`assets/deepavali/audio/music.mp3`), crackers, diyas and the winner's name. It has a mute button, and the song stops when the page closes or the app is hidden.
- **Data:** the game uses its own Supabase project (`jxpedobynwyxdwjlqjwk`), not the main app's. Each main app account quietly gets its own player there under the same name, kept on the phone. See `data/hunt_connection.dart`.

## Admin PIN

Run this in that project's SQL Editor, with your own 6 to 12 digits. Run it again to change it. The PIN is checked on the server and never stored in the app.

```sql
select public.ar_set_admin_pin('your-pin-here');
```

## The two builds

```bash
./scripts/build_release.sh
```

Builds `GlobusHabba-USER` for players and `GlobusHabba-ADMIN` for the organiser into `build/releases/`, each as an `.apk`, a smaller `-arm64.apk` for sharing, and an `.ipa`. It stops at the first failure and checks each app has the right database and tools. Do not use `--no-pub` for a release: it leaves test-only code in and the build fails.

The only difference is `--dart-define=HUNT_ADMIN=true`. In the user build the compiler removes the placing and items screens; the small admin card and PIN box stay in the file but can never appear. Both use one app ID, so installing one replaces the other.

## Running the game

1. Print `docs/ar_hunt/habba_hunt_posters.pdf` at **100% / Actual size**. The ruler on each page must measure exactly 18 cm.
2. Stick each poster flat on a wall at eye level, in good light. **Do not move a poster after placing items against it**, or they all move with it.
3. Keep items within about 15 m of their poster: AR slowly drifts the further you walk.
4. To close the hunt, keeping all scores:
   ```sql
   update public.games set is_active = false where slug = 'ar_hunt';
   ```

## Tests

Work test-first: write a failing test, then the code that makes it pass.

```bash
./scripts/check.sh    # includes test/features/ar/

# Database rules, on an in-memory Postgres
cd tool/ar_hunt && npm i --no-save @electric-sql/pglite && node test_migration.mjs

# The whole game through the real screens (camera and server are stand-ins)
flutter test integration_test/hunt_flow_test.dart -d <device>

# The real Kotlin and Swift AR code. Starts a real AR session on a phone with AR
flutter test integration_test/native_ar_test.dart -d <device>

# The real connection against the real database. Creates a "Live Test" player
flutter test integration_test/live_backend_test.dart -d <device> --dart-define=HUNT_LIVE=true
```

An iPhone must be plugged in by USB: `flutter test` cannot start on a wireless one.

## Setting up a new database

Run every file in `supabase/migrations` in order, except `*_set_admin_user_credentials.sql`. Turn on **Authentication > Providers > Allow anonymous sign-ins**, set the PIN, and pass the new URL and publishable key with `--dart-define=HUNT_SUPABASE_URL=...` and `--dart-define=HUNT_SUPABASE_KEY=...`, or change the defaults in `hunt_connection.dart`.

Do **not** turn on anonymous sign-ins on the main app's project: anyone with its public key could then post scores to the other games.

## Known limits

- Items only show within 4 m. Further than 1.5 m away, an item stays hidden until the phone confirms a clear view of it, by finding the surface it rests on or something beyond it. Once seen it stays shown until a surface is found in front of it twice in a row, which hides it even close up (`ArItemSight`, on both platforms). While placing, items start shown. So a plain wall hides items beyond 1.5 m, and an item on a surface the phone cannot track only appears from 1.5 m away. Within 1.5 m, a plain wall a phone cannot sense can still let an item show. iPhones with LiDAR also hide items behind anything, to the pixel; everywhere else the whole item hides at once.
- Sign-ups are limited to 30 per hour from one internet address by default. An office usually shares one, so raise it under **Rate Limits** before a big start.
- Supabase pauses free projects after about a week of no use. Open the dashboard before an event.
- A player's name is read from the main app once, when they first join the game.
- The leaderboard shows the top 50.
- Scores come from the phone. The server blocks double-scoring and impossibly fast finds, but a modified app could still cheat.
