begin;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null check (char_length(username) between 3 and 24),
  email text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.player_stats (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  high_score integer not null default 0 check (high_score >= 0),
  total_games integer not null default 0 check (total_games >= 0),
  total_score bigint not null default 0 check (total_score >= 0),
  high_score_achieved_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.game_results (
  id uuid primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  score integer not null check (score >= 0),
  duration_ms integer not null check (duration_ms >= 0),
  started_at timestamptz not null,
  completed_at timestamptz not null default now()
);

create index if not exists player_stats_leaderboard_idx
  on public.player_stats (
    high_score desc,
    high_score_achieved_at asc nulls last,
    user_id asc
  );
create index if not exists game_results_user_completed_idx
  on public.game_results (user_id, completed_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists player_stats_set_updated_at on public.player_stats;
create trigger player_stats_set_updated_at
before update on public.player_stats
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  candidate text;
begin
  candidate := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Player'
  );
  candidate := left(candidate, 24);
  if char_length(candidate) < 3 then
    candidate := 'Player';
  end if;

  insert into public.profiles (id, username, email, avatar_url, created_at)
  values (
    new.id,
    candidate,
    new.email,
    coalesce(
      new.raw_user_meta_data ->> 'avatar_url',
      new.raw_user_meta_data ->> 'picture'
    ),
    coalesce(new.created_at, now())
  )
  on conflict (id) do nothing;

  insert into public.player_stats (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

insert into public.profiles (id, username, email, avatar_url, created_at)
select
  user_row.id,
  case
    when char_length(candidate.value) >= 3 then left(candidate.value, 24)
    else 'Player'
  end,
  user_row.email,
  coalesce(
    user_row.raw_user_meta_data ->> 'avatar_url',
    user_row.raw_user_meta_data ->> 'picture'
  ),
  user_row.created_at
from auth.users as user_row
cross join lateral (
  select coalesce(
    nullif(trim(user_row.raw_user_meta_data ->> 'full_name'), ''),
    nullif(trim(user_row.raw_user_meta_data ->> 'name'), ''),
    nullif(split_part(coalesce(user_row.email, ''), '@', 1), ''),
    'Player'
  ) as value
) as candidate
on conflict (id) do nothing;

insert into public.player_stats (user_id)
select id from public.profiles
on conflict (user_id) do nothing;

alter table public.profiles enable row level security;
alter table public.player_stats enable row level security;
alter table public.game_results enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

drop policy if exists player_stats_select_own on public.player_stats;
create policy player_stats_select_own
on public.player_stats for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists game_results_select_own on public.game_results;
create policy game_results_select_own
on public.game_results for select
to authenticated
using ((select auth.uid()) = user_id);

revoke insert, delete on public.profiles from anon, authenticated;
revoke update on public.profiles from anon, authenticated;
grant update (username) on public.profiles to authenticated;
revoke insert, update, delete on public.player_stats from anon, authenticated;
revoke insert, update, delete on public.game_results from anon, authenticated;
grant select on public.profiles, public.player_stats, public.game_results
  to authenticated;

create or replace function public.get_my_stats()
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
        order by
          stats.high_score desc,
          stats.high_score_achieved_at asc nulls last,
          stats.user_id asc
      ) as global_rank
    from public.player_stats as stats
  )
  select jsonb_build_object(
    'high_score', stats.high_score,
    'total_games', stats.total_games,
    'total_score', stats.total_score,
    'global_rank', ranked.global_rank
  )
  from public.player_stats as stats
  join ranked using (user_id)
  where stats.user_id = auth.uid();
$$;

create or replace function public.get_leaderboard(
  p_offset integer default 0,
  p_limit integer default 20
)
returns table (
  rank bigint,
  user_id uuid,
  username text,
  avatar_url text,
  high_score integer
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
  select
    row_number() over (
      order by
        stats.high_score desc,
        stats.high_score_achieved_at asc nulls last,
        stats.user_id asc
    ) as rank,
    stats.user_id,
    profile.username,
    profile.avatar_url,
    stats.high_score
  from public.player_stats as stats
  join public.profiles as profile on profile.id = stats.user_id
  order by
    stats.high_score desc,
    stats.high_score_achieved_at asc nulls last,
    stats.user_id asc
  offset greatest(coalesce(p_offset, 0), 0)
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
end;
$$;

create or replace function public.submit_game_result(
  p_game_id uuid,
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
  inserted_id uuid;
  previous_high_score integer;
  updated_stats public.player_stats%rowtype;
begin
  if caller is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_game_id is null or p_score is null or p_duration_ms is null
     or p_started_at is null then
    raise exception 'Invalid game result' using errcode = '22023';
  end if;
  if p_score < 0 or p_score > 1000000
     or p_duration_ms < 0 or p_duration_ms > 21600000 then
    raise exception 'Game result outside accepted bounds' using errcode = '22023';
  end if;
  if p_score > 5 and p_duration_ms < ((p_score - 5) * 450) then
    raise exception 'Score is not plausible for the reported duration'
      using errcode = '22023';
  end if;
  if p_started_at > now() + interval '5 minutes'
     or p_started_at < now() - interval '30 days' then
    raise exception 'Game timestamp outside accepted bounds'
      using errcode = '22023';
  end if;
  if (
    select count(*)
    from public.game_results
    where user_id = caller and completed_at > now() - interval '1 hour'
  ) >= 120 then
    raise exception 'Score submission rate limit exceeded'
      using errcode = 'P0001';
  end if;

  insert into public.player_stats (user_id)
  values (caller)
  on conflict (user_id) do nothing;

  select high_score into previous_high_score
  from public.player_stats
  where user_id = caller
  for update;

  insert into public.game_results (
    id, user_id, score, duration_ms, started_at
  ) values (
    p_game_id, caller, p_score, p_duration_ms, p_started_at
  )
  on conflict (id) do nothing
  returning id into inserted_id;

  if inserted_id is null then
    select * into updated_stats
    from public.player_stats
    where user_id = caller;
    return jsonb_build_object(
      'high_score', updated_stats.high_score,
      'total_games', updated_stats.total_games,
      'total_score', updated_stats.total_score,
      'is_new_high_score', false,
      'already_submitted', true
    );
  end if;

  update public.player_stats
  set
    high_score = greatest(high_score, p_score),
    total_games = total_games + 1,
    total_score = total_score + p_score,
    high_score_achieved_at = case
      when p_score > high_score then now()
      else high_score_achieved_at
    end
  where user_id = caller
  returning * into updated_stats;

  return jsonb_build_object(
    'high_score', updated_stats.high_score,
    'total_games', updated_stats.total_games,
    'total_score', updated_stats.total_score,
    'is_new_high_score', p_score > previous_high_score,
    'already_submitted', false
  );
end;
$$;

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  delete from auth.users where id = caller;
end;
$$;

revoke all on function public.get_my_stats() from public, anon;
revoke all on function public.get_leaderboard(integer, integer) from public, anon;
revoke all on function public.submit_game_result(uuid, integer, integer, timestamptz)
  from public, anon;
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.get_my_stats() to authenticated;
grant execute on function public.get_leaderboard(integer, integer) to authenticated;
grant execute on function public.submit_game_result(uuid, integer, integer, timestamptz)
  to authenticated;
grant execute on function public.delete_own_account() to authenticated;

commit;
