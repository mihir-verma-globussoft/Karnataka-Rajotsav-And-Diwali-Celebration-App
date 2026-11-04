# Agent Instructions

Flutter app for Android and iOS. Read [README.md](README.md) and [docs/TEAM_DEVELOPMENT.md](docs/TEAM_DEVELOPMENT.md) before changing code.

## Design rules (strict)

Every UI change must follow [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md):

- Use only tokens from `lib/core/theme/app_tokens.dart` (`AppSpacing`, `AppRadius`, `AppIconSizes`, `AppSizes`, `AppColors`, `AppOpacity`, `AppDurations`) and `Theme.of(context).colorScheme` / `textTheme`. Never hard-code colours, sizes, padding, radii, opacities or durations. If a value is missing, add a named token.
- Every screen must fit a 320 × 568 phone at 2× text in light and dark mode, without overflow. Text wraps or scrolls; nothing has a fixed height that text must fit into.
- It must work on both Android and iOS, including permissions on both platforms and a fallback when a device feature is unavailable.
- Run `./scripts/check.sh` before finishing. `test/design_system_test.dart` and `test/app/layout_safety_test.dart` must pass.
