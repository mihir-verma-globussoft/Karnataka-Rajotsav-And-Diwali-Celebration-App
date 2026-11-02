# Team Development (6 developers)

## 1. Roles and assignments

| # | Developer | Module (feature dir) | Role |
|---|-----------|----------------------|------|
| 1 | _TBD_ | Karnataka Rajyotsava (`lib/features/rajyotsava/`) | Module owner |
| 2 | _TBD_ | Deepavali (`lib/features/deepavali/`) | Module owner |
| 3 | _TBD_ | Flappy Bird (`lib/features/flappy_bird/`) | Module owner |
| 4 | _TBD_ | High Pitch / Low Pitch (`lib/features/pitch_game/`) | Module owner |
| 5 | _TBD_ | AR (`lib/features/ar/`, Android `.../ar/`, iOS `Runner/Ar/`) | Module owner + native |
| 6 | _TBD_ | Shared foundation | **Integration owner** |

Fill in names once decided.

**Integration owner:** owns `lib/app/`, `lib/core/`, `pubspec.yaml`, `analysis_options.yaml`, `.github/`, `scripts/`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`; reviews every PR that touches them; keeps `main` green; runs the weekly performance check.
**Module owner:** owns `lib/features/<module>/` and `test/features/<module>/` exclusively. The AR owner additionally owns the native AR code (`android/app/src/main/kotlin/**/ar/`, `ios/Runner/Ar/`) and the AR channel handlers; other native files (manifests, Gradle, Info.plist, `project.pbxproj`) are shared — see below.

## 2. Ownership rules

- Only edit your own feature directory. Anything else needs a PR reviewed by the integration owner.
- Two exceptions you may edit directly in your PR: add **one line** for your feature in `lib/app/feature_registry.dart`; add dependencies to `pubspec.yaml` only after the integration owner approves the package in the PR/issue.
- Need a shared widget, token, or util in `core`? Open an issue/PR describing it; the integration owner (or you, with their review) adds it. Do not copy `core` code into features.
- Native manifests/permissions: add your permission line (e.g. `RECORD_AUDIO`, `NSMicrophoneUsageDescription`, camera) in your PR and flag it to the integration owner; Gradle/Podfile/`project.pbxproj` changes need integration-owner review.
- Never import another feature's internals; use its `<name>_feature.dart` routes only.

## 3. Module contract

The scaffolds already exist for all five modules. Start from your `<name>_feature.dart` (routes + home tile) and replace the placeholder page; sub-routes must stay under `/<name>`. Do not add routes elsewhere. `test/app/module_contract_test.dart` checks every registered module (prefix, home tile, opens/back) — if your page needs a fake (like AR's channel), add the override in that test.

A module provides `<name>_feature.dart` exposing `<Name>Routes` (path constants) and `<Name>Feature implements FeatureModule` (see `lib/features/home/` as the reference). Routes are prefixed `/<name>`. Providers are top-level inside the feature. Cross-feature data is passed via route params or a domain interface agreed in an issue, never by reaching into another feature.

## 4. Git workflow

- `main`: always green, protected, PR-only, squash-merge.
- Branches: `feature/<module>/<short-desc>`, `fix/<module>/<desc>`, `chore/<desc>`.
- Small PRs (target < 400 changed lines), merged at least daily; rebase on `main` before opening (`git pull --rebase origin main`).
- PR title: `<module>: <what>`. Description: what/why, screenshots for UI, test evidence, and which shared files (if any) changed.
- Reviews: 1 approval from a teammate; the integration owner is required if shared files changed.
- Don't force-push shared branches; never rewrite `main`.

## 5. Conflict prevention

- Disjoint directories per developer is the main mechanism.
- Shared files with expected contention (`feature_registry.dart`, `pubspec.yaml`): keep edits to one line, keep alphabetical, rebase right before merging, resolve by keeping both lines.
- Do not reformat files you don't own; do not run repo-wide refactors.
- Generated or lock files: only the integration owner resolves `pubspec.lock` conflicts.

## 6. Before every PR

```
export PATH="$HOME/develop/flutter/bin:$PATH"   # if flutter is not on PATH
./scripts/check.sh        # pub get, format check, analyze --fatal-infos, tests
flutter run               # manual sanity check on a device/emulator
```
CI (`.github/workflows/ci.yml`) runs the same script plus a debug APK build.

## 7. Integration and testing responsibilities

- Module owner: unit + widget tests for their module, including loading/empty/error states and a small-screen / 2x text layout.
- Integration owner: keeps CI green, architecture test passing, merges registry changes, runs the smoke test (`integration_test`) on a device before each demo/release, and the performance check.

## 8. Definition of done (per PR)

- `./scripts/check.sh` passes; no new analyzer infos.
- Uses theme tokens, no hard-coded colours/strings for routes; handles loading, empty, error.
- No overflow at 320dp width, landscape, or 2x text; works in light and dark.
- Resources disposed; no work in `build`; lists are lazy.
- Tests added; docs updated if a contract changed.
- Reviewed and approved.

## 9. Performance checks

1. Use a real mid-range Android device (and an iPhone if available); never judge from debug mode.
2. `flutter run --profile` (or `--release` for startup).
3. Open DevTools > Performance: scroll lists, navigate between screens, run animations; look for frames > 16 ms (60 Hz) on UI or raster threads. Use "Track widget builds" / the CPU profiler to find hot paths; Memory tab for leaks after repeated navigation.
4. Startup: `flutter run --profile --trace-startup` and read `build/start_up_info.json`.
5. Record findings in `docs/PROJECT_PROGRESS.md` (device, date, numbers). Baselines have not been taken yet.

## 10. Resolving architectural disagreements

1. Discuss in the PR/issue for at most one working day, with trade-offs written down.
2. If unresolved, the integration owner decides.
3. Record the outcome in `docs/DECISIONS.md`; revisit only with new evidence.
