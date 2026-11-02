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
- `./scripts/check.sh` passes: format check, `flutter analyze --fatal-infos` (no issues), 36 tests (bootstrap, routing, invalid routes, theme, responsive/overflow, state views, architecture boundaries, per-module contract, AR channel/states).
- `flutter build apk --debug` succeeds (includes the Kotlin AR channel).

## Not verified / not done
- **iOS build:** not run (Linux host, no Xcode). The Swift channel code in `AppDelegate.swift` is uncompiled.
- `integration_test` and any device run (games, microphone, AR): not run.
- GitHub Actions workflow: written, never executed (no remote).
- No performance baseline (profile mode on device).
- No release build or signing.

## Blockers and risks
- **AR compatibility:** ARCore device support / Google Play Services for AR on Android; ARKit needs A9+. Native work for two platforms by one person in two days is the largest schedule risk; prefer one simple AR scene. AR/VR scope beyond AR is unconfirmed.
- **Audio:** real-time pitch detection needs a capture package and a DSP approach; noisy input and permission denial must be handled; keep processing off the UI isolate.
- **Requirements:** no earlier requirement docs exist in the repo; module features are taken only from the brief.
- **App identity:** IDs set to Android `com.globus.rajotsav_and_diwali_celebration_app`, iOS `com.globus.rajotsavAndDiwaliCelebrationApp` (iOS disallows underscores). The app label is still the default; set before any store/TestFlight build.
- **Repo:** git initialised locally, no commits or remote yet.
- **iOS native files:** new Swift files must be added to the Xcode target (cannot be done from this Linux machine).

## Next actions
1. Integration owner: initial commit, remote, branch protection; fill owners in TEAM_DEVELOPMENT.md and above.
2. Everyone: branch `feature/<module>/...`, replace your scaffold page, add tests, run `./scripts/check.sh`.
3. Pitch/Flappy owners: propose packages (if any) before adding them.
4. AR owner: extend `ArPlatform`, implement ARCore (Android) then ARKit (iOS) for one MVP scene; test on a real device.
5. Integration owner: device smoke test + profile-mode baseline before each integration milestone.
