# Design System Rules

Follow these rules for every screen on **Android and iOS**. They apply to every developer and coding agent working in this repository. Two automated tests enforce them, and `./scripts/check.sh` and CI fail when a rule is broken.

## The golden rule

**One source of truth.** Every colour, spacing, size, radius, opacity, duration and text-size limit is defined once, in [`lib/core/theme/app_tokens.dart`](../lib/core/theme/app_tokens.dart). Screens never hard-code these values. They use a token, or a colour role from `Theme.of(context).colorScheme`.

If the value you need doesn't exist, add a named token to `app_tokens.dart`. Don't write the number in your widget. `lib/core/` belongs to the integration owner, so mention new tokens in your PR.

## Tokens

| Need | Use | Never |
|---|---|---|
| Padding, gaps, margins | `AppSpacing.xs/sm/md/lg/xl/xxl` (4–48) | `EdgeInsets.all(16)`, `SizedBox(height: 12)` |
| Corner radius | `AppRadius.*` and `AppRadius.mdAll` etc. | `BorderRadius.circular(12)` |
| Icon size | `AppIconSizes.xs…hero` | `Icon(…, size: 20)` |
| Component sizes | `AppSizes.*` (touch target, badges, flags, content width, bar clearance) | `width: 56`, `maxWidth: 420` |
| UI colours | `colorScheme.primary`, `.surfaceContainerLow`, `.onSurfaceVariant`… | `Color(0xFF…)`, `Colors.red` |
| Brand / fixed colours | `AppColors.*` (theme seeds, Kannada flag, festive banner) | colours defined inside a feature |
| Transparency | `AppOpacity.*` | `withValues(alpha: 0.2)`, `withOpacity` |
| Animation timing | `AppDurations.*` | `Duration(milliseconds: 200)` in a widget |
| Text styles | `Theme.of(context).textTheme.*` | `TextStyle(fontSize: 18)` |

A module may give its screens their own colour theme by deriving a `ThemeData` from the app theme with a seed from `AppColors`. `RajyotsavaTheme` in `lib/features/rajyotsava/presentation/widgets/` is an example. Custom painters may use named geometry constants local to the painter; their colours and opacities still come from tokens.

## Nothing goes outside the screen

Every screen must fit the **smallest supported phone (320 × 568 pt) at the largest supported text size (2×, `AppTextScale.max`)**, in light and dark mode, with no overflow.

- Never give text a fixed height. Let rows grow with `Column`/`Wrap`, or scroll.
- Long content scrolls: `ListView.builder`, `CustomScrollView` or `SingleChildScrollView`. Don't use a fixed `Column` that only fits on a big phone.
- Rows with text use `Expanded`/`Flexible` for the text so it wraps instead of overflowing.
- Content that fills the screen (like the Games boxes) sets a *minimum* height, never a fixed one, so it scrolls when space runs out.
- Grid tiles with text scale their height with `MediaQuery.textScalerOf(context)`, or use `FittedBox(fit: BoxFit.scaleDown)`.
- Wrap page content in `ConstrainedBody` (max `AppSizes.maxContentWidth`) so it doesn't stretch on tablets.
- Tab content leaves `AppSizes.floatingBarClearance` of bottom padding so the floating bar never hides the last item.
- Respect safe areas (`SafeArea`, or `MediaQuery.paddingOf(context)` for full-screen banners).
- The app caps text scaling at `AppTextScale.max` (2×, Apple asks for at least 200%). Don't clamp further in a screen.

## Platforms: Android and iOS

- Use Material widgets with the app theme; they adapt to both platforms. Use `.adaptive` constructors where they exist (e.g. `CircularProgressIndicator.adaptive`).
- Tap targets are at least `AppSizes.minTouchTarget` (48 pt; Apple's minimum is 44).
- Any permission needs **both** an `Info.plist` usage description (iOS) and an `AndroidManifest.xml` entry (Android), plus a clear screen when it's denied (`PermissionDeniedView`).
- Device features (speech, location, camera) must handle "not available on this device" without crashing.
- Check every UI change on both an iOS simulator and an Android emulator before calling it done.

## Accessibility

- Contrast: at least 4.5:1 for normal text, 3:1 for large text. `colorScheme` pairs (`primary`/`onPrimary`, `primaryContainer`/`onPrimaryContainer`…) already meet this. Text on fixed `AppColors` must too; record the ratio in the token's comment.
- Never use colour alone to show state. Add an icon or text, as the quiz does with ✓ and ✗.
- Give icon-only buttons a `tooltip`, and custom tappable widgets a `Semantics` label.
- Mark section titles with `Semantics(header: true)`.

## Enforced by tests

| Test | What fails it |
|---|---|
| `test/design_system_test.dart` | Hard-coded colours, sizes, padding, radii, opacities or animation durations anywhere in `lib/` outside `lib/core/theme/` |
| `test/app/layout_safety_test.dart` | Any tab or fixed-path screen that overflows at 320 × 568 with 2× text, in light or dark mode |

Module tests should also cover their sub-screens with parameters (e.g. detail pages) at the same size, as `test/features/rajyotsava/` does.

## Checklist before every PR

- [ ] No literal colours, sizes, spacings, radii, opacities or durations in your widgets.
- [ ] `./scripts/check.sh` passes, including both design tests.
- [ ] Checked on an iOS simulator and an Android emulator, in light and dark mode, at large text.
