# Karnataka Rajotsav & Diwali Celebration App

A single Flutter app (Android and iOS) for the Karnataka Rajyotsava and Deepavali festivals. It is built by six people as five modules plus a shared foundation.

## Modules

| Module | Folder | Scope |
|---|---|---|
| Karnataka Rajyotsava | `lib/features/rajyotsava` | Celebration home, quizzes, Kannada learning, Karnataka discovery |
| Deepavali | `lib/features/deepavali` | Diyas, rangoli, photo frames, decorations, wishes |
| Flappy Bird | `lib/features/flappy_bird` | Flutter mini-game |
| High Pitch / Low Pitch | `lib/features/pitch_game` | Microphone-based pitch game |
| Karnataka AR | `lib/features/ar` | Native ARCore (Android) / ARKit (iOS) experience with Flutter UI |

> **Status:** the shared foundation is done. The four non-AR modules are scaffolds with placeholder screens. The AR module has its Flutter-side contract and a native channel stub, with no ARCore/ARKit yet. See [PROJECT_PROGRESS.md](docs/PROJECT_PROGRESS.md) for the current state of each module.

## Tech stack

- Flutter (stable, 3.47+), Dart 3
- [Riverpod](https://riverpod.dev) for state management and dependency injection
- [go_router](https://pub.dev/packages/go_router) for navigation
- Kotlin and Swift for native AR code only

## Getting started

Requirements: Flutter 3.47 or newer, Android Studio / Android SDK for Android, Xcode on macOS for iOS.

```bash
flutter pub get
flutter run                                   # debug on a connected device or emulator
flutter run --dart-define=APP_ENV=prod        # APP_ENV: dev (default) | staging | prod
```

Application IDs: Android `com.globus.rajotsav_and_diwali_celebration_app`, iOS `com.globus.rajotsavAndDiwaliCelebrationApp`.

## Before opening a pull request

```bash
./scripts/check.sh    # pub get, format check, analyze --fatal-infos, tests
```

CI runs the same script and a debug APK build.

## Project structure

```
lib/
  app/        bootstrap, app shell, router, feature registry   (integration owner)
  core/       theme, tokens, responsive helpers, shared widgets (integration owner)
  features/   one folder per module, each owned by one developer
android/      Android project; native AR code under .../ar/
ios/          iOS project
docs/         architecture, team workflow, decisions, progress
test/         unit, widget, architecture and module-contract tests
```

Each module registers itself with one line in [`lib/app/feature_registry.dart`](lib/app/feature_registry.dart) and keeps its routes under `/<module>`.

## Documentation

- [Architecture](docs/ARCHITECTURE.md): layers, dependency rules, navigation, Flutter-to-native AR interface
- [Team development](docs/TEAM_DEVELOPMENT.md): ownership, branching, PR process, definition of done
- [Decisions](docs/DECISIONS.md): technical decisions and rationale
- [Project progress](docs/PROJECT_PROGRESS.md): module status, verification results, risks
