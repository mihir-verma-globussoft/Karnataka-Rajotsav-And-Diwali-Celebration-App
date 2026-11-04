begin;

-- A player has a Flappy Bird stats row immediately because the original user
-- trigger creates it. Other games create their row on first submission. Keep
-- their pre-first-game dashboard useful by returning zero totals instead of a
-- null RPC response.
create or replace function public.get_my_stats(
  p_game_slug text default 'flappy_bird'
)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with ranked as (
    select
      stats.user_id,
      stats.high_score,
      stats.total_games,
      stats.total_score,
      row_number() over (
        order by stats.high_score desc,
          stats.high_score_achieved_at asc nulls last,
          stats.user_id asc
      ) as global_rank
    from public.player_game_stats as stats
    where stats.game_slug = p_game_slug
  ), own_stats as (
    select * from ranked where user_id = auth.uid()
  )
  select jsonb_build_object(
    'high_score', coalesce((select high_score from own_stats), 0),
    'total_games', coalesce((select total_games from own_stats), 0),
    'total_score', coalesce((select total_score from own_stats), 0),
    'global_rank', (select global_rank from own_stats)
  );
$$;

revoke all on function public.get_my_stats(text) from public, anon;
grant execute on function public.get_my_stats(text) to authenticated;

commit;
