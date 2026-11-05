begin;

-- Every game keeps its own raw score and own-game leaderboard. The arcade
-- leaderboard instead gives each game an equal 1,000-point contribution at
-- its verified competitive ceiling, so larger raw point scales do not dominate.
alter table public.games
  add column if not exists global_score_ceiling integer not null default 1000
  check (global_score_ceiling > 0);

-- These ceilings reflect the scoring rules in the app, rather than the
-- server-side anti-cheat maxima, which intentionally include headroom.
-- The Hunt ceiling represents a full standard event of 50 base-point finds;
-- organisers can adjust it before an event with a different size.
update public.games
set global_score_ceiling = case slug
  when 'flappy_bird' then 100
  when 'pacman' then 200
  when 'deepavali_quiz' then 1500
  when 'deepavali_guess' then 1200
  when 'deepavali_diya' then 2000
  when 'rajyotsava_quiz' then 2200
  when 'ar_hunt' then 500
  else global_score_ceiling
end;

-- Keep the existing RPC field names for already-installed app versions. The
-- `total_best_score` field is now the sum of normalized per-game bests.
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
      coalesce(sum(
        round(
          least(stats.high_score, game.global_score_ceiling)::numeric
          * 1000 / game.global_score_ceiling
        )
      ), 0)::bigint as total_best_score,
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
      coalesce(sum(
        round(
          least(stats.high_score, game.global_score_ceiling)::numeric
          * 1000 / game.global_score_ceiling
        )
      ), 0)::bigint as total_best_score,
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
    profile.id as user_id,
    profile.username,
    coalesce(profile.character_avatar_url, profile.avatar_url) as avatar_url,
    aggregated.total_best_score
  from aggregated
  join public.profiles as profile on profile.id = aggregated.user_id
  order by aggregated.total_best_score desc,
    aggregated.best_achieved_at asc nulls last,
    aggregated.user_id asc
  offset greatest(p_offset, 0)
  limit least(greatest(p_limit, 1), 100);
end;
$$;

revoke all on function public.get_global_arcade_stats() from public, anon;
revoke all on function public.get_global_arcade_leaderboard(integer, integer)
  from public, anon;
grant execute on function public.get_global_arcade_stats() to authenticated;
grant execute on function public.get_global_arcade_leaderboard(integer, integer)
  to authenticated;

commit;
