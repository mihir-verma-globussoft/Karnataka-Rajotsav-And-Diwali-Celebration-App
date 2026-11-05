begin;

-- One global arcade board: each game contributes its personal best once.
-- This intentionally does not use player_game_stats.total_score, which is the
-- sum of every attempt and would let repeated plays inflate a global ranking.
create or replace function public.get_global_arcade_stats()
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with aggregated as (
    select
      stats.user_id,
      coalesce(sum(stats.high_score), 0)::bigint as total_best_score,
      coalesce(sum(stats.total_games), 0)::bigint as total_games,
      min(stats.high_score_achieved_at) as best_achieved_at
    from public.player_game_stats as stats
    join public.games as game on game.slug = stats.game_slug
    group by stats.user_id
  ), ranked as (
    select
      aggregated.*,
      row_number() over (
        order by aggregated.total_best_score desc,
          aggregated.best_achieved_at asc nulls last,
          aggregated.user_id asc
      ) as global_rank
    from aggregated
  )
  select jsonb_build_object(
    'total_best_score', coalesce(
      (select total_best_score from ranked where user_id = auth.uid()), 0
    ),
    'total_games', coalesce(
      (select total_games from ranked where user_id = auth.uid()), 0
    ),
    'global_rank', (
      select global_rank from ranked where user_id = auth.uid()
    )
  );
$$;

create or replace function public.get_global_arcade_leaderboard(
  p_offset integer default 0,
  p_limit integer default 20
)
returns table (
  rank bigint,
  user_id uuid,
  username text,
  avatar_url text,
  total_best_score bigint
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  return query
  with aggregated as (
    select
      stats.user_id,
      coalesce(sum(stats.high_score), 0)::bigint as total_best_score,
      min(stats.high_score_achieved_at) as best_achieved_at
    from public.player_game_stats as stats
    join public.games as game on game.slug = stats.game_slug
    group by stats.user_id
  )
  select
    row_number() over (
      order by aggregated.total_best_score desc,
        aggregated.best_achieved_at asc nulls last,
        aggregated.user_id asc
    ) as rank,
    aggregated.user_id,
    profile.username,
    coalesce(profile.character_avatar_url, profile.avatar_url) as avatar_url,
    aggregated.total_best_score
  from aggregated
  join public.profiles as profile on profile.id = aggregated.user_id
  order by aggregated.total_best_score desc,
    aggregated.best_achieved_at asc nulls last,
    aggregated.user_id asc
  offset greatest(coalesce(p_offset, 0), 0)
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
end;
$$;

revoke all on function public.get_global_arcade_stats() from public, anon;
revoke all on function public.get_global_arcade_leaderboard(integer, integer)
  from public, anon;
grant execute on function public.get_global_arcade_stats() to authenticated;
grant execute on function public.get_global_arcade_leaderboard(integer, integer)
  to authenticated;

commit;
