# Karnataka Rajotsav & Diwali Celebration App

A single Flutter app (Android and iOS) for the Karnataka Rajyotsava and Deepavali festivals. It is built by six people as five modules plus a shared foundation.

## Modules

| Module | Folder | Scope |
|---|---|---|
| Karnataka Rajyotsava | `lib/features/rajyotsava` | Celebration home, quizzes, Kannada learning, Karnataka discovery |
| Deepavali | `lib/features/deepavali` | Diyas, rangoli, photo frames, decorations, wishes |
| Flappy Bird | `lib/features/flappy_bird` | Account-based three-life game, statistics and leaderboard |
| Pac-Man (Diwali edition) | `lib/features/pacman_diwali` | Swipe-controlled Diwali Pac-Man (based on Raj2503/Pacman-Flutter, MIT) |
| AR Game (Habba Hunt) | `lib/features/ar` | Find AR diyas and Kannada flags around the office, under the Games tab. Native ARCore / ARKit with Flutter UI |

> **Status:** the shared foundation is done. Flappy Bird and its reusable score/leaderboard backend are implemented; three schema migrations were deployed to the live Supabase project. Physical-device camera, Google sign-in, and gameplay verification remain. The other non-AR modules remain scaffolds. See [PROJECT_PROGRESS.md](docs/PROJECT_PROGRESS.md) for the current state of each module.

## Tech stack

- Flutter (stable, 3.47+), Dart 3
- [Riverpod](https://riverpod.dev) for state management and dependency injection
- [go_router](https://pub.dev/packages/go_router) for navigation
- Supabase Auth/PostgreSQL for the account-based Flappy Bird module
- Kotlin and Swift for native AR code only

## Getting started

Requirements: Flutter 3.47 or newer, Android Studio / Android SDK for Android, Xcode on macOS for iOS.

```bash
flutter pub get
flutter run --dart-define-from-file=.env       # debug on a connected device or emulator with Supabase & Google Auth
flutter run                                   # runs with built-in development defaults
flutter run --dart-define=APP_ENV=prod        # APP_ENV: dev (default) | staging | prod
```

Application IDs: Android `com.globus.rajotsav_and_diwali_celebration_app`, iOS `com.globussoft.rajotsavAndDiwaliCelebrationApp`.

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

- [Design system rules](docs/DESIGN_SYSTEM.md): **read before building any screen.** All colours, sizes and spacing come from `lib/core/theme/app_tokens.dart`; every screen must fit a 320 pt phone at 2x text on Android and iOS.
- [Architecture](docs/ARCHITECTURE.md): layers, dependency rules, navigation, Flutter-to-native AR interface
- [Shared gaming backend](docs/GAMING_BACKEND.md): Supabase schema, security, RPCs, score delivery, and instructions for adding games
- [Flappy Bird setup](docs/FLAPPY_BIRD_SETUP.md): Google OAuth, environment, and platform configuration
- [Shared gaming backend](docs/GAMING_BACKEND.md): Supabase schema, security, RPCs, score delivery, and adding more games
- [Flappy Bird setup](docs/FLAPPY_BIRD_SETUP.md): Google OAuth, environment, and platform configuration
- [Habba Hunt](docs/HABBA_HUNT.md): the AR Game: setup, builds, tests
- [Team development](docs/TEAM_DEVELOPMENT.md): ownership, branching, PR process, definition of done
- [Decisions](docs/DECISIONS.md): technical decisions and rationale
- [Project progress](docs/PROJECT_PROGRESS.md): module status, verification results, risks
