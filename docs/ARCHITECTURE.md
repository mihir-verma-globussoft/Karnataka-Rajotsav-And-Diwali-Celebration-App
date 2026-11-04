# Architecture

Smallest robust foundation: Flutter + Riverpod (state + DI) + go_router, organised by feature.

## Directory structure

```
lib/
  main.dart                 entry point -> bootstrap()
  app/                      INTEGRATION OWNER ONLY
    bootstrap.dart          error handlers, ProviderScope, runApp
    app.dart                MaterialApp.router, themes, text-scale clamp
    providers.dart          app-wide providers (config, logger, theme mode)
    feature_module.dart     FeatureModule contract
    feature_registry.dart   list of all features (one line each)
    router/app_router.dart  GoRouter built from registered features; error page
  core/                     INTEGRATION OWNER ONLY (shared, feature-agnostic)
    config/ errors/ logging/ theme/ responsive/ widgets/
  features/<name>/          one directory per module, owned by one developer
    home/                   app shell: floating bottom bar + tabs (integration owner)
    games/                  Games tab: lists entries with group 'games' (integration owner)
    rajyotsava/ deepavali/ flappy_bird/ pacman_diwali/ ar/   the five festival modules
    <name>_feature.dart     FeatureModule + <Name>Routes (public surface)
    <name>_providers.dart   DI wiring: provider returning the domain type (only when data/ exists)
    domain/                 entities, repository contracts, use cases (pure Dart)
    data/                   repository impls, data sources, DTOs/mappers
    presentation/           pages, widgets, Riverpod notifiers
android/app/src/main/kotlin/.../ar/   native Android AR code (AR developer)
ios/Runner/                 native iOS code (AR developer)
test/                       mirrors lib/; architecture_test.dart enforces rules
integration_test/           on-device smoke tests
```

Create `domain/` and `data/` only when a feature has real business rules or a data source. A simple screen needs just `presentation/`.

## Dependency rules (enforced by `test/architecture_test.dart`)

- `core` imports nothing from `app` or `features`.
- `domain` imports no Flutter, `data` or `presentation`.
- `presentation` never imports `data`; it reads repository/use-case **providers** (domain types).
- `data` implements domain contracts; the wiring lives in `<name>_providers.dart` at the feature root (the only file that sees both `data` and `domain`; see `features/ar/ar_providers.dart`).
- Features may import from `app/` only `feature_module.dart` and `providers.dart`.
- A feature may import another feature only via that feature's `<name>_feature.dart` (e.g. its `Routes` class). Shared needs move to `core` through the integration owner.

## State management and DI

Riverpod only (`flutter_riverpod`, no codegen). Providers are the DI mechanism: a repository provider returns the interface; tests override it with a fake.

- Use `Notifier`/`AsyncNotifier` for screen state; `ref.watch(p.select(...))` to keep rebuilds narrow; `ConsumerWidget` leaf widgets rather than wrapping whole pages.
- Use `autoDispose` for screen-scoped state so it is released on leaving. Keep state local (`StatefulWidget`/hooks-free) when nothing else reads it.
- Render `AsyncValue` with `AsyncValueView` for consistent loading / error / empty / data.
- Obsolete work: `autoDispose` + `ref.onDispose` to cancel; check `ref.mounted` after `await` in notifiers.
- No global mutable singletons. Global state requires integration-owner approval.

## Navigation

- Each feature owns a `<Name>Routes` class of path constants and a `FeatureModule` returning `GoRoute`s. Register it in `feature_registry.dart`.
- Never write route strings outside the owner feature. Navigate with `context.push(OtherRoutes.x)` / `context.go`.
- Parameters: path params for identity (`/event/:id`), validate in the route builder; for missing/invalid values show `ErrorView` (or throw `NotFoundFailure`). Unknown URLs land on `RouteErrorPage`.
- Prefix every top-level path with the feature name to avoid collisions (tested for duplicates).
- Deep links: not configured (no requirement yet). Add platform intent filters/URL schemes when needed; go_router already handles incoming paths.

## Theme and design system

`core/theme`: `AppTheme.light/dark` (Material 3, single seed colour), tokens `AppSpacing`, `AppRadius`, `AppSizes`. Use `Theme.of(context).colorScheme/textTheme`; no hard-coded colours or font sizes. Buttons have 48dp minimum targets. `core/widgets`: `LoadingView`, `EmptyView`, `ErrorView`, `AsyncValueView`. Add a shared widget only when two features need it.

## Responsive UI

- `ConstrainedBody` centres content to 720dp on large screens.
- `WindowSize` (compact/medium/expanded) via `context.windowSize`; prefer `LayoutBuilder` for component-level decisions.
- Scrollable bodies, `SafeArea`, no fixed heights for text containers; `Scaffold` handles keyboard insets. Text scaling is clamped 1x–2x in `App`.
- Test pages at 320x480, 480x320, tablet, and 2x text (see `core_test.dart`).

## Error handling

- Expected failures: sealed `AppFailure` (`NetworkFailure`, `NotFoundFailure`, `UnexpectedFailure`); data layer maps exceptions to these. Messages must be user-safe.
- Unexpected errors: `installErrorHandlers` captures `FlutterError.onError` and `PlatformDispatcher.onError`; `ErrorLoggingObserver` logs provider failures (non-release). Nothing is swallowed. No crash-reporting vendor is wired (see DECISIONS.md).
- Never log secrets/PII.

## Lifecycle and startup

`bootstrap()` initializes Supabase only when build-time credentials are present,
so its persisted authentication session is restored before protected Flappy
Bird screens resolve. Without Supabase configuration, startup remains local and
the rest of the festival app is available. Nonessential work belongs in
providers resolved after `runApp`, shown with loading states. Dispose
controllers/subscriptions in `dispose`/`ref.onDispose`. Configuration uses
`--dart-define` values documented in `FLAPPY_BIRD_SETUP.md`.

## Testing strategy

- Unit: domain, notifiers (with `ProviderContainer` + overrides).
- Widget: pages with `testApp(...)` from `test/helpers.dart`; fake `FeatureModule` for routing.
- Architecture: `test/architecture_test.dart`.
- Integration: `integration_test/` smoke flows (`flutter test integration_test -d <device>`).
- Mock only at boundaries (repositories/data sources); prefer hand-written fakes.

## Performance guidelines

`const` everywhere possible; `ListView.builder`/`GridView.builder` for lists; narrow `select`/leaf `Consumer`s; no work in `build`; `compute`/`Isolate.run` only for genuinely heavy CPU work (parsing large JSON, image processing); `cacheWidth/cacheHeight` (or `ResizeImage`) for images shown smaller than source; keep image assets compressed (WebP/optimised PNG); dispose `AnimationController`s; avoid `Opacity`/`ClipRRect`/blur in frequently repainting areas; add `RepaintBoundary` only after profiling shows a benefit; honour `MediaQuery.disableAnimationsOf`. Validation procedure: see TEAM_DEVELOPMENT.md ("Performance checks").

## Adding a feature

1. `lib/features/<name>/` with `<name>_feature.dart` (`<Name>Routes` + `<Name>Feature implements FeatureModule`).
2. Build presentation (and domain/data if needed) inside it; providers live in the feature.
3. Add one line to `lib/app/feature_registry.dart` (alphabetical).
4. Add tests under `test/features/<name>/`.

## The five modules

| Feature dir | Scope (from the project brief; no earlier requirement docs exist in the repo) | Native code |
|---|---|---|
| `rajyotsava` | Karnataka home/celebration, quizzes, Kannada learning, locations/discovery | none |
| `deepavali` | Diyas, rangoli, photo frames/composition, decorative objects, wishes, light animations | none |
| `flappy_bird` | Flutter game: loop, collision, score, restart/game-over, sound | none |
| `pacman_diwali` | Pac-Man: grid engine in `domain/`, CustomPainter UI | none (pure Dart) |
| `ar` | Karnataka-themed AR (one MVP experience); VR **not** in scope unless confirmed | Kotlin (ARCore), Swift (ARKit) |

Modules started as scaffolds; see PROJECT_PROGRESS.md for their state. Module-specific technical choices (game approach, audio/permission packages, 3D formats) are left to owners and need integration-owner approval if they add a dependency — none has been added.

## Flutter <-> native AR interface

- **Channel:** `MethodChannel('festival_app/ar')`. Dart side: `features/ar/data/method_channel_ar_platform.dart` behind the domain interface `ArPlatform`. Presentation sees only `ArPlatform` / `ArAvailability`.
- **Implemented method:** `checkAvailability` → one of `supported | unsupportedDevice | servicesNeedInstall | cameraPermissionDenied | unavailable`. Anything else, `MissingPluginException` or `PlatformException` is mapped to `unavailable`, so a missing/failed native side never crashes the UI.
- **Implemented:** `ArChannel.kt` / `ArChannel.swift` also answer `prepare` and `openSettings`. The camera is a `PlatformView` with viewType `festival_app/ar_view` and its own channel per view; see `data/method_channel_ar_scene.dart` for the calls and events. Details: [HABBA_HUNT.md](HABBA_HUNT.md).
- **Organisation:** Android code under `.../kotlin/<package>/ar/`; iOS code in `ios/Runner/Ar/` (add the files to the Runner target in Xcode — new Swift files must be registered in the `.xcodeproj`).
- **Capability differences (to confirm by testing):** ARCore requires Google Play Services for AR and a supported-device list, so `servicesNeedInstall` is Android-only; ARKit needs an A9+ device. Look and feel is shared through Flutter UI; AR rendering will differ between ARCore and ARKit. AR and VR are distinct; only AR is scoped.

## Bottom navigation

The shell (`features/home`) uses [`flutter_floating_bottom_bar`](https://pub.dev/packages/flutter_floating_bottom_bar) 3.0.1 for the floating, scroll-aware bar. Tabs come from the registry: a feature returns a `FeatureTab` (order, label, icons, builder). Current tabs: **Rajyotsava** (`temple_hindu`), **Deepavali** (`auto_awesome`), **Games** (`sports_esports`), **Team** (`groups`; developer photos from `assets/team/`, list in `features/team/team_members.dart`). Tab content is built lazily and kept alive after first visit. Tab content is not a route; sub-screens are `/<module>/...` routes pushed above the shell. The Games tab lists features whose `FeatureEntry.group == FeatureGroups.games` (Flappy Bird, Pac-Man). Scrollable tab content should leave about 96dp of bottom padding so the bar never hides the last item.
