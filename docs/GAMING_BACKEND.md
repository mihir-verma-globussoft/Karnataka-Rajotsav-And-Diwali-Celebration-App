# Shared Supabase gaming backend

This document describes the production backend used by the app, how a game
result reaches Supabase, and how another game can use the same accounts,
profiles, statistics, and leaderboard infrastructure without coupling itself
to Flappy Bird.

The database contract is game-neutral. Flappy Bird is the first registered
game and remains the default in the Flutter adapter for backward compatibility.

## 1. System overview

```text
Google account chooser
        |
        | ID token + Google access token
        v
Supabase Auth ------------------------+
        | authenticated UUID          |
        v                             |
auth.users                            |
        | database trigger            |
        +--> profiles                 | shared account/profile
        +--> player_game_stats        | one row per player and game
                                      |
Flutter game                          |
        | submit_game_result RPC -----+
        | get_my_stats RPC
        | get_leaderboard RPC
        v
game_results + player_game_stats
        |
        +--> per-game leaderboard
```

Supabase provides four backend services:

- **Auth** owns sessions and the authenticated player UUID.
- **PostgreSQL** stores profiles, the game registry, immutable game results,
  and aggregate statistics.
- **Database functions (RPCs)** are the only client-accessible score-writing
  path and perform validation and atomic updates.
- **Storage** holds camera character avatars in player-owned folders.

The Flutter app uses Riverpod for dependency injection. Widgets depend on
repository interfaces; Supabase calls remain in the data layer.

## 2. Source-of-truth files

| Responsibility | File |
|---|---|
| Supabase initialization | `lib/app/bootstrap.dart` |
| Build-time configuration | `lib/core/config/app_config.dart` |
| Google and Supabase authentication | `lib/features/flappy_bird/data/supabase_auth_repository.dart` |
| Profiles, stats, leaderboard and score RPC client | `lib/features/flappy_bird/data/supabase_player_repository.dart` |
| Offline pending-result queue | `lib/features/flappy_bird/data/local_game_storage.dart` |
| Pac-Man scores (slug `pacman`; migration `202611040002_pacman_game.sql` must be applied) | `lib/features/pacman_game/data/supabase_pacman_scoreboard.dart` |
| Domain models and repository contracts | `lib/features/flappy_bird/domain/` |
| Riverpod dependency wiring and retry service | `lib/features/flappy_bird/flappy_bird_providers.dart` |
| Database schema, RLS, RPCs and Storage policies | `supabase/migrations/` |

Apply migrations strictly in filename order. A migration is the source of
truth; do not make undocumented production-only SQL changes in the dashboard.

## 3. Environment and initialization

The client requires these build-time values:

```dotenv
APP_ENV=dev
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=sb_publishable_REPLACE_ME
GOOGLE_WEB_CLIENT_ID=REPLACE_ME.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=REPLACE_ME.apps.googleusercontent.com
```

Build with:

```sh
flutter run --dart-define-from-file=.env
```

`bootstrap()` initializes Supabase before `runApp`. Supabase Flutter restores a
persisted session during initialization, so the root account gate can decide
whether to show login, camera onboarding, or the application.

The anon/publishable key is intended for a public client and receives only the
permissions granted by RLS and SQL grants. Never embed the service-role key,
database password, or Google client secret in Flutter.

## 4. Authentication and player provisioning

### Google sign-in flow

1. The player taps **Continue with Google**.
2. `google_sign_in` performs the native Google account flow.
3. The Flutter client obtains a Google ID token and access token.
4. `SupabaseAuthRepository` sends both to
   `supabase.auth.signInWithIdToken(provider: google, ...)`.
5. Supabase validates the Google identity and creates or restores a Supabase
   session.
6. The app uses only the session-derived `auth.uid()` for backend identity.

The Flutter app never sends a user UUID as an authority for score submission.
This prevents one signed-in player from submitting a score for another player.

### Automatic profile creation

The `on_auth_user_created` trigger runs `handle_new_user()` after Supabase adds
a row to `auth.users`. It creates:

- a `profiles` row with Google name, email, and profile image metadata; and
- the initial Flappy Bird aggregate row.

The migration also backfills profiles for Auth users who existed before the
trigger was installed. Other games lazily create their aggregate row on their
first accepted result. Before that first result, `get_my_stats` returns zero
totals and a null global rank.

### Root access gate and character photo

A configured build gates the whole application at startup:

1. no session: show Google sign-in;
2. session but no `character_avatar_url`: require front-camera capture;
3. session and character photo: show the app router.

The camera image is uploaded only after the player confirms it. The public
leaderboard uses the camera character image first and falls back to the Google
profile image.

## 5. Final database model

### `profiles`

One shared account record per Supabase user.

| Column | Purpose |
|---|---|
| `id uuid` | Primary key and foreign key to `auth.users(id)` |
| `username text` | Public display name, 3–24 characters |
| `email text` | Private account information |
| `avatar_url text` | Google profile image fallback |
| `character_avatar_url text` | Camera-created public game character |
| `created_at`, `updated_at` | Account timestamps |

### `games`

Server-managed registry that defines every game accepted by the score RPC.

| Column | Purpose |
|---|---|
| `slug text` | Stable API identifier such as `flappy_bird` |
| `display_name text` | Human-readable name |
| `is_active boolean` | Disables new submissions without deleting history |
| `max_score integer` | Maximum accepted score |
| `max_duration_ms integer` | Maximum accepted session duration |
| `minimum_ms_per_score integer` | Basic score-versus-time plausibility rule |
| `created_at`, `updated_at` | Registry timestamps |

Slugs must match `^[a-z0-9_]{3,48}$`. Never reuse or rename a slug after
shipping a client; add a new slug if the scoring model is incompatible.

### `player_game_stats`

One aggregate row per `(user_id, game_slug)`.

| Column | Purpose |
|---|---|
| `user_id uuid` | Player identity |
| `game_slug text` | Registered game |
| `high_score integer` | Greatest accepted score |
| `total_games integer` | Count of unique accepted results |
| `total_score bigint` | Sum of unique accepted scores |
| `high_score_achieved_at timestamptz` | Deterministic tie-break timestamp |
| `updated_at timestamptz` | Last aggregate update |

The composite primary key prevents one game's totals from affecting another
game. The leaderboard index begins with `game_slug` and then follows the exact
leaderboard sort order.

### `game_results`

Append-only record of accepted completed games.

| Column | Purpose |
|---|---|
| `id uuid` | Client-generated, globally unique idempotency key |
| `user_id uuid` | Derived from the authenticated session by the RPC |
| `game_slug text` | Registered game |
| `score integer` | Reported final score |
| `duration_ms integer` | Reported gameplay duration |
| `started_at timestamptz` | Client-reported start time |
| `completed_at timestamptz` | Server insertion time |

The primary key on `id` makes retrying the same completed game safe.

## 6. Security model

RLS is enabled on `profiles`, `games`, `player_game_stats`, `game_results`, and
Storage objects.

| Operation | Client permission |
|---|---|
| Read own complete profile | Allowed |
| Update own username/character URL | Allowed, column-restricted |
| Read another player's email/profile row directly | Denied |
| Read own raw results and aggregates | Allowed |
| Insert/update/delete raw stats directly | Denied |
| Insert raw game results directly | Denied |
| Change the game registry | Denied |
| Read limited public leaderboard fields through RPC | Allowed when authenticated |
| Upload/replace/delete another player's avatar | Denied |

The leaderboard is a `security definer` function with a fixed `search_path`.
It intentionally exposes only rank, UUID, username, public avatar, and high
score. It never returns email or raw game history.

Score functions revoke access from `public` and `anon` and grant execution only
to `authenticated`. Direct table writes are also revoked, so bypassing the app
UI does not bypass validation.

## 7. RPC contracts

### `submit_game_result`

Parameters:

```text
p_game_id     uuid         unique ID generated once when the game starts
p_game_slug   text         registered game slug
p_score       integer      final score
p_duration_ms integer      elapsed gameplay time
p_started_at  timestamptz  game start timestamp
```

Successful response:

```json
{
  "high_score": 67,
  "total_games": 12,
  "total_score": 314,
  "is_new_high_score": true,
  "already_submitted": false
}
```

The function executes one transaction and:

1. requires `auth.uid()`;
2. verifies the game exists and is active;
3. validates score, duration, plausibility, timestamp, and rate limit;
4. creates the per-game aggregate row if needed;
5. locks that aggregate row for concurrent updates;
6. inserts `game_results` using the game UUID;
7. returns without changing totals when that UUID already exists;
8. otherwise increments totals and atomically applies
   `greatest(existing_high_score, submitted_score)`.

Current global validation also rejects start times more than five minutes in
the future or 30 days in the past and more than 120 accepted submissions per
player, per game, per hour.

### `get_my_stats`

Input:

```json
{"p_game_slug": "flappy_bird"}
```

Returns the authenticated player's high score, games, total score, and global
rank for exactly one game. A player with no result for that game receives zeros
and `global_rank: null`.

### `get_leaderboard`

Input:

```json
{
  "p_game_slug": "flappy_bird",
  "p_offset": 0,
  "p_limit": 20
}
```

The server clamps page size to 1–50. Ordering is deterministic:

1. `high_score DESC`;
2. earliest `high_score_achieved_at` first;
3. `user_id ASC` as the final stable tie-break.

Ranks are calculated before pagination, so page two retains global ranks
rather than restarting at rank one.

### `delete_own_account`

Uses `auth.uid()` and deletes that Auth user. Foreign keys cascade profile,
aggregate, and result deletion. The client first attempts to remove the player
avatar and then revokes the local Google credential.

## 8. Offline delivery and idempotency

`ScoreSubmissionService` sends the final result through `PlayerRepository`. If
the RPC fails, it stores the full result locally, including `game_slug`, and
reports that the server has not confirmed the save.

At the next controlled retry:

- the same `game_id` is sent again;
- Supabase inserts it once or returns `already_submitted: true`;
- only a confirmed result is removed from local storage.

This provides at-least-once delivery from the device and exactly-once aggregate
effects in the database. Generate the UUID once per game and retain it across
all retries. Never create a new UUID merely because a network request failed.

## 9. Registering another game

Game registration is an administrator/migration action, not a mobile-client
action. Add a new migration such as:

```sql
begin;

insert into public.games (
  slug,
  display_name,
  max_score,
  max_duration_ms,
  minimum_ms_per_score
) values (
  'pitch_game',
  'High/Low Pitch',
  50000,
  1800000,
  20
)
on conflict (slug) do update set
  display_name = excluded.display_name,
  max_score = excluded.max_score,
  max_duration_ms = excluded.max_duration_ms,
  minimum_ms_per_score = excluded.minimum_ms_per_score,
  is_active = true;

commit;
```

Choose limits from measured legitimate gameplay. Do not copy Flappy Bird's
`450 ms/point` rule unless the new game's scoring cadence is genuinely similar.

Deploy with:

```sh
supabase link --project-ref <project-ref>
supabase db push --remote --include-all
```

Review the dry run first for a shared production project.

## 10. Connecting another Flutter game

### Reuse the authenticated session

All modules in this app use the one root Supabase session. A new module should
read the existing client/repositories through Riverpod rather than initialize a
second Supabase singleton or show another Google login.

### Scope the repository to the new game

`SupabasePlayerRepository` accepts a game slug:

```dart
final pitchRepository = SupabasePlayerRepository(
  Supabase.instance.client,
  gameSlug: 'pitch_game',
);
```

This scopes `loadStats()` and `loadLeaderboard()` to `pitch_game`.

### Create a result once

At the beginning of a new game, create one UUID and record the start time. At
the genuine terminal game-over event, submit:

```dart
final result = GameResult(
  gameId: gameIdCreatedAtStart,
  gameSlug: 'pitch_game',
  score: finalScore,
  duration: elapsedGameplayDuration,
  startedAt: startedAt,
);

final submission = await pitchRepository.submitGame(result);
```

The repository rejects a result whose slug does not match its configured game,
which prevents an accidental cross-game leaderboard write.

### Use the shared retry behavior

For production use, send through `ScoreSubmissionService`, backed by a
`PendingGameRepository`, instead of calling the remote repository directly.
The local serializer preserves `game_slug`, so multiple game types remain
correct after an app restart.

A new module should expose its own Riverpod providers returning domain
interfaces. Do not call Supabase directly from a widget.

### Refresh affected views

After a confirmed submission:

- refresh the new game's dashboard/stat provider;
- refresh its leaderboard provider;
- display `is_new_high_score` only from the confirmed response;
- retain a visible pending state when submission has not been confirmed.

### Games already registered

| Slug | Game | Points (more is better) | Source |
|---|---|---|---|
| `flappy_bird` | Flappy Bird | pipes passed | `lib/features/flappy_bird/` |
| `rajyotsava_quiz` | Rajyotsava Quiz | up to 2200 | `lib/features/rajyotsava/data/supabase_quiz_scoreboard.dart` |
| `deepavali_quiz` | Deepavali Quiz | up to 1500 | `lib/features/deepavali/data/supabase_deepavali_scoreboard.dart` |
| `deepavali_guess` | Guess the Object | up to 1200 | same |
| `deepavali_diya` | Light the Diyas | up to 2000 | same |

The three Deepavali games share one scoreboard class and are registered by
`supabase/migrations/202611040002_deepavali_games.sql`, which also explains
their scoring and limits. Scoring lives in
`lib/features/deepavali/domain/deepavali_scores.dart`; a test
(`test/features/deepavali/scores_test.dart`) reads the migration and fails if
a best possible score no longer fits its limits.

Only wins in the diya game are ranked, and not in relaxed mode. The local
"best time" per level is unchanged; the leaderboard ranks points.

## 11. Connecting a separate application

Another Flutter app can share this backend if it is intentionally part of the
same game platform:

1. use the same Supabase URL and publishable key;
2. add that app's Android package/signing fingerprints and iOS bundle ID as
   Google OAuth clients;
3. keep the same Web OAuth client as `serverClientId` and configure it in the
   Supabase Google provider;
4. authenticate the player with Supabase;
5. use a registered game slug and the RPC contracts above;
6. never ship a service-role key.

Sharing a Supabase project means sharing the account namespace. A Google user
will have one Supabase UUID and profile across all participating games. If that
is not desired, use a separate Supabase project instead.

The backend does not trust package names as authorization. Its actual trust
boundary is the valid Supabase user session plus RLS/RPC validation. OAuth
package and signing configuration protects the native Google login flow.

## 12. Character avatar Storage

Bucket: `player-avatars`

- public read access is intentional because leaderboard images are public;
- maximum object size is 2 MB;
- accepted types are JPEG, PNG, WebP, HEIC, and HEIF;
- object path is `<auth.uid()>/character-avatar`;
- insert/update/delete policies require ownership of that UUID folder.

The client captures at up to 640×640 and quality 82 to reduce upload time and
memory pressure. A version query parameter is added to the saved public URL so
replacing an avatar does not leave stale cached artwork.

Do not place private media in this bucket. Create a separate private bucket and
signed-URL policy for any future private asset.

## 13. Failure behavior

| Failure | Expected behavior |
|---|---|
| Google chooser cancelled | Stay signed out and show cancellation feedback |
| Google client misconfigured | Show an actionable configuration error |
| Supabase token exchange fails | Do not enter protected app; allow retry |
| Profile load fails | Show retry state at the root gate |
| Score RPC/network fails | Queue locally; do not claim the score is saved |
| Duplicate result retry | Return current totals without incrementing again |
| Invalid or implausible score | Reject with no table changes |
| Leaderboard empty | Return an empty page and render an empty state |
| Session expires | Auth stream returns to the login gate |

## 14. Anti-cheat boundary

The current backend is tamper-resistant, not cheat-proof. It prevents direct
stat overwrites, cross-user writes, duplicate inflation, impossible configured
bounds, implausibly fast scores, and submission floods. However, a modified
client can still fabricate a plausible score and duration.

Stronger protection requires an authoritative protocol, for example:

1. server issues a short-lived signed game-session ID;
2. client uploads a bounded event/checkpoint stream;
3. server validates sequence, timing, and game-specific rules;
4. session can be finalized exactly once;
5. suspicious results are quarantined rather than immediately ranked.

Each game needs its own validator because scoring rules differ. Do not market a
client-reported leaderboard as fully cheat-proof.

## 15. Operational checklist

Before enabling a new game in production:

- [ ] Add the game through a reviewed migration.
- [ ] Set realistic score, duration, and timing limits.
- [ ] Use a stable slug in both repository and `GameResult`.
- [ ] Generate one UUID at game start and reuse it for retries.
- [ ] Submit only from the terminal completed-game path.
- [ ] Test zero, lower, higher, duplicate, offline, and rejected scores.
- [ ] Test pagination and the current-player highlight.
- [ ] Confirm no widget performs direct Supabase table writes.
- [ ] Confirm no service-role key or OAuth secret is in the app/repository.
- [ ] Run `flutter analyze` and `flutter test`.
- [ ] Validate Google login and live RPCs on a physical device.

## 16. Known limitations

- Results are client reported and therefore not fully cheat-proof.
- The hourly rate limit is implemented in PostgreSQL, not at the network edge.
- The avatar bucket is public by design.
- Account avatar cleanup is best effort before account deletion; operational
  storage cleanup should monitor for orphaned objects.
- Google OAuth and live score delivery require device-level integration tests;
  widget tests cannot complete the native account chooser.

## 17. Related developer guides

- **[Game Developer Integration Guide](file:///Users/glb-blr-m9/Desktop/Karnataka-Rajotsav-And-Diwali-Celebration-App/docs/GAME_DEVELOPER_INTEGRATION_GUIDE.md)**:
  Detailed instructions and copy-paste code examples for using the player's camera selfie avatar, connecting new game modules, submitting scores, and building leaderboards.


