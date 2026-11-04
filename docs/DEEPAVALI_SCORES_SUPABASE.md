# Deepavali game scores: Supabase setup and handoff

For the teammate who owns the Supabase project and the final scoreboard.
The Deepavali tab now sends its game scores to the shared games backend. The
app side is finished and merged. **Nothing ranks until the migration below is
applied to the Supabase project.** Until then the phones keep the scores and
send them later, so no score is lost by waiting.

Background on the backend itself: [GAMING_BACKEND.md](GAMING_BACKEND.md).

## 1. What you need to do

1. Apply `supabase/migrations/202611040002_deepavali_games.sql`.
2. Check that the migrations before it are applied too. The Rajyotsava quiz
   migration `202611040001_rajyotsava_quiz_game.sql` is also still open.
3. Run the checks in section 5.

```sh
supabase link --project-ref <project-ref>
supabase db push --dry-run        # review first: this is a shared project
supabase db push --include-all
```

Or paste the file into the SQL editor once. It is safe to run twice: it
inserts with `on conflict ... do update`, and it only touches the `games` table.

It does **not** change any table, function, policy or Storage bucket. It only
adds three rows to `public.games`.

## 2. The three games

| Slug | Game in the app | Best possible | `max_score` | `minimum_ms_per_score` | `max_duration_ms` |
|---|---|---|---|---|---|
| `deepavali_quiz` | Deepavali Quiz (10 questions) | 1500 | 1600 | 3 | 3600000 |
| `deepavali_guess` | Guess the Object (8 objects) | 1200 | 1300 | 3 | 3600000 |
| `deepavali_diya` | Light the Diyas | 2000 | 2000 | 1 | 3600000 |

Slugs must never be renamed or reused once shipped (see GAMING_BACKEND.md §5).

## 3. How each score is worked out

The backend ranks one whole number per game, higher is better. The app turns
each result into points (code: `lib/features/deepavali/domain/deepavali_scores.dart`).

**Quiz and Guess the Object**

- 100 points per correct answer.
- Plus a speed bonus of up to 50 points per correct answer. It is full if the
  whole game takes no time and falls to nothing at 10 seconds per question or
  slower.
- Quiz: `1000 + 500 = 1500` at best. Guess: `800 + 400 = 1200` at best.

**Light the Diyas**

- Only a win counts (all 12 diyas lit at once). A loss is never sent.
- Relaxed mode (no timer, no wind) is never sent.
- Base points by level: Gentle 500, Breezy 1000, Stormy 1500 (harder levels are
  worth more).
- Plus up to 500 for time left on the clock. Best: `1500 + 500 = 2000`.
- `duration_ms` is the play time, with paused time excluded.

All three levels share one leaderboard (`deepavali_diya`), so a Stormy win
always outranks a Gentle win by design.

## 4. Why the limits are what they are

The server rejects a score when `duration_ms < (score - 5) x minimum_ms_per_score`
(`submit_game_result`, migration `…0002_generalize_game_backend.sql`).

- Quiz and Guess use 3 ms per point. A perfect, instant quiz still needs
  `(1500 - 5) x 3 ms = 4.5 s`, which is 0.45 s a question and only a bot beats
  it. A real player (about 2 s a question) is far above the line.
- Diya uses 1 ms per point. The top score (2000) needs about 2 s to light 12
  diyas; a human takes at least 3 s.
- `max_score` has a little headroom above the best possible score.
- `max_duration_ms` is one hour. The app does not send a game left open longer.

If real play shows these are too strict or too loose, change the numbers in
the migration (or a new one), not in the app. The app's own scoring would have
to change together with them. A test, `test/features/deepavali/scores_test.dart`,
reads the migration file and fails if a best possible score no longer fits its
`max_score`.

## 5. Checks after applying

Run in the SQL editor:

```sql
-- 1. All three games exist and are active.
select slug, display_name, max_score, max_duration_ms,
       minimum_ms_per_score, is_active
from public.games
where slug like 'deepavali_%'
order by slug;
-- Expect 3 rows: deepavali_diya, deepavali_guess, deepavali_quiz, all active.
```

Then on a phone or emulator signed in with a real account (run the app with
`--dart-define-from-file=.env`), play each game to the end and check:

```sql
-- 2. The result arrived.
select game_slug, score, duration_ms, started_at, completed_at
from public.game_results
where game_slug like 'deepavali_%'
order by completed_at desc
limit 10;

-- 3. The aggregate and rank.
select user_id, game_slug, high_score, total_games, total_score
from public.player_game_stats
where game_slug like 'deepavali_%'
order by game_slug, high_score desc;
```

In the app, the result screen of each game should show a **Leaderboard** card
that says "Saved to the leaderboard." (or "New personal best!"), your rank, and
the top 5 players. If it says "Saved on this phone. It will reach the
leaderboard when you are back online." the send failed. Most likely the
migration is not applied yet, the phone is offline, or the score was rejected;
the app keeps it and retries each time a game starts.

Things worth trying once:

- Play the same game twice: `total_games` goes up by 2, `high_score` is the
  better one.
- Turn on airplane mode, finish a game, then go online and start another game.
  The first result should arrive (retry happens when a game starts), exactly
  once.
- Diya in relaxed mode, and a lost diya game: no row appears.

## 6. How the app talks to Supabase

Nothing new on the server. The Deepavali code calls the three existing
functions through `supabase.rpc(...)` with the player's own session:

| Function | When | Parameters the app sends |
|---|---|---|
| `submit_game_result` | A game ends | `p_game_id` (UUID made when the game started), `p_game_slug`, `p_score`, `p_duration_ms`, `p_started_at` |
| `get_my_stats` | Result screen | `p_game_slug` |
| `get_leaderboard` | Result screen | `p_game_slug`, `p_offset` 0, `p_limit` 5 |

- The app never sends a user id. Identity is `auth.uid()` on the server.
- `p_game_id` is created once per game and reused for every retry, so
  `submit_game_result` counts a game once even if the app sends it several times
  (it returns `already_submitted: true`).
- Failed sends are stored on the phone per player and retried at the start of
  the next game. Games older than 29 days are dropped (the server accepts up to
  30), and at most 50 are kept.
- The app keeps a game queued on **any** error, because an unregistered slug
  and a rejected score both return error code `22023`. So applying the migration
  late is safe.

Server rules that apply as usual: at most 120 accepted results per player per
game per hour, start time no more than 5 minutes in the future or 30 days in
the past.

## 7. For the final scoreboard

- Each game has its own leaderboard and its own point scale. The points are
  **not** normalised across games: the three Deepavali games top out at 1500,
  1200 and 2000, Rajyotsava's quiz at 2200, and Flappy Bird counts pipes.
  Adding the raw high scores together would favour the games with bigger scales.
- Decide how the combined board should weigh them (for example rank per game
  and add the ranks, or scale each game by its `max_score` from the `games`
  table). That is your call; the app does not do it.
- Per-player data you can build on: `player_game_stats` (one row per player and
  game: `high_score`, `total_games`, `total_score`, `high_score_achieved_at`).
  `get_leaderboard` is per game only, so a combined board needs a new function
  or view. Follow the existing rules: `security definer`, fixed
  `search_path`, never return emails, grant to `authenticated` only.
- Scores are reported by the app, so they are tamper-resistant but not
  cheat-proof (GAMING_BACKEND.md §14).

## 8. Rolling back

To stop accepting Deepavali scores without losing history:

```sql
update public.games set is_active = false where slug like 'deepavali_%';
```

The app keeps the games working and queues scores on the phones. Setting
`is_active` back to `true` lets them through.

## 9. Where things are in the app

| What | File |
|---|---|
| Scoring and the score types | `lib/features/deepavali/domain/deepavali_scores.dart` |
| Supabase calls and the offline queue | `lib/features/deepavali/data/supabase_deepavali_scoreboard.dart` |
| Leaderboard card on the result screens | `lib/features/deepavali/presentation/widgets/scoreboard_card.dart` |
| Where each game sends its result | `presentation/state/quiz_notifier.dart`, `guess_notifier.dart`, `game_notifier.dart` |
| Tests | `test/features/deepavali/scores_test.dart`, `scores_screens_test.dart` |
| Decision record | `docs/DECISIONS.md`, ADR-012 |
