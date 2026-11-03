# Flappy Bird account and Supabase setup

## Implemented structure

The module keeps the host app's Riverpod and `go_router` architecture:

- `domain/`: player models, repository contracts, game result, preferences and
  the pure-Dart three-life game session.
- `data/`: Google/Supabase authentication, Supabase player repository, and
  local preferences/pending-result storage.
- `presentation/`: login, camera character onboarding, Diwali-themed game,
  dashboard, leaderboard, profile and settings.
- `supabase/migrations/`: schema, trigger, RLS, leaderboard functions,
  idempotent score submission and account deletion.

The gameplay uses one Flutter ticker and normalized coordinates. A collision
immediately moves the session out of `playing`, so repeated collision callbacks
cannot deduct another life. A new game always creates a new UUID and starts with
three lives.

## 1. Supabase

1. Create a Supabase project.
2. Apply all files in `supabase/migrations/` in filename order with the
   Supabase CLI (`supabase db push`) or paste each into the SQL editor once.
3. In **Authentication > Providers > Google**, enable Google and add the Web
   OAuth client ID and secret created in Google Cloud.
4. Copy the project URL and publishable/anon key from the project API settings.
   Never use the service-role key in this app.

The migrations automatically create profiles and per-game statistics for new
Auth users. The reusable score RPC accepts a registered game slug. Clients can
update only their own username and character-avatar URL. Score and aggregate
statistics writes are available only through `submit_game_result`.

The `player-avatars` Storage bucket has a 2 MB object limit. Players can upload,
replace, or delete only objects within their own UUID folder. Avatar objects are
public because they appear on the global leaderboard; email addresses remain
private.

## 2. Google Cloud OAuth

Create three OAuth clients under the same Google Cloud project:

- **Web application**: its client ID is `GOOGLE_WEB_CLIENT_ID` and is also
  configured in the Supabase Google provider.
- **Android**: package
  `com.globus.rajotsav_and_diwali_celebration_app`. Add SHA-1 and SHA-256 for
  every debug/release signing certificate used to build the app.
- **iOS**: bundle ID `com.globus.rajotsavAndDiwaliCelebrationApp`. Its client ID
  is `GOOGLE_IOS_CLIENT_ID`.

For iOS, add the reversed iOS client ID as a `CFBundleURLSchemes` value in
`ios/Runner/Info.plist`, or add the generated `GoogleService-Info.plist` to the
Runner target. This value is project-specific and cannot be committed safely as
a fabricated placeholder.

Useful fingerprint command for the Android debug key:

```sh
keytool -list -v -alias androiddebugkey \
  -keystore "$HOME/.android/debug.keystore" -storepass android -keypass android
```

## 3. Build configuration

Copy `.env.example` to an ignored local file and replace every placeholder.
Pass it with Flutter's define-file option:

```sh
flutter pub get
flutter run --dart-define-from-file=.env
```

Required:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (or the newer publishable key)
- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_IOS_CLIENT_ID` for iOS

The production privacy policy is
`https://globus-games-arcade.globussoft-4506.chatgpt.site/privacy/`.

## 4. Security behavior

- RLS is enabled on all three player tables.
- Other players' email addresses are never returned by the leaderboard RPC.
- `submit_game_result` derives the player from `auth.uid()`.
- A game UUID is inserted once; retries return the existing aggregate and do
  not increment `total_games` or `total_score` again.
- High score uses `greatest(existing, submitted)` in the same transaction.
- The function validates bounds, duration plausibility, timestamps, and a
  per-user hourly submission limit.
- Failed client submissions remain locally queued and are retried after the
  next dashboard load.
- Camera capture is invoked only after the player taps the button. There is no
  media-library path. The photo is limited to 640×640 at capture and uploaded
  only after confirmation; Android interrupted-capture recovery is supported.

Client-reported gameplay cannot be fully cheat-proof. Stronger protection
would require the server to issue a short-lived game session and validate a
signed event stream or run authoritative simulation server-side.

## 5. Apple review requirements

The requested implementation uses Google as its account provider. Apple App
Review Guideline 4.8 generally requires an equivalent privacy-preserving login
option for apps using Google as the primary account login. Add Sign in with
Apple before an App Store submission unless the app qualifies for one of the
listed exceptions.

Guideline 5.1.1 also requires an accessible privacy-policy link and in-app
account deletion. The settings screen includes account deletion; configure the
real policy URL before submission.

Reviewed 2026-11-03:

- https://developer.apple.com/app-store/review/guidelines/ (4.8, 5.1.1)
- https://supabase.com/docs/reference/dart/auth-signinwithidtoken
- https://supabase.com/docs/guides/auth/social-login/auth-google
- https://developer.apple.com/documentation/bundleresources/information-property-list/nscamerausagedescription
- https://pub.dev/packages/image_picker

## 6. Verification

After Flutter is installed and OAuth values are configured:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test test/features/flappy_bird
flutter test
flutter test integration_test -d <device-id>
```

Google authentication and score delivery require a physical device or properly
configured emulator/simulator plus a live Supabase project. Verify both Android
and iOS sign-in and URL handling before release.

## Attribution

The city background and the starting physics reference came from the MIT
licensed `moha-b/Flappy-Bird` project. Its license is preserved in
`third_party_licenses/moha-b-Flappy-Bird-LICENSE.txt`. The original global
state and periodic timers were replaced to fit this app's architecture and the
three-life requirement. The source project's `Tintin.mp3` was not imported
because its underlying music rights are unclear.

The MIT license covers the material supplied by that repository; it does not
establish ownership of third-party game names or trademarks. Review the final
product name and store artwork before distribution.
