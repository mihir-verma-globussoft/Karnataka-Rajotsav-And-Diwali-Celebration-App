# Habba Hunt

An office AR game for iPhone and Android. Players walk around the office and use
their camera to find diyas and Kannada flags. Everyone shares one leaderboard.

This is a standalone Flutter app, built separately so it can be merged into the
main app later (see "Merging"). AR runs natively: ARKit on iOS, ARCore on Android.

## How it works

- **Posters:** four printed start-point posters go on office walls. Each diya and
  flag is saved as a position measured from a poster, which is how every phone
  agrees on where it is.
- **Admin:** stands in the office, scans a poster, taps a spot, saves.
- **Players:** type a name, scan any poster, walk around, collect what they find.
  10 points each, 15 if they are the first to find it.
- **Shared data:** positions, finds and scores live in Habba Hunt's own free Supabase
  project (`jxpedobynwyxdwjlqjwk`, the "Habba Hunt" project on the organiser's account),
  so the game cannot affect the main app's players or scores.

## Setup

The database is already set up: tables created and name-only join switched on. The one
thing left is the admin PIN, which only the organiser should know. In the Supabase SQL
Editor, run this with your own 6 to 12 digits:

```sql
select public.ar_set_admin_pin('your-pin-here');
```

Run it again any time to change the PIN.

To set up a new database instead: run every file in `supabase/migrations` in order except
`*_set_admin_user_credentials.sql`, turn on **Authentication > Providers > Allow anonymous
sign-ins**, set the PIN, and put the new URL and publishable key in
`lib/core/config/app_config.dart`. Sign-ins are limited to 30 per hour from one internet
address by default; raise that under **Rate Limits** if a whole office joins at once.

## The two builds

Same code, one flag. In the user build the compiler removes the placing and items
screens. The small admin card and PIN box stay in the file but can never appear.

```bash
./scripts/build_release.sh
```

This builds `HabbaHunt-USER` and `HabbaHunt-ADMIN`, as an `.apk`, a smaller `-arm64.apk`
for sharing (64-bit phones only), and an `.ipa`, into `build/habba_hunt/`. It stops at the first failure, and checks each app really uses the
database and has the right tools. Do not add `--no-pub` to a release build: it leaves
test-only code in the app, and the build fails.

The admin build is just `--dart-define=HUNT_ADMIN=true`. Both use one app ID, so
installing one replaces the other on a phone. The `.ipa` files only install on iPhones
registered to the Apple team; for any other iPhone use TestFlight. Android phones need
"install unknown apps" allowed.

In the admin build, open **Admin > Enter PIN**. The PIN is checked on the server and
never stored in the app, so a copied admin build is no use without it. Admins can
test finding items, but never score.

## Running the game

1. Print `posters/habba_hunt_posters.pdf` at **100% / Actual size**. The ruler on each
   page must measure exactly 18 cm.
2. Stick each poster flat on a wall at eye level, in good light. **Do not move a
   poster after placing items against it**, or they all move with it.
3. Keep items within about 15 m of their poster: AR slowly drifts the further you walk.
4. Close the hunt, keeping all scores, with:
   ```sql
   update public.games set is_active = false where slug = 'ar_hunt';
   ```

## Try it without the server

Demo mode needs no setup. You are an admin, and placed items last until the app
closes, on that one phone. It is left out of release builds.

```bash
flutter run --profile --dart-define=HUNT_DEMO=true --dart-define=HUNT_ADMIN=true
```

Use a real phone: simulators and emulators cannot run AR here. Use `--profile`, as
debug builds can fail to start on recent iOS versions.

## Tests

Work test-first: write a failing test, then the code that makes it pass.

```bash
./scripts/check.sh    # format, analyze, unit and widget tests

# Database rules, on an in-memory Postgres
cd tool && npm i --no-save @electric-sql/pglite && node test_migration.mjs
```

Integration tests run the real app on a real device or simulator:

```bash
# The whole game through the real screens (camera and server are stand-ins)
flutter test integration_test/hunt_flow_test.dart -d <device>

# The real Kotlin and Swift AR code. Starts a real AR session on a phone with AR
flutter test integration_test/native_ar_test.dart -d <device>

# The real app code against the real database. Creates a test player
flutter test integration_test/live_backend_test.dart -d <device> --dart-define=HUNT_LIVE=true
```

An iPhone must be plugged in by USB: `flutter test` cannot start on a wireless one. Add
`--dart-define=HUNT_TEST_PIN=...`
to the live test to cover the admin tools too. It leaves a test player behind, so remove it
afterwards in the SQL Editor:

```sql
delete from auth.users where raw_user_meta_data->>'name' = 'Live Test';
```

## Known limits

- AR cannot see walls, so items show only within 6 m, and can be collected only from
  2 m away while on screen.
- Scores come from the phone. The server blocks double-scoring and impossibly fast
  finds, but a determined cheat with a modified app is still possible.
- A player's identity lives on their phone, so reinstalling means starting again.
- The leaderboard shows the top 50.

## Merging into the main app

Same paths on purpose, so most of this is moving folders:

1. Replace `lib/features/ar/` with this app's copy, and copy `assets/ar/`.
2. Copy the Kotlin `ar/` folder and `ios/Runner/Ar/` (add both Swift files to the
   Runner target in Xcode, and delete the inline stub from `AppDelegate.swift`).
3. Copy the `AR hunt` tokens from `lib/core/theme/app_tokens.dart`.
4. Register `ArHuntViewFactory` as in this app's `MainActivity.kt` and `AppDelegate.swift`.
5. Android: add the ARCore dependency, the camera permission, and the
   `com.google.ar.core` meta-data (`minSdk` must be at least 24).
6. iOS: the main `Info.plist` has `NSCameraUsageDescription` twice. Keep one, and
   mention AR in it.
7. Add `prepare` and `openSettings` to the three fake `ArPlatform`s in the main tests.
8. Leave behind `lib/app/`, as the main app has its own login. Players are then known
   by their Google account, and nothing in the feature changes. Add `HUNT_ADMIN=true`
   to get an admin build of the main app.
9. Keep the main app's own `lib/core/config/app_config.dart`: this copy points at Habba
   Hunt's database.
10. Run `supabase/migrations/202611040003_ar_hunt.sql` on the team's project and set a PIN
    there. Do **not** turn on anonymous sign-ins on that project: it would let anyone with
    the app's public key post scores to the other games. Items and scores from this
    standalone database do not carry over.
