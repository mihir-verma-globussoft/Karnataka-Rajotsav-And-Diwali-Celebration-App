-- Registers the Rajyotsava quiz on the shared games backend, so its rounds
-- get per-player best scores, rank and a leaderboard like Flappy Bird.
-- The app sends rounds as game slug 'rajyotsava_quiz'
-- (lib/features/rajyotsava/data/supabase_quiz_scoreboard.dart). Rounds sent
-- before this migration is applied are kept on the phone and sent again.
--
-- Scoring (lib/features/rajyotsava/domain/quiz_scores.dart): a round is 10
-- questions, at most 4 of them hard. A correct answer earns 100 (easy),
-- 150 (medium) or 200 (hard) points, plus up to 50 for answering within
-- 10 seconds. Best possible round: 4 x 250 + 6 x 200 = 2200.
--
-- Limits:
--   max_score 2500             the best round with some headroom
--   max_duration_ms 3600000    one hour; a round left open longer is not sent
--   minimum_ms_per_score 3     a perfect, fastest round still needs
--                              (2200 - 5) x 3 ms = 6.6 s, about 0.7 s per
--                              question, which only a bot could beat

begin;

insert into public.games (
  slug,
  display_name,
  max_score,
  max_duration_ms,
  minimum_ms_per_score
) values (
  'rajyotsava_quiz',
  'Rajyotsava Quiz',
  2500,
  3600000,
  3
)
on conflict (slug) do update set
  display_name = excluded.display_name,
  max_score = excluded.max_score,
  max_duration_ms = excluded.max_duration_ms,
  minimum_ms_per_score = excluded.minimum_ms_per_score,
  is_active = true;

commit;
