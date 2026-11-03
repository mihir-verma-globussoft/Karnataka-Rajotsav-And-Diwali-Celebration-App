begin;

-- The first migration established the Flappy Bird launch schema. This upgrade
-- makes the score service reusable by every game module in this application.
create table if not exists public.games (
  slug text primary key check (slug ~ '^[a-z0-9_]{3,48}$'),
  display_name text not null check (char_length(display_name) between 3 and 80),
  is_active boolean not null default true,
  max_score integer not null default 1000000 check (max_score >= 0),
  max_duration_ms integer not null default 21600000 check (max_duration_ms > 0),
  minimum_ms_per_score integer not null default 0
    check (minimum_ms_per_score >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.games (
  slug, display_name, max_score, max_duration_ms, minimum_ms_per_score
) values ('flappy_bird', 'Flappy Bird', 1000000, 21600000, 450)
on conflict (slug) do nothing;

alter table public.player_stats rename to player_game_stats;
alter table public.player_game_stats
  add column if not exists game_slug text not null default 'flappy_bird'
  references public.games(slug) on delete restrict;
alter table public.player_game_stats
  drop constraint if exists player_stats_pkey;
alter table public.player_game_stats
  drop constraint if exists player_game_stats_pkey;
alter table public.player_game_stats
  add primary key (user_id, game_slug);

alter table public.game_results
  add column if not exists game_slug text not null default 'flappy_bird'
  references public.games(slug) on delete restrict;

drop index if exists public.player_stats_leaderboard_idx;
create index if not exists player_game_stats_leaderboard_idx
  on public.player_game_stats (
    game_slug,
    high_score desc,
    high_score_achieved_at asc nulls last,
    user_id asc
  );
create index if not exists game_results_game_user_completed_idx
  on public.game_results (game_slug, user_id, completed_at desc);

drop trigger if exists player_stats_set_updated_at on public.player_game_stats;
drop trigger if exists player_game_stats_set_updated_at on public.player_game_stats;
create trigger player_game_stats_set_updated_at
before update on public.player_game_stats
for each row execute function public.set_updated_at();

alter table public.games enable row level security;
alter table public.player_game_stats enable row level security;

drop policy if exists games_select_active on public.games;
create policy games_select_active on public.games for select to authenticated
using (is_active);

drop policy if exists player_stats_select_own on public.player_game_stats;
drop policy if exists player_game_stats_select_own on public.player_game_stats;
create policy player_game_stats_select_own on public.player_game_stats
for select to authenticated using ((select auth.uid()) = user_id);

revoke insert, update, delete on public.games from anon, authenticated;
revoke insert, update, delete on public.player_game_stats from anon, authenticated;
grant select on public.games, public.player_game_stats to authenticated;

-- Replace game-specific RPCs with parameterized, still identity-derived RPCs.
drop function if exists public.get_my_stats();
create function public.get_my_stats(p_game_slug text default 'flappy_bird')
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with ranked as (
    select
      stats.user_id,
      row_number() over (
        order by stats.high_score desc,
          stats.high_score_achieved_at asc nulls last, stats.user_id asc
      ) as global_rank
    from public.player_game_stats as stats
    where stats.game_slug = p_game_slug
  )
  select jsonb_build_object(
    'high_score', stats.high_score,
    'total_games', stats.total_games,
    'total_score', stats.total_score,
    'global_rank', ranked.global_rank
  )
  from public.player_game_stats as stats
  join ranked using (user_id)
  where stats.user_id = auth.uid() and stats.game_slug = p_game_slug;
$$;

drop function if exists public.get_leaderboard(integer, integer);
create function public.get_leaderboard(
  p_game_slug text default 'flappy_bird',
  p_offset integer default 0,
  p_limit integer default 20
)
returns table (
  rank bigint, user_id uuid, username text, avatar_url text, high_score integer
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
  select row_number() over (
      order by stats.high_score desc,
        stats.high_score_achieved_at asc nulls last, stats.user_id asc
    ) as rank,
    stats.user_id, profile.username, profile.avatar_url, stats.high_score
  from public.player_game_stats as stats
  join public.profiles as profile on profile.id = stats.user_id
  where stats.game_slug = p_game_slug
  order by stats.high_score desc,
    stats.high_score_achieved_at asc nulls last, stats.user_id asc
  offset greatest(coalesce(p_offset, 0), 0)
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
end;
$$;

drop function if exists public.submit_game_result(uuid, integer, integer, timestamptz);
create function public.submit_game_result(
  p_game_id uuid,
  p_game_slug text,
  p_score integer,
  p_duration_ms integer,
  p_started_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  caller uuid := auth.uid();
  game_config public.games%rowtype;
  inserted_id uuid;
  previous_high_score integer;
  updated_stats public.player_game_stats%rowtype;
begin
  if caller is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_game_id is null or p_game_slug is null or p_score is null
     or p_duration_ms is null or p_started_at is null then
    raise exception 'Invalid game result' using errcode = '22023';
  end if;
  select * into game_config from public.games
  where slug = p_game_slug and is_active;
  if not found then
    raise exception 'Unknown or inactive game' using errcode = '22023';
  end if;
  if p_score < 0 or p_score > game_config.max_score
     or p_duration_ms < 0 or p_duration_ms > game_config.max_duration_ms then
    raise exception 'Game result outside accepted bounds' using errcode = '22023';
  end if;
  if game_config.minimum_ms_per_score > 0 and p_score > 5
     and p_duration_ms < ((p_score - 5) * game_config.minimum_ms_per_score) then
    raise exception 'Score is not plausible for the reported duration'
      using errcode = '22023';
  end if;
  if p_started_at > now() + interval '5 minutes'
     or p_started_at < now() - interval '30 days' then
    raise exception 'Game timestamp outside accepted bounds' using errcode = '22023';
  end if;
  if (select count(*) from public.game_results
      where user_id = caller and game_slug = p_game_slug
        and completed_at > now() - interval '1 hour') >= 120 then
    raise exception 'Score submission rate limit exceeded' using errcode = 'P0001';
  end if;

  insert into public.player_game_stats (user_id, game_slug) values (caller, p_game_slug)
  on conflict (user_id, game_slug) do nothing;
  select high_score into previous_high_score from public.player_game_stats
  where user_id = caller and game_slug = p_game_slug for update;
  insert into public.game_results (id, user_id, game_slug, score, duration_ms, started_at)
  values (p_game_id, caller, p_game_slug, p_score, p_duration_ms, p_started_at)
  on conflict (id) do nothing returning id into inserted_id;
  if inserted_id is null then
    select * into updated_stats from public.player_game_stats
    where user_id = caller and game_slug = p_game_slug;
    return jsonb_build_object('high_score', updated_stats.high_score,
      'total_games', updated_stats.total_games, 'total_score', updated_stats.total_score,
      'is_new_high_score', false, 'already_submitted', true);
  end if;
  update public.player_game_stats set
    high_score = greatest(high_score, p_score),
    total_games = total_games + 1,
    total_score = total_score + p_score,
    high_score_achieved_at = case when p_score > high_score then now()
      else high_score_achieved_at end
  where user_id = caller and game_slug = p_game_slug
  returning * into updated_stats;
  return jsonb_build_object('high_score', updated_stats.high_score,
    'total_games', updated_stats.total_games, 'total_score', updated_stats.total_score,
    'is_new_high_score', p_score > previous_high_score, 'already_submitted', false);
end;
$$;

revoke all on function public.get_my_stats(text) from public, anon;
revoke all on function public.get_leaderboard(text, integer, integer) from public, anon;
revoke all on function public.submit_game_result(uuid, text, integer, integer, timestamptz)
  from public, anon;
grant execute on function public.get_my_stats(text) to authenticated;
grant execute on function public.get_leaderboard(text, integer, integer) to authenticated;
grant execute on function public.submit_game_result(uuid, text, integer, integer, timestamptz)
  to authenticated;

commit;
