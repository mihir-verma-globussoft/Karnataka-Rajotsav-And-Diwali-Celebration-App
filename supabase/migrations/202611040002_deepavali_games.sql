-- Registers the three Deepavali games on the shared games backend, so each
-- gets per-player best scores, rank and a leaderboard like Flappy Bird.
-- The app sends games under these slugs
-- (lib/features/deepavali/data/supabase_deepavali_scoreboard.dart). Games
-- sent before this migration is applied are kept on the phone and sent again.
--
-- Scoring (lib/features/deepavali/domain/deepavali_scores.dart):
--
--   deepavali_quiz   10 questions. 100 per correct answer, plus up to 50 per
--                    correct answer for speed (all ten in under 10 s each on
--                    average). Best possible: 1000 + 500 = 1500.
--   deepavali_guess  8 objects, scored the same way. Best possible:
--                    800 + 400 = 1200.
--   deepavali_diya   Only wins count (every diya lit), and not relaxed mode.
--                    500 (Gentle), 1000 (Breezy) or 1500 (Stormy), plus up to
--                    500 for the time left on the clock. Best possible: 2000.
--
-- Limits (the server rejects a score if duration < (score - 5) x ms/score):
--   max_duration_ms 3600000   one hour; a game left open longer is not sent.
--   quiz / guess: 3 ms per point. A perfect, fastest quiz still needs
--                 (1500 - 5) x 3 ms = 4.5 s, 0.45 s a question.
--   diya:         1 ms per point. The best score (2000) needs 2 s to light
--                 12 diyas; Gentle's top score (1000) needs about 1 s.
--
-- Choose the limits from measured play; loosen them here, not in the app.

begin;

insert into public.games (
  slug,
  display_name,
  max_score,
  max_duration_ms,
  minimum_ms_per_score
) values
  ('deepavali_quiz',  'Deepavali Quiz',   1600, 3600000, 3),
  ('deepavali_guess', 'Guess the Object', 1300, 3600000, 3),
  ('deepavali_diya',  'Light the Diyas',  2000, 3600000, 1)
on conflict (slug) do update set
  display_name = excluded.display_name,
  max_score = excluded.max_score,
  max_duration_ms = excluded.max_duration_ms,
  minimum_ms_per_score = excluded.minimum_ms_per_score,
  is_active = true;

commit;
