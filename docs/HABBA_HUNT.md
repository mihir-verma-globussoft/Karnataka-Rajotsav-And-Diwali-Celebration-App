# Habba Hunt: the AR Game

The AR entry under the Games tab. Players walk around the office and use their camera to find diyas and Kannada flags, with a shared leaderboard.

The screens are Flutter (`lib/features/ar/`). The camera and 3D drawing are native: ARCore (`android/.../ar/`) and ARKit (`ios/Runner/Ar/`).

## How it works

- **Posters:** four printed start-point posters go on office walls. Every item is saved as a position measured from a poster, which is how all phones agree on where it is.
- **Admin:** scans a poster from within 2.5 m, taps anywhere, sets the size, saves. A tap rests the item on a table, floor, wall or any object with detail on it; where the phone finds nothing it floats a metre ahead and stays there. To resize a saved item, remove it and place it again.
- **Players:** scan any poster, walk around, collect what they find. 10 points each, 15 for the first to find it. An item must be within 2 m and on screen to be collected.
- **Finishing:** finding everything leads to the leaderboard with the song (`assets/deepavali/audio/music.mp3`), crackers, diyas and the winner's name. It has a mute button, and the song stops when the page closes or the app is hidden.
- **Data:** the hunt uses the main app's Supabase project and the player's existing authenticated account. Hunt points therefore contribute to the shared arcade total and global leaderboard.

## Admin PIN

Run this in that project's SQL Editor, with your own 6 to 12 digits. Run it again to change it. The PIN is checked on the server and never stored in the app.

```sql
select public.ar_set_admin_pin('your-pin-here');
```

## The two builds

```bash
./scripts/build_release.sh
```

Builds one app for everyone into `build/releases/`: `GlobusHabba.apk` for Android and `GlobusHabba.ipa` for iPhone. It stops at the first failure and checks each app uses the team database and has the placing screen.

The admin tools are in every copy, locked behind the organiser PIN, so players see an "Enter PIN" card and nothing more. `--dart-define=HUNT_ADMIN=false` builds a copy without them.

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

Run every file in `supabase/migrations` in order. The hunt uses the app's normal Google/Supabase session; do not enable anonymous sign-ins for it.

## Known limits

- Items only show within 4 m, and are shown by default: a hit test that finds nothing is never read as a wall in the way, since that is the ordinary result on a blank wall, dim corner, or a spot the phone has not mapped yet. Only a surface the phone actually tracked, confirmed strictly nearer than the item twice in a row, hides it (`ArItemSight`, the same rule on both platforms); a single clear reading, or simply no fresh blocking reading for about a second, shows it again. iPhones with LiDAR hide items behind anything, to the pixel; everywhere else the whole item hides at once.
- Sign-ups are limited to 30 per hour from one internet address by default. An office usually shares one, so raise it under **Rate Limits** before a big start.
- Supabase pauses free projects after about a week of no use. Open the dashboard before an event.
- The leaderboard uses the shared main-app profile and character avatar.
- The leaderboard shows the top 50.
- Scores come from the phone. The server blocks double-scoring and impossibly fast finds, but a modified app could still cheat.
