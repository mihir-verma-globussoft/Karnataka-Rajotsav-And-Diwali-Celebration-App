-- Registers Pac-Man on the shared games backend, so its games get per-player
-- best scores, rank, last score and a leaderboard like Flappy Bird.
-- The app sends games as game slug 'pacman'
-- (lib/features/pacman_game/data/supabase_pacman_scoreboard.dart). Games
-- played before this migration is applied are kept on the phone and sent
-- again.
--
-- Scoring: one point per diya lit. The maze has fewer than 200 cells, so a
-- perfect game is under 200 points.
--
-- Limits:
--   max_score 500              the best game with a lot of headroom
--   max_duration_ms 3600000    one hour; a game left open longer is not sent
--   minimum_ms_per_score 150   the player moves one cell every 220 ms (a turn
--                              can bring a step forward by about half that)
--                              and lights at most one diya per move, so a
--                              score of N needs well over (N - 5) x 150 ms

begin;

insert into public.games (
  slug,
  display_name,
  max_score,
  max_duration_ms,
  minimum_ms_per_score
) values (
  'pacman',
  'Pac-Man',
  500,
  3600000,
  150
)
on conflict (slug) do update set
  display_name = excluded.display_name,
  max_score = excluded.max_score,
  max_duration_ms = excluded.max_duration_ms,
  minimum_ms_per_score = excluded.minimum_ms_per_score,
  is_active = true;

commit;
