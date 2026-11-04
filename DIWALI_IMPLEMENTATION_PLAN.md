# Diwali (Deepavali) Celebration — Wireframe & Implementation Plan

Status: **PLAN ONLY. Nothing has been implemented.** Awaiting approval and the decisions in section 2.
Written: 2026-11-03. Target module: `lib/features/deepavali/` (the "Deepavali" bottom-navigation tab).

## Working agreements (added on request)

1. **Ask during implementation.** Anything the agent needs and does not have — images, fonts, audio, Lottie files, copy/content approval, package approval, event date, design choices — is requested from the user **at the moment it is needed**, in the phase that needs it, via a direct question. The agent never invents, downloads, or substitutes assets/content on its own, and never silently skips a feature. Decisions in section 2 are therefore not all required up front; each is asked when its phase begins (Phase 0 becomes "ask as you go" rather than a gate, except D1/D6 which Phase 1–2 need first).
2. **Scope = the existing Diwali tab only.** Everything is built inside the already-existing Deepavali tab (`lib/features/deepavali/`, tab "Deepavali" in the bottom bar). No new tabs, no changes to other tabs or features, no edits to `lib/core/`, `lib/app/` or `lib/features/home/`. The only shared-file edits permitted are `pubspec.yaml` entries (dependencies/assets/fonts) that the user has approved when asked. Full-screen experiences are routes under `/deepavali/...` launched from within the Diwali tab.

3. **Design-system rules (added after commit 9899a7c, `docs/DESIGN_SYSTEM.md`).** No hard-coded colours, sizes, padding, radii, opacities or durations anywhere under `lib/` outside `lib/core/theme/`; they come from `app_tokens.dart`. The Deepavali palette therefore lives in `AppColors.diwali*` (and new `AppOpacity` tokens) in `app_tokens.dart`, and `DiwaliPalette` only aliases them. This supersedes the "nothing in `core` changes" statement in 3.2: token additions in `app_tokens.dart` are the sanctioned route and are mentioned in the PR. Every screen must also fit 320×568 at 2× text in light and dark (`test/app/layout_safety_test.dart`).
4. **Phase 1 status (done, `./scripts/check.sh` green).** Spike result: `IndexedStack` does **not** stop tickers in hidden tabs, so the user approved a one-line change in `home_page.dart` wrapping each tab in `TickerMode(enabled: i == index)`. Fonts: user chose Poppins via `google_fonts` ^6.3.3 (9.x does not compile on Flutter 3.47.9), with weights 400/500/600/700 bundled in `assets/google_fonts/` and runtime fetching disabled so the tab works offline.
5. **Phase 2 status (done, `./scripts/check.sh` green).** Event date confirmed: Lakshmi Puja Sunday 8 Nov 2026 (IST), five days 6–10 Nov. `shared_preferences` approved and used for the intro-seen flag. Shared files touched: `app_tokens.dart` (`AppDurations.slow`), `test/helpers.dart` + `module_contract_test.dart` + `layout_safety_test.dart` (tests now request reduced motion via `reduceMotionForAllTests()` because animated tabs never "settle" under `pumpAndSettle`). Not built: tapping the hero diya to flare (optional).
6. **Content authority (user decision).** The agent has full liberty to write the explorer, destination, quiz and other content; no review gate from the user. D11 is therefore resolved: the agent writes accurate, concise, region-aware copy and flags uncertain facts itself.
7. **Device testing.** A physical Android device is connected (`flutter run -d e3f149c9`); phases are verified on it with `adb` screenshots in addition to `./scripts/check.sh`.
8. **Phase 3 status (done).** Six explorer cards + bottom sheets. Device testing found that `IntrinsicHeight`/`Table` mis-measured the wrapped card title (overflow by 24px) because text metrics change when Poppins finishes loading, so tiles use a fixed height computed from the text scale (as `docs/DESIGN_SYSTEM.md` recommends for grid tiles).
9. **Phase 4 status (done, verified on device).** Six-city swipeable gallery + `/deepavali/destination/:id` detail route + photo credits sheet. Photos are freely licensed Wikimedia Commons images chosen on request to show Diwali in each city (Ram Mandir for Ayodhya): Varanasi diyas swastik (CC BY-SA 4.0), Jaipur street lights (CC BY 2.0), Ayodhya Ram Mandir (CC BY 3.0), Amritsar Golden Temple with lamps (CC BY-SA 4.0), Kolkata Om of diyas (CC BY-SA 4.0), Mumbai lanterns (CC BY-SA 4.0) bundled in `assets/deepavali/images/destinations/` with attribution in `assets/deepavali/CREDITS.md` and in the app. Every fact carries a source checked against Wikipedia. Decorative India map was not built (optional, D3).

Document order: (1) repository findings, (2) decisions needed, (3) UI wireframe & specification, (4) architecture, (5) phased plan, (6) execution sequence & checklist.

Naming: the repo, tab label and folder use **Deepavali**; the brief says **Diwali**. This plan keeps the folder/route names (`deepavali`) and uses "Diwali" in user-facing copy only if approved (Decision D13).

---
10. **Phase 5 status (done, verified on device).** Light the Diyas: pure-Dart state machine (`domain/diya_game.dart`), monotonic-clock notifier that only counts while playing and auto-pauses when the tab is hidden or the app is backgrounded, 12-diya board, pause/restart, win burst (static check under reduced motion), time-up screen, best time in `shared_preferences`, and a relaxed (no-timer) mode that does not record best times. Share-card button deferred to Phase 8.
    **Difficulty rework (on request: too easy).** Win now means all 12 lit at once. Three levels: Gentle (the original, no wind), Breezy (20 s, first gust at 2.5 s then every ~0.8 s, tightening to 0.6 s) and Stormy (16 s, first gust at 1.5 s then every ~0.55 s, tightening to 0.42 s). Wind blows out one lit diya per gust; the target shakes (and shows a wind icon, so it never relies on motion alone) 0.5 s / 0.38 s beforehand and tapping it shields it. Gust targets come from a seeded generator, so the pure state machine stays deterministic and testable. Best times are kept per level (Gentle keeps the original key). Relaxed mode now means no timer and no wind.
11. **Phase 6 status (done, verified on device).** Quiz: 23 reviewed questions across five categories (folklore phrased as tradition), 10 drawn per run with seeded shuffling of questions and options, locked answers with instant feedback and explanation, results with tier title and a review of misses, quit confirmation, best score in `shared_preferences`, burst for 8+ (trophy only under reduced motion).
12. **Phase 7 status (done except sharing, verified on device).** Rangoli Studio: circular canvas of a centre disc plus four rings of eight sectors (33 shapes) with O(1) polar hit-testing in pure Dart, quarter-turn symmetry (tap colours four matching shapes, centre is single), 8 festival colours + eraser (new `AppColors.rangoli*` tokens), Random (seeded, symmetrical), Undo (50 deep), Reset (confirms when dirty, undoable), and a per-shape semantics tree for screen readers. PNG capture (`RepaintBoundary` at 3x on an opaque background) and an `ImageSharer` interface exist and are tested with a fake; Not built: tap-fill animation (instant), 16-sector/mirror variant. Sharing was completed after approval of `share_plus` (see item 13).
13. **Phase 8 status (done in tests and on a debug build; share sheet not yet seen on the phone).** `share_plus` ^13.3.1 approved and added (no `path_provider`: the PNG goes to the system temp folder, cleared on the next share rather than straight after, since the receiving app may still be reading it; iPad gets a share-sheet anchor). No gallery package: both OS share sheets offer Save, so no storage permission is requested. Greeting Card: four vector designs (Golden Diyas, Rangoli Border, Night Sky Lanterns, Marigold Garland), 4:5 card that scales any message down to fit and ignores the phone's text size (it is a picture), 4 preset wishes, message up to 120 and sender name up to 30 characters (counted as code points so emoji and Indian-script letters are never split), keyboard-safe customise sheet, contrast of every design's text checked at 4.5:1, Share card and Share image through one capture/share helper with Retry on failure and silence when the share sheet is dismissed.
\n14. **Phase 9 status (core done, verified on device).** More to Explore: (a) Virtual Diya Wall: wish up to 80 characters plus optional name up to 30, newest first, 50 kept, saved on the device in `shared_preferences` as one JSON list (damaged data reads as empty, bad entries skipped, stored text re-tidied on read), starts empty with "Light the first diya" (no fake sample wishes), a failed save keeps the diya for the session and says so, remove-a-wish, "View all" sheet, and copy that says it is saved on this phone only. (b) Guess the object: eight vector silhouettes (diya, rangoli, lantern, laddu, sparkler, marigold garland, puja thali, firework rocket) that reveal in colour with a one-line fact, reusing the quiz session logic (seeded distractors, locked answers, tiers). (c) Five-day timeline: horizontal stepper with today's step glowing (static under reduced motion), tap a day for its story. Placeholder section code removed because every section is real. Optional extras (home decoration, photo booth, recommendations) deliberately not started: they need approval first.
\n15. **Optional extras (built on request; user agreed to provide permissions).** (a) *Which city is for you?*: four questions, pure scoring with a brute-force test that every one of the six cities can win, a result card with the city photo, the answers that pointed to it and a link to its detail page. (b) *Decorate your home*: full-screen `/deepavali/decorate`; five decorations (diya, rangoli, lantern, garland, sparkler) added from a palette, dragged into place (or moved with arrow buttons for anyone who cannot drag), max 40, Clear confirms, Share image; the selection ring is drawn outside the captured picture. (c) *Photo booth*: full-screen `/deepavali/photo-booth`; `image_picker` ^1.2.4 (system camera or gallery; photo kept in memory only, scaled to 1600 px, never uploaded), four frames (Diyas, Lanterns, Rangoli, Garland) plus a Happy Deepavali banner, Share photo. Permissions: iOS `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` added to `Info.plist`; Android needs none (the system camera app takes the picture). Fallbacks: camera access denied or no camera shows a clear message and the gallery still works. Verified on device: camera, framed photo, share sheet for the decorated house.
\n16. **Portrait lock and UI polish.** The whole app is now portrait only (requested): `android:screenOrientation="portrait"` on the activity, iOS `UISupportedInterfaceOrientations` (phone and iPad) limited to portrait with `UIRequiresFullScreen` (required for iPad when not all orientations are supported), and `lockToPortrait()` in `bootstrap.dart` as a third guard; verified on device that a forced landscape request leaves the app upright. UI fixes from a review on the phone at 1x and 1.6x text: rangoli shapes are now visible before they are coloured (lighter fill, gold outline); greeting-card backgrounds are lighter so the card stands out, an ornament separates title and message, and the four design thumbnails always sit in one row with the chosen design's name beneath; the timeline stepper has a round "more days" button (also tappable) when days are off to the right, its steps widen with the text size (measured on body text because Android scales large sizes less) so day names wrap between words; the decorate and photo booth backgrounds fill the screen when content is short. An accessibility bug found by a test: the timeline's "more" button was merged into the stepper's group label; it is now its own control.
\n17. **Phase 10 status (done, verified on device with the real audio).** One mute / unmute button at the top right that controls **only the background song** (shown only when a song file is bundled; the choice is remembered). The six sound effects always play, muted or not (fixed on request after the mute button was silencing them too; verified on device: song silent, 4 of 4 effect taps still played). On request the settings sheet was removed, vibration is always on (the phone's own touch-feedback setting decides whether it is felt), and animations simply follow the phone's reduce-motion setting. The song defaults to **on**. Audio: `music.mp3` is the supplied "Happy Diwali" song (re-encoded from the 320 kbps original to 80 kbps MP3, 7.7 MB → 1.9 MB, loudness unchanged, 1.5 s fade-in and 2 s fade-out so it loops cleanly; the six effects are mono 96 kbps MP3s totalling 66 KB, so the whole Deepavali audio folder is about 2.0 MB), looping at 45% volume, playing only while the Deepavali tab is on screen and the app is in front; six short effects are free CC0 sounds (Kenney Interface Sounds, Fupi's Win Jingle, remaxim's short wind sound) trimmed and levelled to a matching loudness: `tap`, `diya_light`, `correct`, `wrong`, `win`, `gust`, used by the diya game, quiz, guessing game, rangoli, decorate, greeting card and diya wall. Sources and licences: `assets/deepavali/audio/CREDITS.md`. **Open item: the song's tags name T-Series, so the team must confirm it may distribute that recording.** Audio setup matches the Rajyotsava tab (iPhone follows the silent switch, Android mixes with the person's own music); verified on the phone that exactly one tab's song plays at a time (Deepavali session only on its tab, Rajyotsava session only on its tab, silence on Games, Team and in the background, and the song resumes on return), that 10 rounds of rapid mute/unmute always end in the state the button shows (play and pause commands now run in order, latest wish wins, with one retry if a resume does not take), and that effects start. Sections fade and slide in the first time they scroll into view (nothing hidden when animations are off).
18. **Credits footer removed (on request, after phase 11).** The page no longer ends with a credits section: the "Credits & licences" sheet, the open-source licences button and the note under them are gone (section 3.13 is therefore not built). Credits are still kept in the repo (`assets/deepavali/audio/CREDITS.md`, `assets/deepavali/CREDITS.md`) and the Photo credits sheet in the cities gallery stays. A test still checks that every audio file is listed in its `CREDITS.md` and every photo belongs to a destination. Also fixed while there: unrevealed sections now start a fixed 24 px below their place instead of 4% of their own height (the tall More to Explore section used to slide about 90 px).
19. **Firecrackers in the hero (on request).** The top of the Deepavali page now has fireworks: five rockets that climb and burst into multicoloured sparks with a glow flash, staggered every 3 to 4 seconds in the open sky around the diyas, plus two fountains of sparks at the bottom corners. They start as the side diyas light up during the intro. One painter on the shared animation clock, in its own repaint layer, at most about 150 shapes a frame; with reduced motion, or while the hero is scrolled away or the tab is hidden, it shows a still frame of the same bursts. Decorative, hidden from screen readers. Looked at on the phone; **not profiled**: the profile-mode trace that would show the extra GPU cost on this phone was not completed, and the hero was already the heaviest part of the page to draw.

## 1. Repository findings (verified by reading the code)

### 1.1 What exists
| Area | Finding | Source |
|---|---|---|
| Framework | Flutter 3.47.9 installed, Dart `^3.13.7`, `flutter: >=3.47.0` | `pubspec.yaml`, `flutter --version` |
| Dependencies | Only `flutter_riverpod ^3.4.3`, `go_router ^18.1.2`, `flutter_floating_bottom_bar ^3.0.1`, `cupertino_icons`. **No** animation, audio, share, storage, font or image packages. | `pubspec.yaml` |
| Assets | Only `assets/team/` (6 JPGs). **No Diwali imagery, fonts, audio or Lottie files exist.** `pubspec.yaml` declares only `assets/team/`. | `pubspec.yaml`, `git ls-files` |
| Diwali module today | A scaffold: `deepavali_feature.dart` (tab order 1, label "Deepavali", `Icons.auto_awesome(_outlined)`, `entry: null`, `routes: const []`) and `presentation/deepavali_page.dart` (AppBar + `EmptyView` "Not implemented yet."). No tests, no providers, no domain. | `lib/features/deepavali/` |
| Registration | `DeepavaliFeature()` already in `lib/app/feature_registry.dart`. No registry edit needed. | `feature_registry.dart` |
| Shell / bottom nav | `HomePage` uses `flutter_floating_bottom_bar` `BottomBar` (adaptive, max width 420) over an `IndexedStack`. Tabs are built lazily on first visit, then **kept alive**. Bar is a floating rounded container (radius 28) — content must leave bottom clearance. | `features/home/presentation/home_page.dart` |
| Clearance convention | Games tab pads the bottom by `AppSpacing.xl * 3` (96dp) so the last item clears the bar. | `games_page.dart` |
| Theme | Single seed `Color(0xFFE65100)` (deep orange), Material 3, light + dark, 48dp min touch targets. "Never hard-code colours in features." | `core/theme/app_theme.dart` |
| Tokens | `AppSpacing` xs4/sm8/md16/lg24/xl32; `AppRadius` sm8/md12/lg20; `AppSizes.minTouchTarget=48`, `maxContentWidth=720`. | `core/theme/app_tokens.dart` |
| Responsive | `WindowSize` (compact <600, medium <840, expanded), `ConstrainedBody`. | `core/responsive/breakpoints.dart` |
| Shared widgets | `LoadingView`, `EmptyView`, `ErrorView(onRetry)`, `AsyncValueView`, `PermissionDeniedView`. | `core/widgets/` |
| Text scale | Clamped to 1x–2x globally. System bar icon brightness set globally from theme brightness (ADR-005, `app.dart`). | `app/app.dart` |
| Config | `AppConfig` from `--dart-define` (APP_ENV). No event-date config exists. | `core/config/app_config.dart` |
| Backend | **None.** ADR-004: no backend, analytics or crash reporting. ADR-008: no game engine / audio packages yet. | `docs/DECISIONS.md` |
| Lint | `strict-casts/inference/raw-types`; `prefer_const_constructors`, `unawaited_futures`, `cancel_subscriptions`, `directives_ordering`, etc. `flutter analyze --fatal-infos`. | `analysis_options.yaml` |
| Quality gate | `./scripts/check.sh` = pub get, `dart format --set-exit-if-changed lib test integration_test`, analyze, test. CI also builds a debug APK. | `scripts/check.sh`, `.github/workflows/ci.yml` |
| Architecture tests | `test/architecture_test.dart` enforces: core imports no app/features; `domain/` has no Flutter/data/presentation imports; `presentation/` never imports `data/`; features import other features only via `<name>_feature.dart`; features import only `app/feature_module.dart` and `app/providers.dart`. | `test/architecture_test.dart` |
| Contract test | `test/app/module_contract_test.dart` checks each registered module (prefix, tab, opens/back). | `test/app/` |
| Perf tooling | `integration_test/perf_test.dart` + `test_driver/perf_driver.dart` (profile-mode frame timings; target p99 < 16 ms). | `docs/TEAM_DEVELOPMENT.md` §9 |

### 1.2 Ownership rules that constrain this plan (`docs/TEAM_DEVELOPMENT.md`)
- Edit **only** `lib/features/deepavali/` and `test/features/deepavali/`.
- Allowed shared edits: one line in `feature_registry.dart` (already present) and **`pubspec.yaml` dependencies only after the integration owner approves each package**.
- `lib/core/` and `lib/app/` are integration-owner files. The Diwali look must therefore live **inside the feature** (a feature-local `Theme`), not by editing `AppTheme` or `core`.
- `pubspec.yaml` `flutter: assets:` / `fonts:` entries and native manifests (`Info.plist`, `AndroidManifest.xml`) are shared files → integration-owner review.
- Do not touch Rajyotsava, Games, Flappy Bird, Pitch, AR, Team, Home.

### 1.3 Consequences for design
1. **IndexedStack keeps the tab alive.** After the first visit, the Diwali page stays mounted while hidden. `Offstage` disables tickers (animations stop), but `Timer`/`Stream` work does **not** stop. Countdown and game timers must pause when the tab is not visible. The page has no built-in "tab is visible" signal; Phase 1 must derive one (see 4.4). *Prerequisite spike: confirm ticker behaviour on a device.*
2. **No AppBar.** The existing scaffold uses an `AppBar`; the immersive hero needs full-bleed art under the status bar, so the page uses a bare `Scaffold` with its own background.
3. **Light/dark.** The festive identity is dark-first. The tab renders its own fixed festive palette in both system modes (Decision D6). The floating bottom bar belongs to the shell and stays system-themed; a light-mode bar against a dark page is an accepted visual seam unless the integration owner wants otherwise.
4. **Status-bar icons** are set globally from theme brightness. In system light mode the icons would be dark on a dark hero → the page must wrap itself in its own `AnnotatedRegion<SystemUiOverlayStyle>` (light icons). It reverts when the user changes tab. Verify on device.
5. **Offline-first** is easy: no backend exists and none is needed. All content ships in the app.
6. **Full-screen experiences** are routes under `/deepavali/...`. Pushing a route from the tab covers the shell, so the floating bar is hidden there (same as Games' children).

---

## 2. Decisions needed from you (the plan does not guess these)

| # | Decision | Why it matters | Recommended default |
|---|---|---|---|
| D1 | **Event date.** Which date is "Diwali Day" for the countdown? Lakshmi Puja date for 2026 is expected to be **Sunday 8 Nov 2026**, but the date varies by panchang and region (Karnataka often marks Naraka Chaturdashi, 7 Nov, as the main day). Today is 3 Nov 2026, so the festival is days away. | Countdown, five-day timeline, "celebration status". | Single constant `kDiwaliLakshmiPujaDate` plus the 5 derived days, easy to edit. **You confirm the date and time zone (IST).** |
| D2 | **Approved images.** Do you have licensed/own photos for Varanasi, Jaipur, Ayodhya, Amritsar, Kolkata, Mumbai (and hero art)? | No Diwali images exist in the repo. Wikimedia Commons CC-BY/CC0 is an option but requires attribution and per-image licence checks. | You supply images; fallback is Commons with a Credits screen. Until supplied, Phase 4 uses clearly-marked placeholders (see risk). |
| D3 | **Scope of optional advanced features:** festive home-decoration, photo booth, personalised destination recommendations, interactive map. | Each is multi-day work and some need camera/permissions. | **Out of scope for core delivery.** Timeline, diya wall, guess-the-object are in scope. Others only after Phase 11 sign-off. |
| D4 | **Packages** (integration-owner approval required). See 4.6. Recommended: `shared_preferences`, `share_plus`, `path_provider`. Optional: `gal`, `audioplayers`, `lottie`. | Every package adds weight and native config. | Approve the three core ones; decide the optional ones per D5/D7/D8. |
| D5 | **Save-to-gallery** for rangoli/cards, or share sheet only? | `gal` adds native permission config (iOS `NSPhotoLibraryAddUsageDescription`). | Share sheet only (covers "save" via the OS UI). Add `gal` only if you want an explicit "Save" button. |
| D6 | **Always-dark festive theme** regardless of system mode? | Deviates from the "works in light and dark" definition of done (which is satisfied here only because the tab is theme-independent). | Yes, always dark festive. |
| D7 | **Sound effects:** in scope at all? Do you have licensed audio? | Needs `audioplayers`/`just_audio` (heavy), asset licensing, interruption handling. | Defer. Ship haptics (built into Flutter) + a settings toggle; add audio only with approved audio files. |
| D8 | **Lottie:** allow? | Needs licensed Lottie JSON. | Not required; build diya/flame/particles with `CustomPainter`. Optionally one celebratory Lottie later. |
| D9 | **Fonts:** approve bundling an OFL display font (and Noto Sans Devanagari/Kannada if system rendering is poor). | `google_fonts` would fetch at runtime → breaks offline; bundling is shared `pubspec.yaml` + asset size. | Bundle one display serif + system body font. Candidates (verify licence at selection): Cinzel, Playfair Display, Yatra One. |
| D10 | **Persistence of user data** (wishes, sound/motion prefs, "intro seen", best scores) across launches? | Needs `shared_preferences`. | Yes, small key-value only. |
| D11 | **Content review.** Who verifies cultural/regional facts and quiz answers? | Plan requires accuracy and regional-difference notes. | A named reviewer signs off Phase 3, 4, 6 content. |
| D12 | **Languages.** English only, or English + Kannada/Hindi greetings? | Greeting card text, hero greeting. | English UI; hero/cards include "Shubh Deepavali" + Kannada "ದೀಪಾವಳಿಯ ಶುಭಾಶಯಗಳು" + Hindi "शुभ दीपावली" as display text only (verify rendering on device). |
| D13 | **Spelling** in UI copy: "Diwali" vs "Deepavali". | Consistency with Rajyotsava/Kannada audience. | "Deepavali" in headings (matches tab), "Diwali" acceptable in body copy. |
| D14 | **Minimum supported OS/devices** for performance targets. | Particle counts and painter cost are tuned to the low end. | A mid-range Android device as the profile baseline. |

---

## 3. UI wireframe & specification

### 3.1 Screen composition (whole tab, one vertical scroll)

The tab is a single `Scaffold` (no AppBar) containing a vertical scroll. Order, top to bottom:

```
┌─ status bar (light icons) ──────────┐
│ [0] Top utility row (overlaid hero) │  sound / motion toggles
│ [1] FESTIVE HERO                    │  ~ 70% of viewport height
│ [2] CELEBRATION COUNTDOWN           │
│ [3] DIWALI EXPLORER                 │  card grid
│ [4] DIWALI AROUND INDIA             │  horizontal gallery
│ [5] LIGHT THE DIYAS                 │  inline game
│ [6] DIWALI QUIZ                     │  inline quiz
│ [7] RANGOLI STUDIO                  │  inline canvas
│ [8] GREETING CARD GENERATOR         │  preview + controls
│ [9] MORE TO EXPLORE                 │  diya wall, guess game, timeline, (optional)
│ [10] Footer: credits / about        │
│      bottom clearance ≥ 96dp + inset│  clears floating bar
└─────────────────────────────────────┘
        [ floating bottom bar ]   ← owned by Home shell
```

**Layer map — what is where**
| Kind | Items |
|---|---|
| Main scrolling screen | Sections 0–10 above |
| Bottom sheets | Explorer card details, five-day detail, greeting customise, quiz explanation (if not inline), settings (sound/motion), wish composer, credits |
| Dialogs | Confirm restart game/quiz, confirm reset rangoli (only if non-empty), permission/share error |
| Full-screen routes (hide bottom bar) | `/deepavali/destination/:id` (destination detail); optional: `/deepavali/rangoli` (expanded studio), `/deepavali/photo-booth`, `/deepavali/decorate` (optional features only) |

**Scroll implementation:** `SingleChildScrollView` + `Column` (not slivers), so `Scrollable.ensureVisible` works for every section key (the hero CTA needs this). Cost control comes from (a) each section wrapped in `RepaintBoundary`, (b) heavy interactive sections (game, quiz, rangoli, card) render a lightweight **poster** until the user taps "Start"/"Create", so no painters or tickers run until needed, (c) the destination gallery uses `ListView.builder`.

**Width:** content in `ConstrainedBody(maxWidth: 720)`; hero background is full-bleed. Side gutter `AppSpacing.md` (16). Section vertical gap `AppSpacing.xl` (32); inside a section `AppSpacing.md`.

### 3.2 Design system (feature-local; nothing in `core` changes)

**Palette** (fixed, dark-first; names are tokens in `diwali_palette.dart`; values to be validated by a contrast test)

| Token | Hex | Use |
|---|---|---|
| `night` | `#14081F` | page background (deepest) |
| `plum` | `#2A1240` | background gradient mid |
| `maroon` | `#4A1424` | gradient warm end, card tint |
| `surface` | `#231238` | card base |
| `surfaceHigh` | `#2F1A4A` | raised card / sheet |
| `gold` | `#F5B83D` | primary accent, CTA fill, borders |
| `goldDeep` | `#C98A12` | pressed state, dividers |
| `saffron` | `#FF9933` | secondary accent |
| `orange` | `#F26A1B` | flame outer, highlights |
| `flameCore` | `#FFD36B` | flame inner, glow |
| `cream` | `#FFF4DC` | primary text |
| `creamMuted` | `#D9C7A8` | secondary text |
| `success` | `#7BD88F` | correct answer |
| `error` | `#FF8A80` | wrong answer / errors |

Rules: text `cream` on `night/surface` and `night` text on `gold` fills (both expected ≥ 7:1 — verify in a test). Colour is never the only signal (correct/wrong also use icon + label). Rangoli palette colours are content, exempt from the token rule but each must have a semantic label.

**Gradients:** page = linear `night → plum → maroon` (top→bottom, subtle); hero = radial warm glow centred on the diya (`flameCore @ 35% → transparent`) over `night→plum`; card = `surface → surfaceHigh` with 1dp `gold @ 30%` border; CTA = `gold → saffron` horizontal.

**Typography** (display font bundled per D9; body = platform font)
| Role | Style |
|---|---|
| Display (hero greeting) | display serif, 40/44 compact, 56/60 on medium+, `cream`, gold glow shadow |
| Section title | display serif 28/34, `gold` |
| Card title | body bold 18/24, `cream` |
| Body | 16/24, `creamMuted` or `cream` |
| Caption / chips | 13/18, `creamMuted` |
| Button | 16/20 bold |
All scale with the system text scale (app clamps 1–2x). No fixed-height text containers.

**Cards:** radius `AppRadius.lg` (20), padding 16, `surface` gradient, gold hairline border, soft warm shadow (`orange @ 12%`, blur 24) — shadow only on raised cards, not on scrolling-heavy lists (cost).
**Buttons:** Primary = gold gradient pill, 48dp min, `night` text, optional leading icon. Secondary = outlined gold. Tertiary = text `saffron`. All have focus/pressed states, ≥ 48dp target, `Semantics(button: true)`.
**Decorative elements:** string-light garland (top of hero), marigold-flower border motif (section dividers), paisley/mandala corner ornaments (low-opacity `CustomPainter`s), sparkle stars. All painters are `const`-style, cached via `RepaintBoundary`, and marked `ExcludeSemantics`.
**Section header:** gold ornament divider → title → one-line subtitle, `Semantics(header: true)`.
**Spacing/tokens:** reuse `AppSpacing`, `AppRadius`, `AppSizes` from core (read-only); feature adds only what core lacks (palette, gradients, shadows).

**Interaction patterns:** tap = primary; long-press not required anywhere; no drag-to-paint (conflicts with vertical scroll); horizontal gallery is the only horizontal scroller; bottom sheets for detail (drag handle, swipe to dismiss, 640 max width); haptics via `HapticFeedback.selectionClick/lightImpact` on meaningful taps only, gated by the setting; every animated state has a non-animated equivalent.

**Global states:** content is static, so **no network loading/error states** for Explorer/Destinations/Quiz. Loading appears only for (a) asset image decode (shimmer-free placeholder: gradient + icon), (b) reading saved prefs (first frame uses defaults, no spinner), (c) image export (inline progress on the button). Errors: image asset missing → gradient + name placeholder; export/share failure → `SnackBar` with Retry.

**Accessibility baseline (all sections):** 48dp targets; semantics labels on every interactive/illustrative element, decorative art excluded; logical focus order top→bottom; headings marked; text scales to 2x without clipping (cards grow); contrast per palette; no information by colour alone; **reduced motion**: `MediaQuery.disableAnimationsOf(context)` → static diya with fixed glow, no particles, no confetti, instant transitions; live regions (`SemanticsService.announce` / `Semantics(liveRegion: true)`) for game progress, quiz feedback, countdown changes (not every second).

**Responsive baseline:** compact (<600): 1-column cards, gallery card 78% width. Medium (600–840): Explorer 2 columns, gallery card 46%. Expanded: content capped at 720, centred; hero art scales but text stays in the capped column. Landscape phone: hero height `max(320, 0.9*height)` scrolls normally; game grid recomputes columns by width. Verified at 320dp, 360dp, 411dp, 600dp, 840dp, landscape, text 1x/1.5x/2x.

### 3.3 Section 0 — Top utility row (overlay on hero)

```
┌───────────────────────────────────┐
│                      [♪off] [✦ on]│  48dp icon buttons, top-right, below status bar
└───────────────────────────────────┘
```
- Hierarchy: `Positioned(top: safeTop+8, right: 8) Row[SoundToggle, MotionToggle]` → opens Settings sheet on long form, or toggles directly.
- Behaviour: Sound toggle (default **off**), Motion toggle ("Animations: system / on / off"; "system" follows OS reduce-motion). Persisted (D10). Haptics toggle lives in the sheet.
- Semantics: "Sound effects, off. Double tap to turn on." State announced.
- States: sound control hidden entirely if audio is not in scope (D7).

### 3.4 Section 1 — Festive Hero

```
┌─────────────────────────────────────┐
│ ·  ✦    ·     ✧   ·   ✦    ·   ✧   │  floating particles (embers/sparkles)
│ o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o │  string-light garland (twinkle)
│                                     │
│            ( glow halo )            │
│              \  |  /                │
│               \ | /                 │  hero diya: clay lamp + animated flame
│            ____\|/____              │
│           (___________)             │
│    ( )                    ( )       │  smaller side diyas (parallax-lite)
│                                     │
│        Shubh Deepavali              │  display, gold glow
│   ದೀಪಾವಳಿಯ ಶುಭಾಶಯಗಳು · शुभ दीपावली   │  subtitle line
│  May light fill your home and heart │
│                                     │
│     [ ✦ Begin the celebration ]     │  primary CTA
│        ‹ Replay ›   ‹ Skip ›        │  tertiary (only during intro)
│               ⌄                     │  scroll hint (bobbing)
└─────────────────────────────────────┘
```
- **Hierarchy:** `HeroSection` → `Stack[ GlowBackground (gradient+radial), StarField/ParticleField (CustomPainter), Garland (CustomPainter), SideDiyas, HeroDiya (DiyaPainter + FlameWidget), HeroText column, CTA, ScrollHint ]` wrapped in `RepaintBoundary`s (static background / animated layers separate).
- **Content:** greeting lines above (D12/D13), tagline, CTA label "Begin the celebration".
- **Imagery:** all vector/painter-drawn (no raster needed): diya bowl (clay gradient), wick, flame (3 layered teardrops: orange outer, saffron mid, `flameCore` inner), glow halo (radial gradient). Zero asset weight.
- **Interactions:** CTA → `Scrollable.ensureVisible(explorerKey)` 700ms `easeInOutCubic`. Tap the hero diya → flame flares + haptic (delight, optional). **Intro animation** (≈2.5 s): background fades in, diyas ignite one by one centre→sides, text rises/fades, particles begin. **Skip** jumps to final state instantly; **Replay** (small button, appears after intro) re-runs. "Seen" flag persisted (D10): on later visits, hero renders directly in final state with only the idle loop. Intro never replays on tab re-selection (state kept alive by IndexedStack and the flag).
- **Animation:** flame = flicker via one `AnimationController` (repeat, ~1.4 s) with noise-modulated scale/skew, glow pulse sin-based; particles = ~24 (compact)/40 (larger) simple dots, single `CustomPainter` repainting off one ticker (no widget per particle); garland twinkle shares the ticker; scroll hint bob. All idle loops **stop** when hero is scrolled out of view (`VisibilityDetector`-free approach: track scroll offset via `ScrollController` listener; pause when `offset > heroHeight`) and when the tab is hidden.
- **States:** default (animated); reduced-motion (static diya, steady glow, no particles/garland twinkle, CTA unchanged); low-end fallback (halve particles via `ParticleBudget`).
- **Responsive:** hero min-height `clamp(480, 0.7*viewportHeight, 760)`; diya width = `min(0.55*width, 280)`; side diyas hidden below 340dp width; text wraps, centred.
- **Accessibility:** one semantic node for the scene: label "Decorative lit diyas" (excluded from tab order); greeting is a heading; CTA labelled "Begin the celebration, scrolls to Explore Diwali"; Skip/Replay are real buttons; no flashing >3/sec (flicker is smooth, not strobing).

### 3.5 Section 2 — Celebration Countdown / Status

```
┌─────────────────────────────────────┐
│  Diwali · Sunday, 8 November 2026   │  (date from D1 constant)
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐         │
│ │ 04 │ │ 12 │ │ 37 │ │ 21 │         │  days / hrs / min / sec
│ │days│ │hrs │ │min │ │sec │         │
│ └────┘ └────┘ └────┘ └────┘         │
│  Next: Dhanteras · Fri 6 Nov        │  next milestone line
└─────────────────────────────────────┘
```
- **Hierarchy:** `CountdownSection` → `DiwaliCard` → date header, `Row` of 4 `FlipDigitCard`s (plain `AnimatedSwitcher`, no package), milestone line.
- **Status logic** (pure Dart, `domain/festival_status.dart`, takes `now` as parameter): `before` (> 5 days: countdown + "N days to go"), `festivalWeek` (inside the five-day window: shows current day name e.g. "Today is Naraka Chaturdashi" + countdown to Lakshmi Puja), `diwaliDay` (Lakshmi Puja date: "Happy Deepavali! Today is the day", no countdown, subtle shimmer), `after` ("Deepavali has passed — see you next year", next-year date unknown → no fabricated date; shows "Relive the celebration" links to Explorer/Quiz).
- **Interactions:** tap card → opens **five-day timeline bottom sheet** (same content as Section 9 timeline). Seconds tick only while visible and tab active.
- **Animation:** digit change cross-fade/slide 250ms (instant in reduced motion); `diwaliDay` state: gentle gold shimmer.
- **States:** countdown correct at boundaries (midnight, DST-less IST); device clock changes handled by recomputing from `DateTime.now()` each tick (never decrementing a counter); invalid/unset config → section hides itself (never shows "NaN").
- **Responsive:** 4 digit cards in a row down to 320dp (card width flexible, min 64dp); at text scale >1.5 switch to a 2×2 grid.
- **Accessibility:** semantic label updates at most **once per minute** ("4 days, 12 hours, 37 minutes until Diwali"); seconds are `ExcludeSemantics`; sheet reachable by button "View five-day schedule".

### 3.6 Section 3 — Diwali Explorer

```
┌─────────────────────────────────────┐
│ ── ✿ ── Discover Deepavali ── ✿ ──  │
│ Stories, flavours and rituals       │
│ ┌──────────────┐ ┌──────────────┐   │
│ │ 🪔 Significance│ │ 📖 Traditions │   │  2-col grid (1-col <360dp / large text)
│ │ Light over   │ │ Cleaning,    │   │
│ │ darkness…    │ │ lamps, gifts…│   │
│ └──────────────┘ └──────────────┘   │
│ ┌──────────────┐ ┌──────────────┐   │
│ │ 🌸 Rangoli   │ │ 🍬 Sweets     │   │
│ └──────────────┘ └──────────────┘   │
│ ┌──────────────┐ ┌──────────────┐   │
│ │ 🕯 Rituals   │ │ 📅 Five days  │   │
│ └──────────────┘ └──────────────┘   │
└─────────────────────────────────────┘
```
Six `ExplorerCard`s: **Significance, Traditions, Rangoli, Festive sweets, Rituals (Lakshmi Puja, lamps, fireworks note), Five days of Diwali.**
- **Hierarchy:** `SectionHeader` + `Wrap`/`GridView(shrinkWrap, NeverScrollable)` of `ExplorerCard(icon, title, teaser)`.
- **Interaction:** tap → `showModalBottomSheet` (`isScrollControlled`, draggable, `maxChildSize 0.92`) with: icon + title, 2–4 short paragraphs, a "Regional note" callout, optional "Did you know?" fact, close. Five-days card opens a sheet with a **vertical 5-step timeline**; tapping a step expands it.
- **Content rules:** each topic ≤ ~120 words, plain language; always phrase beliefs as "many believe / traditionally"; include regional variation: e.g. Naraka Chaturdashi is the principal day in much of South India incl. Karnataka (pre-dawn oil bath, Ganga snana) while Lakshmi Puja is central in North/West India; Kali Puja in Bengal; Govardhan Puja/Annakut in North India; Gujarati new year after Diwali; Jain Diwali commemorates Mahavira's nirvana; Sikh Bandi Chhor Divas. Five days: Dhanteras (Dhanatrayodashi), Naraka Chaturdashi (Choti Diwali), Lakshmi Puja (Diwali), Govardhan Puja / Balipratipada, Bhai Dooj. Content reviewed per D11 before merge.
- **Animation:** card press scale 0.97 (100ms); sheet default Material slide; staggered fade-in of cards on first reveal (≤ 60ms offsets, disabled in reduced motion).
- **States:** static data → no loading/error; if a content item is malformed (caught by a unit test, not at runtime) nothing shows.
- **Responsive:** 1 column when width < 360 or text scale ≥ 1.6; 2 columns otherwise; 3 columns on expanded (cap 720 keeps this 2 in practice).
- **Accessibility:** each card = button with label "Significance of Diwali, opens details"; sheet traps focus, announced as dialog, close button + swipe + back gesture.

### 3.7 Section 4 — Diwali Around India

```
┌─────────────────────────────────────┐
│ ── Diwali Around India ──           │
│ Six cities, six ways to celebrate   │
│ ┌────────────┐┌────────────┐┌─────  │  horizontal PageView-like list,
│ │ [ photo ]  ││ [ photo ]  ││ [ph   │  peeking next card
│ │ Varanasi   ││ Jaipur     ││ Ayo.. │
│ │ Ghats glow…││ Lit bazaars││       │
│ └────────────┘└────────────┘└─────  │
│        ● ○ ○ ○ ○ ○                  │  indicator
└─────────────────────────────────────┘
```
- **Hierarchy:** `ListView.builder(scrollDirection: horizontal, physics: ClampingScrollPhysics/snap via PageView(viewportFraction 0.78))` of `DestinationCard(image, name, state, tagline)` + dot indicator.
- **Destinations:** Varanasi (Dev Deepawali on Kartik Purnima, ghats lit with lamps), Jaipur (illuminated markets and city lights), Ayodhya (Deepotsav lamp-lighting on the Sarayu ghats), Amritsar (Bandi Chhor Divas, Golden Temple illuminated), Kolkata (Kali Puja around Diwali night), Mumbai (Lakshmi Puja, Dhanteras shopping, Muhurat trading session). **Every fact is a draft to be sourced** — no record counts, dates or numbers are written into the plan or app unless a citation is attached in the content file (`source` field required by a unit test).
- **Detail route `/deepavali/destination/:id`** (full screen): hero photo with `Hero` transition, name, state, "How it's celebrated" (2–3 paragraphs), "Interesting facts" list (each with source), "Best time" note, photo credit line, back. `id` validated; unknown id → `ErrorView` with "Back".
- **Map:** **not** recommended (see D3). A map package needs online tiles (breaks offline) and adds ~34 transitive dependencies. Alternative within scope: a small decorative India outline `CustomPainter` in the section header with six tappable pins that scroll the gallery — optional, only if outline geometry is licensed/self-drawn.
- **Animation:** card parallax of image inside card (offset by scroll), indicator slide; `Hero` to detail; disabled in reduced motion (plain fade).
- **States:** image loading → gradient placeholder with name; image missing/decode error (`errorBuilder`) → gradient + icon + name; offline: unaffected (bundled).
- **Responsive:** card width `0.78*w` compact, `0.46*w` medium, fixed 300 on expanded; image aspect 4:5; text clamps to 3 lines in-card (full text in detail).
- **Accessibility:** each card button label "Varanasi, Uttar Pradesh. Opens details."; images have `semanticLabel` (describing the picture, e.g. "Lamps floating on the Ganga at Varanasi") or are excluded if purely decorative; gallery is a list with position announced ("1 of 6"); swipe alternatives via visible next/prev buttons on expanded/TalkBack.
- **Photo credits:** each asset has `photographer`, `licence`, `sourceUrl` in the content model; a Credits sheet (Section 10) lists all.

### 3.8 Section 5 — Light the Diyas (mini-game)

```
 State: READY                      State: PLAYING
┌─────────────────────────────┐   ┌─────────────────────────────┐
│ ── Light the Diyas ──       │   │ ⏱ 00:23      🪔 7 / 12      │
│ Tap every unlit diya before │   │ ▓▓▓▓▓▓▓░░░░░  progress bar  │
│ time runs out               │   │  (o)  🪔  (o)  (o)          │
│  [ preview of unlit diyas ] │   │  (o)  (o)  🪔  (o)          │
│   Best: 12/12 in 31 s       │   │  🪔  (o)  (o)  🪔          │
│     [ ▶ Start ]             │   │      [ Pause ] [ Restart ]  │
└─────────────────────────────┘   └─────────────────────────────┘
 State: COMPLETE (success)         State: TIME UP
┌─────────────────────────────┐   ┌─────────────────────────────┐
│     ✨ confetti / sparks ✨  │   │ Time's up!  9 / 12 lit      │
│  All 12 diyas are glowing!  │   │ [ Try again ]               │
│  Time: 24 s · Best: 24 s    │   └─────────────────────────────┘
│ [ Play again ] [ Share card ]│
└─────────────────────────────┘
```
- **Hierarchy:** `DiyaGameSection` → `GameHeader(timer, counter)` → `LinearProgressIndicator(custom gold)` → `DiyaGrid` (`GridView` 3–4 cols, 12 diyas, fixed) → controls. Poster (READY) → PLAYING → COMPLETE | TIME_UP, plus PAUSED.
- **Game rules (decision-free defaults):** 12 diyas, 45 s limit, tap unlit diya → lit (idempotent: tapping a lit diya does nothing, no double count). Win = all lit before 0. No penalties. Optional difficulty = later.
- **State machine** (pure Dart, `domain/diya_game.dart`): `ready → playing ⇄ paused → complete | timeUp`; reducer `tap(index)`, `tick(elapsed)`, `pause()`, `resume()`, `restart()`. Time derived from a `Stopwatch`/monotonic elapsed, not by decrementing a counter, so jank cannot drift the timer. Auto-pause when tab hidden or app backgrounded (`WidgetsBindingObserver`); resume is explicit.
- **Interaction:** tap diya = light with flame "ignite" animation (scale 0→1 flame + glow bloom, 250ms) + `lightImpact` haptic (if enabled); counter and progress animate; at completion → success celebration (Section 3.14 effect) + `mediumImpact`.
- **Animation:** per-diya `AnimatedBuilder` limited to its own `RepaintBoundary`; flames reuse one shared flicker ticker (not one controller per diya); celebration = `ConfettiPainter` (single ticker, ≤ 60 particles, 2 s, then disposed).
- **States:** ready, playing, paused (dims grid, "Paused" overlay with Resume), complete, time-up, reduced-motion (flame fades in, no confetti; result card gets a static "✓"). Error states: none expected (no IO); best score read failure falls back to "—".
- **Persistence:** best time via `shared_preferences` (D10), optional.
- **Responsive:** grid 3 cols on <360, 4 cols otherwise, diya hit area ≥ 56dp; header wraps at 2x text.
- **Accessibility:** each diya = button "Diya 3 of 12, unlit. Double tap to light." → "lit"; progress announced ("7 of 12 lit") via debounced live region; timer announced at 30/10/5 s only; Pause available as a real button; **no-timer "relaxed mode"** toggle as an accessibility accommodation (optional, flagged).

### 3.9 Section 6 — Diwali Quiz

```
 QUESTION                               RESULT
┌─────────────────────────────┐   ┌─────────────────────────────┐
│ Question 3 of 10   ▓▓▓░░░░░ │   │      🏆  You scored 8/10     │
│ Which sweet is made of …?   │   │   "Diwali Dazzler"           │
│ ┌─────────────────────────┐ │   │ ✔ Q1 …  ✘ Q4 … (review list) │
│ │ A  Rasgulla             │ │   │ [ Play again ] [ Share ]     │
│ └─────────────────────────┘ │   └─────────────────────────────┘
│ ┌─────────────────────────┐ │
│ │ B  Laddu            ✔   │ │   after answering:
│ └─────────────────────────┘ │   chosen option turns success/error,
│ ┌─────────────────────────┐ │   correct one is marked, explanation
│ │ C  Jalebi               │ │   card slides in, [ Next ] enabled
│ └─────────────────────────┘ │
│ Explanation: …              │
│            [ Next → ]       │
└─────────────────────────────┘
```
- **Hierarchy:** `QuizSection` → poster (title, "10 questions · ~3 min", Start) → `QuestionView(progress, prompt, OptionTile×4, ExplanationCard, NextButton)` → `ResultView(score, tier title, review list, actions)`.
- **Data:** `domain/content/quiz_questions.dart` — const list of `QuizQuestion(id, prompt, options[4], correctIndex, explanation, category)` (categories: traditions, culture, food, celebrations, folklore); target pool ≥ 20, 10 drawn per session (shuffled question and option order, seeded for testability). Folklore items (Rama's return to Ayodhya, Krishna and Narakasura, Lakshmi, Bali, Bandi Chhor) phrased as traditions; answers reviewed (D11).
- **Interaction:** select option → locks, immediate feedback (colour + icon + text "Correct!"/"Not quite"), explanation revealed, Next enabled (last question: "See results"). No back-navigation within a run; a restart confirms via dialog if mid-run.
- **Scoring:** 1 point per correct, no negative. Tier titles are copy-only (e.g. 0–4 "Keep exploring", 5–7 "Bright spark", 8–10 "Diwali Dazzler"). Best score persisted (D10).
- **Animation:** option feedback colour tween 200ms; explanation `AnimatedSize`; progress bar animates; result score counts up (skipped in reduced motion); celebration effect for ≥ 8.
- **States:** not started, in progress (unanswered / answered), finished. Empty question pool is a programmer error caught by test.
- **Responsive:** options stacked full width; question text wraps; at 2x text card scrolls with the page (no inner scroll).
- **Accessibility:** radio-like semantics (`Semantics(inMutuallyExclusiveGroup, selected)`), feedback announced via live region ("Correct. Laddu is …"), progress "Question 3 of 10".

### 3.10 Section 7 — Rangoli Studio

```
┌─────────────────────────────────────┐
│ ── Rangoli Studio ──                │
│ Tap a shape to colour it            │
│          ┌───────────┐              │
│          │ (mandala  │              │  square canvas, 1:1, ≤ 360dp
│          │  8-fold   │              │  rings × 8 sectors
│          │  symmetry)│              │
│          └───────────┘              │
│  ● ● ● ● ● ● ● ●   ← palette        │  8 colour swatches, selected ring
│  [Symmetry: ON ◉] [🎲 Random]       │
│  [↺ Reset]  [Undo]  [⬇ Share image] │
└─────────────────────────────────────┘
```
- **Hierarchy:** `RangoliSection` → `RepaintBoundary(key)` → `GestureDetector(onTapUp)` → `CustomPaint(RangoliPainter)`; below: `PaletteRow`, `ToggleChip(symmetry)`, `ActionRow`.
- **Geometry (pure Dart in `domain/rangoli_geometry.dart`):** canvas defined in normalised coordinates; rings `r0..r4` (centre disc + 4 annuli + petal outer ring) × 8 sectors; a point → (ring, sector) via polar conversion (`atan2`, distance), so hit-testing needs no per-shape `Path.contains` and is O(1). Petal/lotus shapes are drawn with the same ring/sector index for visual appeal; hit-test uses ring/sector cell.
- **Symmetry:** ON paints the tapped cell **and its 7 rotational counterparts** (and mirror when 16 sectors if approved); OFF paints one cell. State = `List<int?> cellColors` (ring*sectors+sector → palette index).
- **Controls:** palette (8 festival colours + "erase"), **Random** (symmetrical random design from palette, seedable for tests), **Reset** (confirm dialog only if any cell is coloured), **Undo** (stack, depth 50), **Share image**.
- **Export:** `RepaintBoundary.toImage(pixelRatio: 3)` → `ByteData` PNG → temp file (`path_provider`) → `Share.shareXFiles` (share_plus). Canvas painted on a solid dark rounded background so exported PNG isn't transparent. Optional "Save" via `gal` (D5). Export runs off the tap handler with inline progress; failures show SnackBar + Retry.
- **Evaluation:** `CustomPainter` — yes (resolution-independent, one object, cheap); `GestureDetector` — yes with `onTapUp`/`onTapDown` only (no pan, avoids scroll conflict; optional drag-paint only in expanded full-screen route where there is no vertical scroll); `RepaintBoundary` — yes, both for isolating repaint (only repaint on tap) and for export. `shouldRepaint` compares an immutable state snapshot.
- **Animation:** tapped cells animate fill 180ms (a single controller driving a lerp list; or instant if reduced motion); Random sweeps cells in a radial stagger (≤ 600ms).
- **States:** empty (outline only + hint "Tap a shape to begin"), editing, exporting, export success (SnackBar "Ready to share"), export error (Retry). 
- **Responsive:** canvas side = `min(width − 32, 360)`; palette wraps to 2 rows below 320; expanded route (optional) uses full viewport.
- **Accessibility:** canvas is custom-drawn so it gets a semantic grid: `SemanticsProperties` per ring/sector via `CustomPainter.semanticsBuilder` ("Ring 2, section 3, red. Double tap to colour") — heavy at 40 cells but acceptable; **plus** an alternative: "Quick fill ring N" buttons list for screen readers (optional). Palette swatches have colour names. Controls labelled.

### 3.11 Section 8 — Greeting Card Generator

```
┌─────────────────────────────────────┐
│ ── Greeting Card ──                 │
│ ┌─────────────────────────────┐     │
│ │ [ card art: diyas + border ]│     │  RepaintBoundary, 4:5
│ │  Happy Deepavali!           │     │
│ │  Wishing you light & joy    │     │
│ │          — Asha             │     │
│ └─────────────────────────────┘     │
│  Design:  ◉1  ○2  ○3  ○4            │  thumbnails (4 designs)
│  [ ✎ Customise message ]            │  → bottom sheet
│  [ ⤴ Share card ]                   │  native share sheet
└─────────────────────────────────────┘
 Customise (bottom sheet):
 ┌─────────────────────────────────────┐
 │ Message  [preset chips: 4 wishes]   │
 │ [ editable text, max 120 chars  ]   │
 │ From (optional) [ name          ]   │
 │ [ Done ]                            │
 └─────────────────────────────────────┘
```
- **Hierarchy:** `GreetingSection` → `GreetingCardView(design, message, from)` (inside `RepaintBoundary`) → `DesignPicker` (horizontal row of tiny cards) → buttons → `CustomizeSheet`.
- **Designs:** 4 designs drawn with `CustomPainter` + gradients (e.g. Golden Diyas, Rangoli Border, Night Sky Lanterns, Marigold Garland) — vector, no image assets, so no licensing risk. Typography uses bundled display font.
- **Interactions:** pick design (instant), edit message in sheet (keyboard-safe via `viewInsets`), live preview updates, Share → render to PNG at `pixelRatio 3` → temp file → system share sheet with default text "Wishing you a bright and happy Deepavali!".
- **Constraints:** message max 120 chars with counter, `maxLines` auto-fit (`FittedBox`/`AutoSize` hand-rolled with `LayoutBuilder`), personal name max 30 chars; no profanity filter needed (user-only content, never uploaded). Nothing leaves the device unless the user shares.
- **Packages:** `share_plus` (export file share) + `path_provider` (temp file). Alternative without `path_provider`: `XFile.fromData(bytes, mimeType)` works on mobile — **verify at implementation**; if confirmed, `path_provider` is not needed.
- **States:** default, editing, exporting (button shows progress, disabled), share success (none shown; OS handles), share error (SnackBar + Retry), share cancelled (silent).
- **Responsive:** card width = `min(width−32, 340)`, 4:5; design picker scrolls horizontally on narrow screens; tablet: preview left, controls right (expanded only).
- **Accessibility:** card has a semantic summary ("Greeting card, design Golden Diyas: <message> from <name>"); text field labels; preset chips as buttons; sheet focus management; ≥ 4.5:1 contrast on every design (tested via palette).

### 3.12 Section 9 — More to Explore (additional experiences)

```
┌─────────────────────────────────────┐
│ ── More to Explore ──               │
│ ┌─ Virtual Diya Wall ─────────────┐ │
│ │ 🪔🪔🪔🪔🪔🪔   (tiny lit diyas)  │ │  tap → wall sheet/page
│ │ 23 wishes · [ Light a diya ]    │ │
│ └─────────────────────────────────┘ │
│ ┌─ Guess the Diwali object ───────┐ │
│ │ silhouette + 4 choices          │ │  inline mini-game, 8 rounds
│ └─────────────────────────────────┘ │
│ ┌─ Festival Timeline (5 days) ────┐ │
│ │ ● Dhanteras ─ ● Naraka ─ ● …    │ │  horizontal stepper, current day glows
│ └─────────────────────────────────┘ │
│ ┌─ Coming later (optional) ───────┐ │  only listed if approved in D3
│ │ Decorate · Photo booth · For you │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```
Core vs optional:
| Feature | Class | Notes |
|---|---|---|
| **Virtual diya wall** | Core (Phase 9) | Local only. User writes a wish (≤ 80 chars) + optional name → a diya is "lit" on the wall (grid of glowing diyas, newest first). Stored in `shared_preferences` (JSON list, max 50 retained). Seed with a few **clearly marked sample wishes** ("Sample") so the wall is not empty — or leave empty state; decision when Phase 9 starts. **No backend**: it is "your wall", not shared with others, and the UI must say so (no implication of other users). |
| **Guess the object** | Core | 8 rounds, object silhouettes (painted vectors: diya, rangoli, kandeel/lantern, laddu, sparkler, marigold garland, thali, rocket…) → 4 choices → reveal with a one-line fact. Scoring like quiz. |
| **Five-day timeline** | Core | Same data as Explorer "Five days"; here a horizontal stepper with today's day highlighted (from D1). Tap step → detail sheet. |
| Home decoration | **Optional** (D3) | Drag-and-drop lamps/lights/rangoli on a house illustration; needs gesture handling + export; ≥ 2 days. Depends on Phase 7 export utility. |
| Photo booth | **Optional** (D3) | Camera permission + frame overlay + capture/share; needs `camera`/`image_picker` + native permissions + testing on devices. Highest risk. |
| Personalised destination recommendations | **Optional** (D3) | 3–4 question picker → matches one of six destinations (pure local rules). Depends on Phase 4 data. Cheap once Phase 4 exists. |

- **Interactions/animation:** wall: new diya "ignites" with glow; wish sheet with live char counter; timeline: current-day pulse; guess game: reveal flip 250ms. All respect reduced motion.
- **States:** wall empty ("Light the first diya"), wall populated, wish too long/empty (inline validation), storage error (SnackBar "Couldn't save your wish" and the diya still shows for this session); guess game ready/playing/finished.
- **Responsive/a11y:** wall grid 4–6 columns by width, each diya a button reading the wish; wish sheet keyboard-safe; object silhouettes labelled only after reveal (the label *is* the answer).

### 3.13 Section 10 — Footer & Credits
Small text row: "Made with love by the Globus team" (only if the team wants this copy; otherwise omit), buttons "Credits & licences" (sheet listing every third-party image/font/audio with licence + source), "Replay intro". Bottom clearance spacer = `AppSpacing.xl*3 + MediaQuery.paddingOf(context).bottom`.

### 3.14 Cross-cutting: celebration effect & transitions
- **Celebration effect** (`CelebrationBurst`): ≤ 60 gold/saffron sparks launched from a point, gravity + fade, one `CustomPainter`, 1.8–2.2 s, then removed. Used for game win, quiz ≥ 8, rangoli export success (smaller), diya wall wish. Reduced motion → none, replaced with a static check badge + haptic only.
- **Page transitions:** section entrances = fade + 12dp upward slide, once, when the section first scrolls into view (driven by scroll offset check, no extra package); sheets = Material defaults; destination detail = `Hero` + fade.
- **Lifecycle:** every `AnimationController`/`Ticker` disposed; loops paused when (a) tab hidden, (b) app backgrounded, (c) section off-screen; documented in 4.4.

---

## 4. Proposed architecture

### 4.1 Folder structure (fits ADR-003; `domain/` is pure Dart per `architecture_test.dart`)

```
lib/features/deepavali/
  deepavali_feature.dart              [exists] add DeepavaliRoutes constants + destination (and optional) GoRoutes
  deepavali_providers.dart            DI for data/ (prefs-backed stores); only file that sees data + domain
  domain/                             pure Dart — NO flutter imports (enforced)
    festival_dates.dart               event date constant(s), five-day model, derived day dates
    festival_status.dart              (now, dates) -> FestivalStatus (before/festivalWeek/diwaliDay/after)
    content/                          const static content (strings, asset path strings, ids, sources)
      explorer_topics.dart
      destinations.dart
      quiz_questions.dart
      guess_objects.dart
      greeting_presets.dart
    diya_game.dart                    state machine + reducer
    quiz_session.dart                 selection, shuffling (seedable), scoring
    rangoli_state.dart                cell model, symmetry, undo stack, random generator
    rangoli_geometry.dart             polar hit-test maths (no dart:ui)
    greeting.dart                     design ids, message/name validation
    wish.dart                         wish model + validation
  data/                               only persistence/IO adapters
    deepavali_prefs_store.dart        shared_preferences: settings, intro-seen, best scores, wishes
    image_export_service.dart         RepaintBoundary PNG -> file -> share  (dart:ui / share_plus)
  presentation/
    deepavali_page.dart               [exists, replaced] Scaffold, scroll, section keys, AnnotatedRegion
    theme/
      diwali_palette.dart  diwali_text.dart  diwali_theme.dart   feature-local Theme + ThemeExtension
    widgets/
      diwali_card.dart  diwali_button.dart  section_header.dart  ornament_divider.dart
      glow_background.dart  diya_painter.dart  flame.dart  particle_field.dart
      celebration_burst.dart  garland_painter.dart  segment_progress.dart
    sections/
      hero_section.dart  countdown_section.dart  explorer_section.dart
      destinations_section.dart  diya_game_section.dart  quiz_section.dart
      rangoli_section.dart  greeting_section.dart  more_section.dart  footer_section.dart
    sheets/
      topic_sheet.dart  timeline_sheet.dart  customize_card_sheet.dart
      wish_sheet.dart  settings_sheet.dart  credits_sheet.dart
    screens/
      destination_detail_screen.dart  (+ optional full-screen experiences later)
    state/                            Riverpod notifiers (autoDispose where screen-scoped)
      settings_notifier.dart  game_notifier.dart  quiz_notifier.dart
      rangoli_notifier.dart  greeting_notifier.dart  wall_notifier.dart
assets/deepavali/
  images/destinations/<id>.jpg  (+ LICENCES.md/credits data)
  fonts/<display font>.ttf
  (audio/, lottie/ only if D7/D8 approve)
test/features/deepavali/          mirrors lib/ (domain tests, widget tests, golden-free)
```
Notes: `domain/content/` is pure const data (no repository ceremony for static content). `data/` exists only because persistence/export are real IO. Section-local notifiers sit in `presentation/state/` per ARCHITECTURE.md ("Riverpod notifiers in presentation"). `presentation/` must not import `data/`; it reads providers declared in `deepavali_providers.dart` that return domain-typed interfaces (`DeepavaliStore`, `ImageExporter` are declared as abstract in `domain/`, implemented in `data/`).

### 4.2 State management
- Riverpod only (existing). `Notifier`/`AsyncNotifier` with `autoDispose` for game, quiz, rangoli, greeting; `settings`, `wall` are non-autoDispose because the IndexedStack keeps the tab alive and data must survive.
- Pure domain classes are immutable value objects; notifiers wrap them. Time-dependent logic receives `DateTime now` / `Duration elapsed` as parameters → deterministic tests.
- Use `ref.watch(provider.select(...))` in leaf widgets so a game tick does not rebuild the page.

### 4.3 Routing
- Add to `DeepavaliRoutes`: `prefix='/deepavali'`, `destination = '/deepavali/destination/:id'` (+ helper `destinationPath(id)`). Return the `GoRoute`s from `DeepavaliFeature.routes` (replacing `const []`; the getter can no longer be `const`). Optional routes only if approved.
- Module-contract test must still pass; it likely needs a destination-route case in `test/features/deepavali/`.

### 4.4 Animation & lifecycle strategy
- **One shared master ticker** (`AnimationController.unbounded` / `Ticker`) in `DiwaliMotion` (an `InheritedWidget` scoped to the page) feeding flame flicker, glow pulse, garland twinkle and particles → one frame callback rather than dozens.
- **Visibility gating:** `DiwaliMotion.active = tabVisible && appResumed && !reducedMotion`. `appResumed` from `WidgetsBindingObserver`. `tabVisible`: `TickerMode.of(context)` (false inside the IndexedStack's `Offstage` — to be **verified in the Phase 1 spike**); if it does not behave, fall back to the integration owner exposing a visibility hint (shared change, needs approval).
- Section off-screen pause: `ScrollController` offset checks, throttled (≤ 10 Hz).
- Timers (`countdown`, game) use `Stopwatch`/`DateTime.now()` deltas and are cancelled in `dispose`.
- `MediaQuery.disableAnimationsOf(context)` drives reduced motion; user setting can force off but not force on when OS requests reduced motion.
- Lottie vs Flutter vs GIF (decision): **Flutter `CustomPainter` + controllers** for diya, flame, particles, garland, confetti (vector, tiny, theme-able, pausable, accessible). **Lottie** only if a licensed, designer-made one-off (e.g. fireworks finale) is supplied; cap file at ~100 KB and render with `renderCache`/paused when off-screen. **GIF: no** (no pause control, large memory, no reduced-motion support).

### 4.5 Asset strategy
- Bundled only; declared in `pubspec.yaml` as `assets/deepavali/images/`, `assets/deepavali/fonts/` (integration-owner review).
- Photos: JPEG/WebP, longest side ≤ 1600 px, ≤ ~250 KB each (six → ≤ 1.5 MB). Use `Image.asset(cacheWidth: …)` to avoid decoding full size in the gallery. Detail screen loads the larger version.
- Every third-party asset recorded in `assets/deepavali/CREDITS.md` and in-app credits (author, licence, URL, date retrieved). No asset is merged without a recorded licence.
- No raster art for diyas/rangoli/cards (all painters) → zero licensing and size cost.

### 4.6 Packages (checked with `flutter pub add --dry-run` on 2026-11-03; project tree was not modified)

| Package | Resolved version | Purpose | Verdict |
|---|---|---|---|
| `shared_preferences` | 2.5.6 | Settings, intro-seen, best scores, wall wishes | **Add** (D4/D10). Small, first-party. |
| `share_plus` | 13.3.1 | Native share sheet for card/rangoli image | **Add** (D4). Pulls many transitive deps (dry-run: 30 changes); needs iOS/Android review by integration owner. |
| `path_provider` | 2.1.6 | Temp file for sharing | **Add only if** `XFile.fromData` is unreliable (see 3.11). |
| `gal` | 2.3.3 | Explicit "Save to gallery" | Optional (D5); adds iOS `NSPhotoLibraryAddUsageDescription`. |
| `audioplayers` | 6.8.1 | Sound effects | Optional/deferred (D7); heavy (31 dep changes) + audio licences. |
| `lottie` | 3.8.2 | Lottie playback | Optional/deferred (D8). |
| `confetti` | 0.8.0 | Confetti | **Not used** — custom `CelebrationBurst` is ~80 lines and shares the master ticker. |
| `flutter_animate` | 4.5.2 | Declarative animation | **Not used** — built-in implicit animations suffice; avoids a dependency. |
| `flutter_map` | 8.3.2 | Interactive map | **Not used** — needs online tiles, 34 deps (conflicts with offline requirement). |
| `google_fonts` | (not added) | Fonts | **Not used** — runtime download breaks offline; bundle font files. |
Haptics use `package:flutter/services.dart` `HapticFeedback` (no package). Compatibility with Flutter 3.47.9/Dart 3.13 was confirmed only to the extent that pub resolved them; real device behaviour is part of each phase's verification. Re-run `flutter pub add --dry-run` at implementation time because versions may move.

### 4.7 Testing strategy (applies to every phase)
- **Unit (domain):** countdown/status boundaries, game state machine (idempotent taps, timeout, pause/resume), quiz scoring/shuffle determinism, rangoli polar hit-test + symmetry + undo, wish validation, content integrity (unique ids, 4 options, correctIndex in range, every destination has ≥1 sourced fact and an image credit, no empty strings).
- **Widget:** each section renders at 320dp/360dp/411dp/600dp and 1x/2x text without overflow; reduced-motion variants (`MediaQueryData(disableAnimations: true)`); semantics tree checks (labels/roles); sheet open/close; fake clock injection for countdown; fake store/exporter overrides.
- **Architecture:** existing `test/architecture_test.dart` must stay green (domain pure; no presentation→data imports).
- **Integration (on device):** add a Diwali trace to `integration_test/perf_test.dart` (scroll entire page, play game, quiz, rangoli taps) using `ValueKey`s; profile mode, p99 < 16 ms on the D14 baseline device.
- **Manual device checks:** share sheet, export image content, status-bar icons, offline (airplane mode), tab switching while a game runs, app backgrounding, Devanagari/Kannada rendering, TalkBack/VoiceOver pass.
- **Gate:** `./scripts/check.sh` green before each phase is considered done.

---

## 5. Phased implementation plan

Conventions per phase: **Depends on** → prerequisites; **Files** → existing (E) and new (N); every phase ends with `./scripts/check.sh` green and a short on-device sanity run. Features are listed once; nothing in the brief is dropped (see traceability table in 6.3).

### Phase 0 — Approvals & prerequisites (no app code)
- **Objective:** unblock decisions so later phases don't invent requirements.
- **Tasks:** get answers to D1–D14; get integration-owner approval for packages and for `pubspec.yaml` asset/font entries; obtain images (D2) or agree on placeholders; name the content reviewer (D11); pick the baseline device (D14).
- **Output:** a short "Decisions resolved" section appended to this plan.
- **Acceptance:** D1, D2, D4, D6, D9 answered at minimum (they gate Phases 1, 2, 4, 7/8). **Risks:** Phase 4 blocked on images; Phase 10 blocked on audio licences.

### Phase 1 — Foundation & Design
- **Objective:** a themed, scrollable, empty-but-styled Diwali tab with reusable components and the architecture skeleton; no real content yet.
- **Depends on:** Phase 0 (D6, D9).
- **Files:** E `deepavali_page.dart` (replace), E `deepavali_feature.dart` (routes constants only); N `presentation/theme/*`, `presentation/widgets/{diwali_card,diwali_button,section_header,ornament_divider,glow_background}.dart`, `presentation/sections/*` (placeholder section shells), `presentation/state/settings_notifier.dart` (motion/sound/haptics flags, in-memory first); N `test/features/deepavali/...`; shared: `pubspec.yaml` (font asset entry) after approval.
- **Tasks:** (1) Spike: verify `TickerMode`/Offstage behaviour in the IndexedStack and `AnnotatedRegion` status-bar behaviour on a device. (2) Palette, `ThemeData` override via `Theme(data: …)` wrapper + `ThemeExtension` for gold/glow/gradients. (3) Typography with bundled font; Kannada/Devanagari fallback check. (4) Components: `DiwaliCard`, `DiwaliButton` (primary/secondary/tertiary), `SectionHeader`, `OrnamentDivider`, `GlowBackground`. (5) `DeepavaliPage`: `Scaffold(backgroundColor: night)`, `SingleChildScrollView` + `ConstrainedBody` + section keys + bottom clearance (96 + inset), page gradient, status-bar region. (6) `DiwaliMotion` scope (master ticker, reduced-motion/lifecycle gating) — skeleton only. (7) Section shells with titles to prove ordering and spacing.
- **Assets/packages:** 1 bundled font; no packages.
- **Acceptance:** tab renders with gradient and section headers in system light and dark; no overflow at 320dp/2x text/landscape; last section clears the floating bar; other tabs unaffected (contract + existing tests pass); architecture test green; contrast test of palette passes; ticker/status-bar spike results recorded.
- **Tests:** palette contrast, widget layout matrix, reduced-motion flag plumbing, architecture test.
- **Risks:** status-bar override reverting wrongly; ticker not paused when hidden (fallback in 4.4); font licence/size.

### Phase 2 — Animated Hero & Celebration Status
- **Objective:** the hero (3.4) and countdown/status (3.5), with intro skip/replay.
- **Depends on:** Phase 1; D1.
- **Files:** N `domain/festival_dates.dart`, `domain/festival_status.dart`, `data/deepavali_prefs_store.dart` + `deepavali_providers.dart` (intro-seen) *(or in-memory until Phase 9 if `shared_preferences` not yet approved)*, `presentation/widgets/{diya_painter,flame,particle_field,garland_painter}.dart`, `presentation/sections/{hero_section,countdown_section}.dart`, `presentation/sheets/timeline_sheet.dart`.
- **Tasks:** pure `FestivalStatus` with injected `now`; `DiyaPainter` + `Flame`; `ParticleField` (single painter, budgeted); intro sequence controller (ignite → text → idle) with Skip/Replay and persisted seen-flag; CTA with `Scrollable.ensureVisible`; countdown cards, once-per-minute semantic updates, 2×2 fallback; timeline sheet; pause when hidden/off-screen.
- **Packages:** `shared_preferences` (if approved) for intro-seen.
- **Acceptance:** intro plays on first run only, Skip/Replay work, re-selecting the tab never replays; countdown matches device clock for before/week/day/after states (tested with fake `now` incl. midnight and boundaries); CTA lands on Explorer header; animations stop when hidden/scrolled away/reduced-motion; p99 frame time < 16 ms in profile on baseline device; TalkBack reads hero and countdown sensibly.
- **Tests:** status table tests, widget tests with fake clock, reduced-motion render, semantics, ticker disposal.
- **Risks:** date/time-zone assumptions (D1); particle cost on low-end devices (budget fallback).

### Phase 3 — Diwali Information Explorer
- **Objective:** six interactive cards + detail bottom sheets (3.6).
- **Depends on:** Phase 1; D11 (reviewer).
- **Files:** N `domain/content/explorer_topics.dart`, `presentation/sections/explorer_section.dart`, `presentation/sheets/topic_sheet.dart` (reuse `timeline_sheet`).
- **Tasks:** author concise content (≤ ~120 words/topic, "Regional note" per topic where relevant, five days incl. regional differences); card grid with responsive columns; sheet with consistent layout; staggered reveal; semantics.
- **Acceptance:** all six topics open and close (tap, swipe, back); text scales to 2x; content test (non-empty, length caps, regional note present on topics that need it); reviewer sign-off recorded; no hard-coded colours.
- **Tests:** content integrity, widget (open sheet, semantics), layout matrix.
- **Risks:** factual accuracy and regional bias → review gate; copy length vs sheet height at 2x.

### Phase 4 — Diwali Around India
- **Objective:** destination gallery + detail route (3.7).
- **Depends on:** Phase 1; D2 (images); D11.
- **Files:** N `domain/content/destinations.dart`, `presentation/sections/destinations_section.dart`, `presentation/screens/destination_detail_screen.dart`, `assets/deepavali/images/destinations/*`, `assets/deepavali/CREDITS.md`; E `deepavali_feature.dart` (route), E `pubspec.yaml` (asset dir, approval).
- **Tasks:** six destination records each with tagline, description, ≥ 1 sourced fact, credit, image path; gallery with snap/peek/indicator; `Hero` detail route with id validation (`ErrorView` for unknown); image loading/error fallbacks; credits entries; optional India-outline pin map **only** if D3 approves (otherwise explicitly skipped, noted in plan).
- **Acceptance:** six cards in the stated set, all open details and back; every fact has a source in data; every image has licence/credit; works offline; no image decoded above needed size (check via DevTools memory); unknown route id handled; text/gallery layouts verified at 320dp–840dp.
- **Tests:** content integrity (sources/credits required), route param validation, gallery widget test, image-error fallback test.
- **Risks:** **image availability/licensing (hard blocker for final quality; placeholders must be clearly marked and not shipped as "done")**; fact accuracy; APK size.

### Phase 5 — Light the Diyas
- **Objective:** inline game with full state machine (3.8).
- **Depends on:** Phase 1–2 widgets (diya/flame, motion scope).
- **Files:** N `domain/diya_game.dart`, `presentation/state/game_notifier.dart`, `presentation/sections/diya_game_section.dart`, `presentation/widgets/celebration_burst.dart`.
- **Tasks:** pure state machine + reducer; stopwatch-based timer notifier (auto-pause on hidden/background); diya grid; ignite animation; progress/counter; start/pause/restart; complete + time-up screens; celebration; best time (prefs, optional); relaxed mode if approved.
- **Acceptance:** all states reachable and recoverable; double taps never double count; timer doesn't drift or run while hidden; restart fully resets (no leaked tickers); win exactly when 12/12 before timeout; 60fps in profile with 12 flames; semantics announce progress; works with reduced motion.
- **Tests:** exhaustive reducer tests (every transition incl. illegal ones), timer tests with fake clock, widget tests for each state, tab-hidden pause test.
- **Risks:** timer/lifecycle bugs; performance of 12 glow effects (shared ticker, no `saveLayer` blur per diya — use pre-rendered radial gradient).

### Phase 6 — Diwali Quiz
- **Objective:** quiz flow, feedback, results (3.9).
- **Depends on:** Phase 1; D11.
- **Files:** N `domain/content/quiz_questions.dart`, `domain/quiz_session.dart`, `presentation/state/quiz_notifier.dart`, `presentation/sections/quiz_section.dart`.
- **Tasks:** ≥ 20 reviewed questions across the five categories with explanations; seedable shuffle; answer lock + feedback + explanation; progress; results with review list and tiers; restart (confirm); best score; celebration for ≥ 8.
- **Acceptance:** 10-question run scores correctly for all-correct/all-wrong/mixed; cannot change a locked answer; option order shuffled yet correctness preserved; results review matches choices; content integrity test passes; accessible feedback.
- **Tests:** scoring/shuffle unit tests, content integrity (4 options, valid index, non-empty explanation, unique ids), widget flow test end-to-end, semantics.
- **Risks:** factual errors in questions (review gate), ambiguous folklore wording.

### Phase 7 — Interactive Rangoli Studio
- **Objective:** symmetrical, tappable rangoli with export (3.10).
- **Depends on:** Phase 1; D4/D5 (share/gallery packages) for export.
- **Files:** N `domain/rangoli_geometry.dart`, `domain/rangoli_state.dart`, `presentation/state/rangoli_notifier.dart`, `presentation/sections/rangoli_section.dart`, `presentation/widgets/rangoli_painter.dart`, `data/image_export_service.dart` (+ abstract in domain), `deepavali_providers.dart`.
- **Tasks:** polar geometry & hit-test; painter (cells + decorative outlines); symmetry toggle; palette; random (seedable); undo/reset (confirm when dirty); export via `RepaintBoundary.toImage` → file → share; optional `gal` save; error/progress states.
- **Acceptance:** every tap maps to the intended ring/sector (table-driven tests incl. centre, ring borders, outside canvas ignored); symmetry paints all 8 counterparts; reset/undo exact; exported PNG has opaque background, 3x pixel ratio, matches on-screen; share sheet opens on both OS; no jank while tapping (repaint only canvas); vertical scroll never blocked by canvas.
- **Tests:** geometry unit tests, state/undo tests, widget tap test with `tester.tapAt`, fake exporter, export-error path.
- **Risks:** `toImage` on low-memory devices (cap ratio), share_plus native config, accessibility of custom canvas.

### Phase 8 — Greeting Card Generator
- **Objective:** card designs, customisation, sharing (3.11).
- **Depends on:** Phase 7 export service; D5, D9, D12.
- **Files:** N `domain/greeting.dart`, `domain/content/greeting_presets.dart`, `presentation/state/greeting_notifier.dart`, `presentation/sections/greeting_section.dart`, `presentation/sheets/customize_card_sheet.dart`, `presentation/widgets/greeting_card_view.dart` (4 painters/designs).
- **Tasks:** 4 vector designs; design picker; message presets + free text (limit 120) + optional name; auto-fit text; export & share through shared exporter; keyboard-safe sheet; error handling.
- **Acceptance:** each design renders any message up to limit without overflow at 1x–2x text; empty name omitted cleanly; long words wrap; shared PNG shows exactly the preview; cancel share is silent; failure shows retry; nothing uploaded.
- **Tests:** validation, widget tests per design, export fake, semantics.
- **Risks:** font embedding in exported image (uses bundled font → consistent), Kannada/Hindi glyph rendering.

### Phase 9 — Additional Festive Experiences
- **Objective:** core extras: diya wall, guess-the-object, five-day timeline (3.12); evaluate optional ones.
- **Depends on:** Phases 2, 5, 6 (shared components), Phase 7 (if decorating); D3, D10.
- **Files:** N `domain/wish.dart`, `domain/content/guess_objects.dart`, `presentation/state/wall_notifier.dart`, `presentation/sections/more_section.dart`, `presentation/sheets/wish_sheet.dart`, `data/deepavali_prefs_store.dart` (extend).
- **Tasks (core):** diya wall (local persistence, validation, empty/sample policy, ignite animation, "only on this device" copy); guess-the-object (8 silhouette painters + facts + scoring); horizontal timeline stepper reusing five-day data and today highlight.
- **Tasks (optional, only if D3 = yes, one at a time, each its own mini-plan to be approved first):** recommendations (cheapest, after Phase 4), home decoration (after export exists), photo booth (needs camera package/permissions — highest risk).
- **Acceptance (core):** wishes survive app restart; storage failure doesn't crash; ≤ 50 wishes retained; guess game scoring correct; timeline highlights today correctly for any date (tests); all work offline. Optional items: not started without explicit approval; "Coming later" card must not appear unless something is genuinely planned.
- **Tests:** wish validation/persistence with in-memory fake prefs, guess scoring, timeline highlight table tests, widget tests.
- **Risks:** scope creep (optional items), wall implying social features that don't exist (copy), storage corruption (try/catch + reset).

### Phase 10 — Animation, Audio & Haptics
- **Objective:** polish layer applied consistently; user control.
- **Depends on:** Phases 2–9; D7, D8.
- **Files:** N `presentation/widgets/section_reveal.dart`, `presentation/sheets/settings_sheet.dart`, `presentation/state/settings_notifier.dart` (persist), `domain/` interface `SoundPlayer` + `data/` impl only if D7 = yes; E existing widgets (hook haptics/effects).
- **Tasks:** section reveal transitions; unify `CelebrationBurst` usage; haptics map (selection on picks, light on diya, medium on success, none on errors) behind the setting; settings sheet (Sound — default **off**, Haptics, Animations: System/On/Off); persistence; **if audio approved:** load short clips lazily, respect silent mode/audio focus, never autoplay, volume low, dispose player, assets ≤ ~50 KB each with licences; Lottie only if supplied (D8).
- **Acceptance:** with sound off nothing plays and no audio package initialises; reduced-motion disables all non-essential motion across every section (checked with a widget-test sweep); no animation/ticker runs when tab hidden (instrumented test); asset size delta documented; haptics fire only when enabled; no frame regression versus Phases 2/5.
- **Tests:** settings persistence, haptic call recording via `SystemChannels.platform` mock, reduced-motion sweep, ticker-count assertion hidden/visible.
- **Risks:** audio licensing/lifecycle, binary size, iOS haptics availability variance.

### Phase 11 — Integration, Testing & Polish
- **Objective:** ship-quality, verified feature.
- **Depends on:** all prior phases.
- **Files:** E `integration_test/perf_test.dart` (add Diwali trace), `docs/PROJECT_PROGRESS.md` (record results, per team rules), `assets/deepavali/CREDITS.md`; fixes anywhere in the feature.
- **Tasks:** full-page scroll pass; tab-switch pass (Rajyotsava ↔ Deepavali ↔ Games) with a running game; state retention checks; offline run in airplane mode; error-path drills (missing image, storage failure, share failure); accessibility audit (TalkBack + VoiceOver, 2x text, contrast); performance profile (p99 < 16 ms, memory after repeated visits, release APK size delta); licence audit; remove placeholders, TODOs, debug code and unused dependencies (`flutter pub deps`, check each package is imported); visual consistency review against 3.2; `./scripts/check.sh` + CI debug APK; update docs only where the contract changed.
- **Acceptance:** every checklist item in 6.2 ticked with evidence; no placeholder content; no overflows at the full layout matrix; other tabs' tests unchanged and green.
- **Risks:** device-only defects found late (so run device checks from Phase 1 onward, not only here).

---

## 6. Execution sequence & validation

### 6.1 Recommended order
```
Phase 0 (decisions)  ─▶ Phase 1 (foundation)
                          ├▶ Phase 2 (hero + countdown)      ← first visible milestone
                          ├▶ Phase 3 (explorer)               [parallel-safe with 2]
                          ├▶ Phase 4 (destinations)           [needs images]
                          ├▶ Phase 5 (diya game)
                          └▶ Phase 6 (quiz)
                          Phase 7 (rangoli + export service) ─▶ Phase 8 (greeting card)
                          Phases 2–8 ─▶ Phase 9 (extras: core, then optional if approved)
                          Phases 2–9 ─▶ Phase 10 (animation/audio/haptics) ─▶ Phase 11 (integration & polish)
```
Per-phase gate before starting the next: (1) `./scripts/check.sh` passes; (2) phase acceptance criteria demonstrated on a physical Android device (screenshots or screen recording attached to the PR); (3) no unapproved package/asset/shared-file changes; (4) other teams' files untouched (`git diff --stat` shows only `lib/features/deepavali/`, `test/features/deepavali/`, `assets/deepavali/`, and approved `pubspec.yaml` lines); (5) PR title `deepavali: <what>`, < ~400 changed lines where feasible (split phases into several PRs).

### 6.2 Final execution checklist
Ticked with evidence on 2026-11-03. Items marked **open** need a person outside this work.
- [x] D1–D14 resolved and recorded (answers recorded in the status notes at the top of this file)
- [x] Package/asset/font approvals on record (user approved `google_fonts`, `shared_preferences`, `share_plus`, `image_picker`; **open:** integration-owner sign-off in `docs/PROJECT_PROGRESS.md`)
- [x] Phase 1: theme, components, scroll shell, ticker & status-bar spike results
- [x] Phase 2: hero, intro skip/replay, CTA scroll, countdown/status incl. after-event state
- [x] Phase 3: six explorer topics + sheets (**open:** content reviewer sign-off, D11)
- [x] Phase 4: six destinations, detail route, credits, offline
- [x] Phase 5: diya game all states
- [x] Phase 6: quiz scoring, feedback, results
- [x] Phase 7: rangoli tap/symmetry/random/reset/undo/export
- [x] Phase 8: four card designs, customise, share
- [x] Phase 9: diya wall, guess game, timeline; optional features built (recommendations, home decoration, photo booth)
- [x] Phase 10: audio (song with mute, effects), haptics always on, reduced motion follows the phone (the settings sheet was removed on request)
- [x] Phase 11: accessibility (semantics, 4.5:1 contrast test, 2x text), performance (profile traces, fixes, release size), licensing (audit test; the credits footer was built and then removed on request), offline (no network calls, bundled font and media), error handling (drills in tests), cleanup
- [x] No placeholder text/images, no unused packages, no TODOs (searched; one unused helper removed; debug prints replaced by the app logger)
- [x] `./scripts/check.sh` green (528 tests); progress doc updated; **open:** CI run on GitHub, iOS build, listening test, licence confirmation for the song and four team-supplied photos

### 6.3 Traceability — every requested feature maps to a phase
| Requested | Phase | Class |
|---|---|---|
| Visual identity, typography, cards, buttons, spacing, gradients, decor, structure, responsive, a11y | 1 | Core |
| Hero greeting, diyas, flames, particles, CTA | 2 | Core |
| Countdown/celebration status, skippable/replayable intro | 2 | Core |
| Traditions, significance, rangoli, sweets, rituals, five days + sheets | 3 | Core |
| Six-city gallery, photos, facts, detail views | 4 | Core |
| Interactive map | 4 (decorative pins) | **Optional**, D3 |
| Light the Diyas game | 5 | Core |
| Quiz | 6 | Core |
| Rangoli studio + export | 7 | Core |
| Greeting card + share | 8 | Core |
| Virtual diya wall, guess-the-object, five-day timeline | 9 | Core |
| Home decoration, photo booth, personalised recommendations | 9 | **Optional**, D3 |
| Lottie/animation/GIF evaluation, transitions, sound, haptics, reduced motion, controls | 10 (evaluation in 4.4) | Core (sound optional, D7) |
| Integration, testing, accessibility, performance, licensing, cleanup | 11 | Core |

### 6.4 Recommended first step
Do **Phase 0** now (answer D1, D2, D4, D6, D9 minimum), then start **Phase 1**. Phase 1 contains the two device spikes (tab-hidden ticker behaviour, status-bar icons) whose results can change the animation strategy for Phases 2, 5 and 10, so they must happen before any animated work.

### 6.5 Known limitations of this plan
- Facts about destinations, festival days and regional customs are outlines for authors to verify, not publishable copy; sources are mandatory in the data model.
- The 2026 date (8 Nov) is an expectation, not confirmed (D1).
- Package versions come from today's pub resolution; transitive dependency counts and native config needs must be re-checked at install time.
- Nothing here has been run on a device; performance targets are acceptance criteria, not measurements.
