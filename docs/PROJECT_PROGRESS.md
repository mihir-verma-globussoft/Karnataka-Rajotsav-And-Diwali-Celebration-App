# Project Progress

**Last updated:** 2026-11-03 IST

## Objective
One Flutter app (Android + iOS) with five modules built by six people: Karnataka Rajyotsava, Deepavali, Flappy Bird, High/Low Pitch, and a native-backed Karnataka AR experience. Deadline: about two days.

## Module status
Statuses: Not Started, In Progress, Blocked, Ready for Integration, Integrated, Verified.

| Module | Owner | Status | Evidence / notes |
|---|---|---|---|
| Rajyotsava | _TBD_ | Not Started | Scaffold route + placeholder page only; contract tests pass. |
| Deepavali | _TBD_ | Not Started | Scaffold only. |
| Flappy Bird | Harsh | In Progress | Google account flow, camera character onboarding, Diwali gameplay, three lives, reusable Supabase score backend, leaderboard/profile/settings, live privacy policy, and tests are implemented on `harsh/flappybird`. Migrations 001–003 are deployed to the live Supabase project; migration 004 adds empty per-game stats defaults and still needs deployment. Physical-device camera/gameplay smoke testing remains. |
| High/Low Pitch | _TBD_ | Not Started | Scaffold only. Mic/pitch packages and permission approach pending. |
| AR | _TBD_ | In Progress | Flutter contract + availability screen + channel done and unit-tested; native ARCore/ARKit **not started** (stubs return `unavailable`). |
| Shared foundation | _TBD_ | In Progress | See below. |

No module is Integrated or Verified: nothing has been run on a physical device.

## Shared foundation — verified
- `./scripts/check.sh` passes: format check, `flutter analyze --fatal-infos` (no issues), 44 tests (bootstrap, routing, invalid routes, theme, responsive/overflow, state views, architecture boundaries, per-module contract, AR channel/states).
- `flutter build apk --debug` succeeds (includes the Kotlin AR channel).

## Performance baseline (one physical Android 16 phone, model 2406ERN9CI, 2026-11-02)
Taken with placeholder screens only, so it is a floor to protect, not a feature-level result.
- Cold start, release build: ~540 ms (`am start -W` TotalTime: 563, 519, 543 ms).
- Profile mode, 3 rounds of switching all four tabs plus 3 Games-to-module round trips (63 frames): build avg 6.4 ms, p90 11.2 ms, p99 15.9 ms, worst 16.9 ms; raster avg 4.5 ms, p99 7.8 ms, worst 21.3 ms; 1 frame over the build budget and 1 over the raster budget (budget 16.7 ms at 60 Hz).
- Release APK: 49.6 MB universal (all ABIs); use `--split-per-abi` or an app bundle for distribution.
- Re-run with the command in TEAM_DEVELOPMENT.md section 9 at each integration milestone.

## Not verified / not done
- **Flappy Bird:** live Google/Supabase configuration and the camera-avatar migration are deployed, but camera capture, Google sign-in, avatar upload, and gameplay still require physical-device smoke testing.
- **iOS device:** the configured Simulator build succeeds; a physical-device build/run is still required for final camera and Google sign-in verification.
- `integration_test` and any device run (games, microphone, AR): not run.
- GitHub Actions workflow: written, never executed (no remote).
- No release build or signing.

## Blockers and risks
- **AR has no entry point in the UI** (bottom bar has only Rajyotsava, Deepavali, Games); needs a decision on where to launch it.
- **AR compatibility:** ARCore device support / Google Play Services for AR on Android; ARKit needs A9+. Native work for two platforms by one person in two days is the largest schedule risk; prefer one simple AR scene. AR/VR scope beyond AR is unconfirmed.
- **Audio:** real-time pitch detection needs a capture package and a DSP approach; noisy input and permission denial must be handled; keep processing off the UI isolate.
- **Requirements:** no earlier requirement docs exist in the repo; module features are taken only from the brief.
- **App identity:** IDs set to Android `com.globus.rajotsav_and_diwali_celebration_app`, iOS `com.globus.rajotsavAndDiwaliCelebrationApp` (iOS disallows underscores). The app label is still the default; set before any store/TestFlight build.
- **Repo:** pushed to GitHub (`main`). Branch protection and the first CI run are not yet confirmed.
- **iOS native files:** new Swift files must be added to the Xcode target (cannot be done from this Linux machine).

## Next actions
1. Integration owner: branch protection, confirm CI runs on GitHub; fill owners in TEAM_DEVELOPMENT.md and above.
2. Everyone: branch `feature/<module>/...`, replace your scaffold page, add tests, run `./scripts/check.sh`.
3. Pitch/Flappy owners: propose packages (if any) before adding them.
4. AR owner: extend `ArPlatform`, implement ARCore (Android) then ARKit (iOS) for one MVP scene; test on a real device.
5. Integration owner: device smoke test + profile-mode baseline before each integration milestone.

## Apple guidance review — 2026-11-03
- Reviewed App Review Guidelines 4.8 and 5.1.1 for Google login, privacy policy and account deletion: https://developer.apple.com/app-store/review/guidelines/
- Google-only login needs an equivalent privacy-preserving login option for iOS distribution unless an enumerated exception applies. Sign in with Apple is pending because the requested scope specifies Google authentication.
- The settings implementation includes account deletion. The public policy is live at https://globus-games-arcade.globussoft-4506.chatgpt.site/privacy/ and includes camera-avatar disclosure.

## Flappy Bird verification — 2026-11-03
- A temporary Dart 3.13.7 SDK parsed and formatted all `lib/` and `test/` Dart files. The pure-Dart game domain analyzed with no issues, and a smoke run verified three lives, duplicate-collision suppression, zero floor and final game-over state.
- The migration applied cleanly to temporary PostgreSQL 16 with minimal Supabase Auth stubs. Functional queries verified: automatic profile/stat creation, duplicate game UUID idempotency, lower-score protection, higher-score update, aggregate totals, rank output, username-only profile updates, and denial of direct `player_stats` writes/protected profile-field writes.
- Live Supabase migration history was last verified through `202611030003`. Migration `202611030004_reusable_empty_game_stats.sql` is local and must be deployed for zero-valued stats before a player’s first score in another game.
- `flutter pub get` succeeds, `flutter analyze` reports no issues, all 64 Flutter tests pass, and `flutter build ios --simulator --debug --dart-define-from-file=.env` succeeds. The current Mac has no Android SDK, so a current Android package was not produced here. Google authentication, camera capture/avatar upload, and Android/iOS gameplay remain pending on-device checks.
