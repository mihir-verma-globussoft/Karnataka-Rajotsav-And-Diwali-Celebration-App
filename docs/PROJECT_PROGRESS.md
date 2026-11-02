# Project Progress

**Last updated:** 2026-11-02 20:18 IST

## Objective
One Flutter app (Android + iOS) with five modules built by six people: Karnataka Rajyotsava, Deepavali, Flappy Bird, High/Low Pitch, and a native-backed Karnataka AR experience. Deadline: about two days.

## Module status
Statuses: Not Started, In Progress, Blocked, Ready for Integration, Integrated, Verified.

| Module | Owner | Status | Evidence / notes |
|---|---|---|---|
| Rajyotsava | _TBD_ | Not Started | Scaffold route + placeholder page only; contract tests pass. |
| Deepavali | _TBD_ | Not Started | Scaffold only. |
| Flappy Bird | _TBD_ | Not Started | Scaffold only. Tooling choice pending (ADR-008). |
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
- **iOS build:** not run (Linux host, no Xcode). The Swift channel code in `AppDelegate.swift` is uncompiled.
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
