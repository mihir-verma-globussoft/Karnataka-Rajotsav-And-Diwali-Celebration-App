# Project Progress

**Last updated:** 2026-11-05 IST

## Objective
One Flutter app (Android + iOS) with five modules built by six people: Karnataka Rajyotsava, Deepavali, Flappy Bird, Pac-Man, and a native-backed Karnataka AR experience. Deadline: about two days.

## Module status
Statuses: Not Started, In Progress, Blocked, Ready for Integration, Integrated, Verified.

| Module | Owner | Status | Evidence / notes |
|---|---|---|---|
| Rajyotsava | Chethan Nayak | In Progress | Full-screen tab (festive banner, countdown, history, facts, wishes with Kannada voice), background song that plays only on this tab with a mute button (needs a licensed MP3 at `assets/audio/huttidare_kannada.mp3`; see its README), Quiz, Learn Kannada with voice-over, Discover Karnataka, Near me (location or manual search, 31 districts), 291 places from `docs/data/karnataka_famous_places_google_maps.csv` with directions in Apple/Google Maps, Songs & Folk Arts with YouTube links. Packages added: `flutter_tts`, `geolocator`, `url_launcher`, `audioplayers` (need integration-owner sign-off). |
| Deepavali | Mihir Verma (built with Claude) | Ready for Integration | Full-screen tab, always dark, Poppins bundled for offline use. Hero with intro (skip/replay) and countdown to Lakshmi Puja (8 Nov 2026 IST, five-day schedule); Discover Deepavali (six topics); Deepavali Around India (six cities, detail screens, sourced facts, photo credits); Light the Diyas (wind game, three levels plus relaxed mode, best times); Quiz (23 questions, 10 per run); Rangoli Studio (33 shapes, symmetry, undo, share); Greeting Card (four designs, share); More to Explore (diya wall saved on the device, Guess the object, five-day timeline, Which city is for you?, Decorate your home, Photo booth with camera or gallery); mute button for the background song; sound effects always play; vibration on taps; whole app portrait only. Checked on the physical phone (see below). Packages added: `google_fonts`, `shared_preferences`, `share_plus`, `image_picker` (need integration-owner sign-off; `audioplayers` was added by Rajyotsava and is reused). Shared-file edits: `app_tokens.dart` (tokens), `home_page.dart` (`TickerMode` per tab), `bootstrap.dart` and the Android manifest / iOS `Info.plist` (portrait lock; camera and photo-library usage text), test helpers. |
| Flappy Bird | Harsh | In Progress | Google account flow, camera-character onboarding, Diwali gameplay, three lives, reusable Supabase score backend, leaderboard/profile/settings, live privacy policy, and tests are implemented on `harsh/flappybird`. The shared score migrations and global arcade aggregate board are deployed to the live Supabase project. Physical-device camera, Google sign-in, and gameplay verification remain. |
| Pac-Man (Diwali edition) | _TBD_ | Done | Replaced the High/Low Pitch game; ported from Raj2503/Pacman-Flutter (MIT). Diwali theme, pick 3 of 6 chasers, selfie player, game-over sound, scores screen (personal best, games, total, last score, global rank, leaderboard) on the shared Supabase backend as game `pacman`; migration `202611040003_pacman_game.sql` must be deployed with the shared score migrations. |
| AR | _TBD_ | In Progress | Flutter contract + availability screen + channel done and unit-tested; native ARCore/ARKit **not started** (stubs return `unavailable`). |
| Shared foundation | _TBD_ | In Progress | See below. |

No module is Integrated or Verified: nothing has been run on a physical device.

## Shared foundation — verified
- `./scripts/check.sh` passes: format check, `flutter analyze --fatal-infos` (no issues), 528 tests (bootstrap, routing, orientation, theme, responsive/overflow at 320x568 and 2x text in light and dark, state views, architecture boundaries, per-module contract, AR channel/states, Rajyotsava, and 239 for Deepavali covering content, game rules, persistence, sharing, audio, accessibility, contrast, offline guarantees and the licence audit).
- `flutter build apk --debug` succeeds (includes the Kotlin AR channel).

## Performance baseline (one physical Android 16 phone, model 2406ERN9CI, 2026-11-02)
Taken with placeholder screens only, so it is a floor to protect, not a feature-level result.
- Cold start, release build: ~540 ms (`am start -W` TotalTime: 563, 519, 543 ms).
- Profile mode, 3 rounds of switching all four tabs plus 3 Games-to-module round trips (63 frames): build avg 6.4 ms, p90 11.2 ms, p99 15.9 ms, worst 16.9 ms; raster avg 4.5 ms, p99 7.8 ms, worst 21.3 ms; 1 frame over the build budget and 1 over the raster budget (budget 16.7 ms at 60 Hz).
- Release APK: 49.6 MB universal (all ABIs); use `--split-per-abi` or an app bundle for distribution.
- Re-run with the command in TEAM_DEVELOPMENT.md section 9 at each integration milestone.

## Deepavali performance and size (one physical Android 16 phone, model 2406ERN9CI, 2026-11-03)
Profile mode, `flutter drive` with the traces in `integration_test/perf_test.dart` (the Deepavali tab animates all the time, so these traces use fixed frame counts instead of `pumpAndSettle`). Two full runs; the phone's results move by a few milliseconds between runs.
- Tab switching (all four tabs, 3 rounds, plus Games round trips): build p99 13.8 and 17.9 ms in the two runs (target 16), raster p99 5 ms.
- Deepavali, scrolling the whole page down and up: build p99 12.5 to 12.8 ms.
- Deepavali, diya game running with wind: build p99 19.9 ms before and 13.9 ms after the fix below, no frame over budget after it.
- Deepavali, opening Decorate and returning: build p99 17 to 18 ms, worst 28 to 35 ms (one frame as the screen opens or closes).
- Raster: the first 6 to 9 frames after the Deepavali page appears (first scroll, or returning to the tab) take 20 to 30 ms, then settle to 5 ms. The time is spent waiting in the final submit step and ramps up and down smoothly, which looks like the phone's GPU clock waking from idle (the engine fell back to Impeller on OpenGLES on this phone); it is not caused by one expensive widget. Not fixed.
- Fixed from the traces: the diya game rebuilt its whole board ten times a second (now only when a diya, the clock second or the wind state changes); every section is now its own repaint boundary, and the hero's bobbing arrow and the timeline's glowing dot have their own boundaries, so one animating widget no longer re-records the whole long page.
- Release APK, `--split-per-abi`: arm64 35.8 MB, armeabi-v7a 33.4 MB, x86_64 37.2 MB. The Deepavali tab's assets are 3.7 MB of the 34.0 MB arm64 download (audio 1.9, photos 1.5, font 0.3); the song was re-encoded 7.7 MB to 1.9 MB.
- Not measured: memory after repeated visits (no DevTools run), cold start with the Deepavali tab open, battery.

## Renderer experiments on the Xiaomi 2406ERN9CI (2026-11-05)
Profile mode, `integration_test/perf_test.dart` and `rajyotsava_perf_test.dart`. On this phone Flutter falls back to Impeller on OpenGL ES (about 98% of raster time is GPU submit).
- **Forcing Vulkan crashes the app at launch** ("invalid Android context"). Do not set `io.flutter.embedding.android.ImpellerBackend=vulkan`.
- **Skia** (`io.flutter.embedding.android.EnableImpeller=false`) is a trade-off, so it is **not shipped**. Rajyotsava scroll: late raster frames 125/152 to 3/114, avg raster 22.9 to 9.6 ms; collection and screen transitions also much better; card reveal 116/142 to 72/159. But Deepavali scroll got worse: 140/150 late frames, raster avg 24 ms (earlier GLES run: 18/160). Tab switching and the diya game are fine either way.
- With the Deepavali hero's animated layers switched off (`idleClock = null`) Skia's Deepavali scroll raster dropped from 24 to 5 ms in one run, yet the hero is off-screen for most of that trace and pausing the layers while scrolling changed nothing. Raster times ramp smoothly (34, 22, 12, 27 ms), so the GPU clock governor is the likelier cause. Cause not found.
- Removing Rajyotsava's tab-wide fireworks/confetti overlay cut its scroll raster from 22.9 to 12.0 ms under GLES (module owner: Chethan Nayak).
- Open: Rajyotsava card reveal costs a flat 35 to 43 ms per frame while open. A like-for-like GLES re-run of the Deepavali suite is needed before choosing a renderer.

## Not verified / not done
- **Flappy Bird:** live Google/Supabase configuration and the camera-avatar migration are deployed, but camera capture, Google sign-in, avatar upload, and gameplay still require physical-device smoke testing.
- **iOS build:** not run (Linux host, no Xcode). The Swift channel code in `AppDelegate.swift` is uncompiled. For Deepavali this also means untested on iPhone: share sheet and iPad popover anchor, camera and photo-library prompts, the silent-switch behaviour of the audio, the portrait lock, and VoiceOver.
- **Deepavali:** not heard by a person (sounds were only checked to start and stop); TalkBack was exercised through the semantics tree in tests, not with a screen reader on the phone; offline was checked by test and code review (no network calls, fonts and media bundled), not in airplane mode.
- `integration_test` and any device run (games, microphone, AR): not run.
- GitHub Actions workflow: written, never executed (no remote).
- No release build or signing.

## Blockers and risks
- **Deepavali song licence:** `assets/deepavali/audio/music.mp3` is the supplied song "Happy Diwali" (film Home Delivery); its tags name T-Series. The team must confirm it may distribute that recording (credits are kept in `assets/deepavali/audio/CREDITS.md` and the photo credits sheet in the cities gallery; there is no credits screen at the bottom of the page). Four of the six city photos (Varanasi, Jaipur, Kolkata, Mumbai) were also supplied without a source, and their licence is likewise unconfirmed.
- **Deepavali dates:** 8 Nov 2026 for Lakshmi Puja is the team's chosen date, not independently confirmed; regional calendars differ.
- **AR has no entry point in the UI** (bottom bar has only Rajyotsava, Deepavali, Games); needs a decision on where to launch it.
- **AR compatibility:** ARCore device support / Google Play Services for AR on Android; ARKit needs A9+. Native work for two platforms by one person in two days is the largest schedule risk; prefer one simple AR scene. AR/VR scope beyond AR is unconfirmed.
- **Requirements:** no earlier requirement docs exist in the repo; module features are taken only from the brief.
- **App identity:** display name "Globus Habba". IDs: Android `com.globus.rajotsav_and_diwali_celebration_app`, iOS `com.globussoft.rajotsavAndDiwaliCelebrationApp` (explicit App ID registered by Globussoft, Apple team `JDGV77HJK6`; iOS disallows underscores).
- **Repo:** pushed to GitHub (`main`). Branch protection and the first CI run are not yet confirmed.
- **iOS native files:** new Swift files must be added to the Xcode target (cannot be done from this Linux machine).

## Next actions
1. Integration owner: branch protection, confirm CI runs on GitHub; fill owners in TEAM_DEVELOPMENT.md and above.
2. Everyone: branch `feature/<module>/...`, replace your scaffold page, add tests, run `./scripts/check.sh`.
3. Flappy Bird dependencies and backend are already integrated on its feature branch.
4. AR owner: extend `ArPlatform`, implement ARCore (Android) then ARKit (iOS) for one MVP scene; test on a real device.
5. Integration owner: device smoke test + profile-mode baseline before each integration milestone.

## Habba Hunt: the AR Game (under the Games tab)

State on 2026-11-04. Setup, the two builds and the tests are in [HABBA_HUNT.md](HABBA_HUNT.md).

- **Built:** native ARKit and ARCore views with Flutter screens, poster-based positions, admin placing with a server-checked PIN, hunt, leaderboard, offline saving of finds, one app for everyone with admin behind the PIN.
- **Backend:** the main shared Supabase project. Hunt points use the authenticated app account and contribute to the global arcade board.
- **Checked:** on an iPhone 13 (iOS 27) the camera, poster detection, placing and hunting ran.
- **Not checked:** ARCore has never run on a real Android phone. The automated AR test on a real iPhone needs a USB connection.

## Prize screen and cleanup (2026-11-05)
- The Games tab trophy opens one screen with the global rank, the per-game scoreboard and the combined leaderboard. Icons, medals, avatars and text were enlarged on it, on Flappy Bird and on Pac-Man; the Games tab volume button now matches the Deepavali one and sits after the trophy.
- Removed unused code: the old separate Hunt database connection (`hunt_connection.dart`, `main_app_player.dart`, their tests) and `city_day.png`.
- Migrations renumbered so no two share a version: `202611050003_ar_hunt_item_scale.sql`, `202611050004_my_game_scores.sql`.
- **Must be applied by the Supabase project owner:** `202611050003` and `202611050004`. Until `202611050004` is applied, the scoreboard shows raw best scores instead of points.
- Not run on iOS.
