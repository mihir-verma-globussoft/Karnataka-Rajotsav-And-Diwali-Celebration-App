begin;

-- The prize screen on the Games tab shows the caller's own scoreboard: one
-- row per active game with their personal best, games played and the
-- normalised points that game contributes to the combined leaderboard.
-- Uses the same formula as get_global_arcade_leaderboard, so the rows add up
-- to the player's combined score.
create or replace function public.get_my_game_scores()
returns table (
  game_slug text,
  display_name text,
  best_score bigint,
  games_played bigint,
  score_ceiling integer,
  points bigint
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    game.slug as game_slug,
    game.display_name,
    coalesce(stats.high_score, 0)::bigint as best_score,
    coalesce(stats.total_games, 0)::bigint as games_played,
    game.global_score_ceiling as score_ceiling,
    coalesce(round(
      least(stats.high_score, game.global_score_ceiling)::numeric
      * 1000 / game.global_score_ceiling
    ), 0)::bigint as points
  from public.games as game
  left join public.player_game_stats as stats
    on stats.game_slug = game.slug and stats.user_id = auth.uid()
  where game.is_active and auth.uid() is not null
  order by game.display_name;
$$;

revoke all on function public.get_my_game_scores() from public, anon;
grant execute on function public.get_my_game_scores() to authenticated;

commit;
