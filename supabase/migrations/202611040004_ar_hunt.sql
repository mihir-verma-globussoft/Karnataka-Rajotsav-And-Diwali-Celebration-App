begin;

-- Habba Hunt: an office AR hunt. Admins place diyas and Kannada flags relative
-- to printed start-point posters; players walk around and collect them.
--
-- Points live in the shared player_game_stats row (high_score is the running
-- total), so the existing get_leaderboard and get_my_stats RPCs work unchanged.
insert into public.games (
  slug,
  display_name,
  max_score,
  max_duration_ms,
  minimum_ms_per_score
) values (
  'ar_hunt',
  'Habba Hunt',
  1000000,
  21600000,
  0
)
on conflict (slug) do update set
  display_name = excluded.display_name,
  is_active = true;

create table if not exists public.ar_hunt_items (
  id uuid primary key default gen_random_uuid(),
  -- The start-point poster this item's coordinates are measured from.
  zone text not null check (zone ~ '^[a-z0-9_]{1,16}$'),
  kind text not null check (kind in ('diya', 'flag')),
  -- Metres from the poster, in a gravity-aligned frame. See poster_lock.dart.
  x double precision not null check (abs(x) <= 200),
  y double precision not null check (abs(y) <= 200),
  z double precision not null check (abs(z) <= 200),
  hint text check (char_length(hint) <= 120),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  -- Soft delete: points already earned from a removed item are kept.
  removed_at timestamptz
);

create index if not exists ar_hunt_items_live_idx
  on public.ar_hunt_items (created_at)
  where removed_at is null;

create table if not exists public.ar_hunt_finds (
  item_id uuid not null references public.ar_hunt_items(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  points integer not null check (points > 0),
  found_at timestamptz not null default now(),
  primary key (item_id, user_id)
);

create index if not exists ar_hunt_finds_user_idx
  on public.ar_hunt_finds (user_id, found_at desc);

-- Players join with just a name (Supabase anonymous sign-in), so there is no
-- email to recognise an organiser by. They unlock admin with a PIN instead.
-- Separate from admin_users on purpose: that table also controls the app-wide
-- event countdown, which a hunt PIN must never reach.
create table if not exists public.ar_hunt_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.ar_hunt_settings (
  id boolean primary key default true check (id),
  admin_pin_salt text not null,
  admin_pin_hash text not null
);

create table if not exists public.ar_hunt_pin_tries (
  user_id uuid not null references auth.users(id) on delete cascade,
  tried_at timestamptz not null default now()
);

create index if not exists ar_hunt_pin_tries_user_idx
  on public.ar_hunt_pin_tries (user_id, tried_at desc);

-- Clients only ever go through the RPCs below.
alter table public.ar_hunt_items enable row level security;
alter table public.ar_hunt_finds enable row level security;
alter table public.ar_hunt_admins enable row level security;
alter table public.ar_hunt_settings enable row level security;
alter table public.ar_hunt_pin_tries enable row level security;
revoke all on public.ar_hunt_items from public, anon, authenticated;
revoke all on public.ar_hunt_finds from public, anon, authenticated;
revoke all on public.ar_hunt_admins from public, anon, authenticated;
revoke all on public.ar_hunt_settings from public, anon, authenticated;
revoke all on public.ar_hunt_pin_tries from public, anon, authenticated;

create or replace function public.ar_hunt_is_admin(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists(select 1 from admin_users a where a.user_id = p_user)
    or exists(select 1 from ar_hunt_admins a where a.user_id = p_user);
$$;

-- Run once from the Supabase SQL editor: select public.ar_set_admin_pin('...');
-- Until then nobody can unlock admin. Clients cannot call this.
create or replace function public.ar_set_admin_pin(p_pin text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  salt text := gen_random_uuid()::text;
begin
  if p_pin !~ '^[0-9]{6,12}$' then
    raise exception 'The PIN must be 6 to 12 digits' using errcode = '22023';
  end if;
  insert into ar_hunt_settings (id, admin_pin_salt, admin_pin_hash)
  values (true, salt, encode(sha256(convert_to(salt || p_pin, 'UTF8')), 'hex'))
  on conflict (id) do update set
    admin_pin_salt = excluded.admin_pin_salt,
    admin_pin_hash = excluded.admin_pin_hash;
end;
$$;

-- Makes the caller an admin if the PIN is right. Five wrong tries in ten
-- minutes lock that player out for a while, so it cannot simply be guessed.
create or replace function public.ar_admin_unlock(p_pin text)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  caller uuid := auth.uid();
  settings public.ar_hunt_settings;
begin
  if caller is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if (
    select count(*) from ar_hunt_pin_tries t
    where t.user_id = caller and t.tried_at > now() - interval '10 minutes'
  ) >= 5 then
    raise exception 'too_many_attempts' using errcode = 'P0001';
  end if;
  select * into settings from ar_hunt_settings where id;
  if settings.admin_pin_hash is null or settings.admin_pin_hash <> encode(
    sha256(convert_to(settings.admin_pin_salt || coalesce(p_pin, ''), 'UTF8')),
    'hex'
  ) then
    insert into ar_hunt_pin_tries (user_id) values (caller);
    return false;
  end if;
  delete from ar_hunt_pin_tries where user_id = caller;
  insert into ar_hunt_admins (user_id) values (caller)
  on conflict (user_id) do nothing;
  return true;
end;
$$;

-- Everything the hub and the AR view need for the signed-in player.
create or replace function public.ar_hunt_state()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'is_admin', public.ar_hunt_is_admin(caller),
    'is_active', coalesce(
      (select g.is_active from games g where g.slug = 'ar_hunt'),
      false
    ),
    'items', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', i.id,
            'zone', i.zone,
            'kind', i.kind,
            'x', i.x,
            'y', i.y,
            'z', i.z,
            'hint', i.hint,
            'found', f.item_id is not null
          )
          order by i.created_at
        )
        from ar_hunt_items i
        left join ar_hunt_finds f
          on f.item_id = i.id and f.user_id = caller
        where i.removed_at is null
      ),
      '[]'::jsonb
    )
  );
end;
$$;

-- Awards a find once per player. Safe to retry after a lost connection.
create or replace function public.ar_collect_item(p_item_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  caller uuid := auth.uid();
  base_points constant integer := 10;
  first_finder_bonus constant integer := 5;
  -- Two items can sit close together, but not closer than this to walk between.
  minimum_gap constant interval := interval '3 seconds';
  last_find timestamptz;
  was_first boolean;
  awarded integer;
  total integer;
begin
  if caller is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not exists(
    select 1 from games g where g.slug = 'ar_hunt' and g.is_active
  ) then
    raise exception 'hunt_closed' using errcode = 'P0001';
  end if;

  -- Locking the item serialises its finds, so exactly one player can be first.
  perform 1
  from ar_hunt_items i
  where i.id = p_item_id and i.removed_at is null
  for update;
  if not found then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;

  select coalesce(s.high_score, 0) into total
  from player_game_stats s
  where s.user_id = caller and s.game_slug = 'ar_hunt';
  total := coalesce(total, 0);

  -- Admins know where everything is, so they can test without ranking.
  if public.ar_hunt_is_admin(caller) then
    return jsonb_build_object(
      'points', 0,
      'first_finder', false,
      'already_found', false,
      'is_admin', true,
      'total_points', total
    );
  end if;

  if exists(
    select 1 from ar_hunt_finds f
    where f.item_id = p_item_id and f.user_id = caller
  ) then
    return jsonb_build_object(
      'points', 0,
      'first_finder', false,
      'already_found', true,
      'is_admin', false,
      'total_points', total
    );
  end if;

  select max(f.found_at) into last_find
  from ar_hunt_finds f
  where f.user_id = caller;
  if last_find is not null and now() - last_find < minimum_gap then
    raise exception 'too_fast' using errcode = 'P0001';
  end if;

  was_first := not exists(
    select 1 from ar_hunt_finds f where f.item_id = p_item_id
  );
  awarded := base_points + case when was_first then first_finder_bonus else 0 end;

  insert into ar_hunt_finds (item_id, user_id, points)
  values (p_item_id, caller, awarded);

  insert into player_game_stats as s (
    user_id, game_slug, high_score, total_games, total_score,
    high_score_achieved_at, updated_at
  )
  values (caller, 'ar_hunt', awarded, 1, awarded, now(), now())
  on conflict (user_id, game_slug) do update set
    high_score = s.high_score + excluded.high_score,
    total_games = s.total_games + 1,
    total_score = s.total_score + excluded.total_score,
    high_score_achieved_at = now(),
    updated_at = now()
  returning s.high_score into total;

  return jsonb_build_object(
    'points', awarded,
    'first_finder', was_first,
    'already_found', false,
    'is_admin', false,
    'total_points', total
  );
end;
$$;

create or replace function public.ar_admin_place_item(
  p_zone text,
  p_kind text,
  p_x double precision,
  p_y double precision,
  p_z double precision,
  p_hint text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  caller uuid := auth.uid();
  item public.ar_hunt_items;
begin
  if not public.ar_hunt_is_admin(caller) then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  insert into ar_hunt_items (zone, kind, x, y, z, hint, created_by)
  values (p_zone, p_kind, p_x, p_y, p_z, nullif(trim(p_hint), ''), caller)
  returning * into item;
  return jsonb_build_object(
    'id', item.id,
    'zone', item.zone,
    'kind', item.kind,
    'x', item.x,
    'y', item.y,
    'z', item.z,
    'hint', item.hint,
    'found', false
  );
end;
$$;

create or replace function public.ar_admin_remove_item(p_item_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.ar_hunt_is_admin(auth.uid()) then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  update ar_hunt_items
  set removed_at = now()
  where id = p_item_id and removed_at is null;
end;
$$;

revoke all on function public.ar_hunt_is_admin(uuid) from public, anon, authenticated;
revoke all on function public.ar_set_admin_pin(text) from public, anon, authenticated;
revoke all on function public.ar_admin_unlock(text) from public, anon;
revoke all on function public.ar_hunt_state() from public, anon;
revoke all on function public.ar_collect_item(uuid) from public, anon;
revoke all on function public.ar_admin_place_item(
  text, text, double precision, double precision, double precision, text
) from public, anon;
revoke all on function public.ar_admin_remove_item(uuid) from public, anon;

grant execute on function public.ar_admin_unlock(text) to authenticated;
grant execute on function public.ar_hunt_state() to authenticated;
grant execute on function public.ar_collect_item(uuid) to authenticated;
grant execute on function public.ar_admin_place_item(
  text, text, double precision, double precision, double precision, text
) to authenticated;
grant execute on function public.ar_admin_remove_item(uuid) to authenticated;

commit;
