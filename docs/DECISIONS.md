# Architecture Decisions

## ADR-001 Riverpod for state management and DI — 2026-11-02
- **Context:** Six developers need one consistent, testable approach.
- **Alternatives:** Bloc, Provider, get_it + ChangeNotifier.
- **Reason:** Compile-safe providers, fine-grained rebuilds (`select`), built-in async/dispose handling, override-based test fakes; one tool for both state and DI.
- **Consequences:** Team must learn Riverpod 3 `Notifier` APIs; no codegen used to keep the toolchain small.

## ADR-002 go_router with feature-registered routes — 2026-11-02
- **Context:** Independent features must add routes without editing each other's code.
- **Alternatives:** Navigator 1.0 `onGenerateRoute`, auto_route (codegen).
- **Reason:** Maintained by the Flutter team, supports deep links and declarative back-stack; no codegen.
- **Consequences:** Typed params by convention (path constants + validation) rather than generated routes.

## ADR-003 Feature-first layout, layers inside features — 2026-11-02
- **Context:** Parallel ownership with minimal conflicts.
- **Alternatives:** Layer-first (`data/`, `domain/`, `presentation/` at top).
- **Reason:** One directory per developer; layer rules enforced inside each feature by `architecture_test.dart`.
- **Consequences:** Shared code is limited to `core/` and gated by the integration owner. Domain/data layers are optional per feature.

## ADR-004 No backend, analytics or crash reporting yet — 2026-11-02
- **Context:** No requirement in the repository.
- **Reason:** Avoid unjustified dependencies and startup cost.
- **Consequences:** Errors are logged locally via `installErrorHandlers`; plug a reporter there if adopted.

## ADR-005 Text scale clamped to 1x–2x — 2026-11-02
- **Reason:** Honour accessibility settings while avoiding unusable layouts at extreme scales.
- **Consequences:** Revisit if accessibility review requires more.

## ADR-006 Home screen driven by the feature registry — 2026-11-02
- **Context:** Five modules need entry points without editing the home screen.
- **Reason:** `FeatureModule.entry` supplies each tile; `featureModulesProvider` is overridden in `bootstrap` (not defined in the registry) to avoid an import cycle home ↔ registry.
- **Consequences:** Adding a module is one registry line plus its own directory.

## ADR-007 AR via a platform channel behind a domain interface — 2026-11-02
- **Context:** AR must be native (ARCore/ARKit); Flutter owns the surrounding UI.
- **Alternatives:** Third-party Flutter AR plugins (less control, extra dependencies, uncertain maintenance); Pigeon-generated bindings (extra tooling for a two-day project).
- **Reason:** Hand-written `MethodChannel` with a tiny contract, mapped to a domain enum; failures degrade to `unavailable`. A `PlatformView` is the planned way to show the camera.
- **Consequences:** Contract must be changed in Dart, Kotlin and Swift together. ARCore/ARKit not yet integrated; no ARCore dependency added yet (size).

## ADR-008 No game engine or audio/permission packages yet — 2026-11-02
- **Context:** Flappy Bird and pitch game owners have not chosen tools.
- **Reason:** Avoid unused dependencies. Flappy Bird can be done with a `Ticker` + `CustomPainter`; a package such as Flame is allowed if the owner shows a need. The pitch game needs microphone capture and a permission API: owner proposes packages, integration owner approves.
- **Consequences:** Dependencies are added per-need through reviewed PRs.

## ADR-009 Floating bottom bar with registry-provided tabs — 2026-11-02
- **Context:** Requested navigation: Karnataka Rajyotsava, Deepavali, Games.
- **Reason:** `flutter_floating_bottom_bar` (requested; supports Flutter >=3.44, compatible with our SDK) provides only the floating container, so the tab buttons are our own widgets (48dp targets, selected state, semantics). Tabs are declared by features via `FeatureTab`, so modules stay independent.
- **Consequences:** The AR module has no tab or tile yet; its route `/ar` exists but nothing links to it. Placement is to be decided. Theme-mode toggle UI was removed from the shell (provider remains).

## ADR-010 Flappy Bird uses a single ticker and pure-Dart session model — 2026-11-03
- **Context:** The selected MIT reference used global mutable variables and two periodic timers, which could duplicate loops and score events during life recovery.
- **Alternatives:** Adopt Flame; copy the reference timers; use one Flutter ticker with a pure-Dart model.
- **Reason:** One ticker is sufficient for this small game and keeps physics, collision, lives and scoring deterministic and unit-testable without another game-engine dependency.
- **Consequences:** Rendering uses `CustomPainter`; network and UI work stay outside the game loop. App lifecycle interruption resets the current attempt to a safe ready state without consuming a life.

## ADR-011 Supabase writes statistics only through an idempotent RPC — 2026-11-03
- **Context:** Leaderboard statistics cannot trust arbitrary table updates from the client, and failed submissions must be safely retryable.
- **Reason:** `submit_game_result` derives `auth.uid()`, validates the score envelope, inserts a unique game UUID, and updates aggregates atomically. RLS denies client writes to statistics.
- **Consequences:** The client queues failed results locally. Client-reported scores still need authoritative server gameplay validation for strong anti-cheat guarantees.
