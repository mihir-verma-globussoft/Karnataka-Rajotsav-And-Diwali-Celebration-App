begin;

-- ============================================================================
-- 1. Event Configurations Table
-- ============================================================================
create table if not exists public.event_configurations (
  id text primary key,
  event_name text not null,
  target_time timestamptz not null,
  is_active boolean not null default true,
  test_mode boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by text
);

-- Seed default global celebration event
insert into public.event_configurations (
  id,
  event_name,
  target_time,
  is_active,
  test_mode,
  updated_by
) values (
  'global_diwali',
  'Karnataka Rajyotsava & Deepavali Celebration 2026',
  '2026-11-04 18:00:00+05:30',
  true,
  false,
  'system_bootstrap'
)
on conflict (id) do update set
  event_name = excluded.event_name,
  is_active = excluded.is_active;

-- ============================================================================
-- 2. Administrator Users Table
-- ============================================================================
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  role text not null default 'admin',
  created_at timestamptz not null default now()
);

-- ============================================================================
-- 3. Row Level Security on Event Configurations & Admin Users
-- ============================================================================
alter table public.event_configurations enable row level security;
alter table public.admin_users enable row level security;

-- Mobile clients have strictly SELECT permissions on active event configurations
drop policy if exists event_configurations_select on public.event_configurations;
create policy event_configurations_select on public.event_configurations
  for select to anon, authenticated using (true);

-- Mutations are completely revoked from client roles
revoke insert, update, delete on public.event_configurations from anon, authenticated;
grant select on public.event_configurations to anon, authenticated;

-- Admin users can be read by authenticated users to verify admin status
drop policy if exists admin_users_select_own on public.admin_users;
create policy admin_users_select_own on public.admin_users
  for select to authenticated using (auth.uid() = user_id);

revoke insert, update, delete on public.admin_users from anon, authenticated;
grant select on public.admin_users to authenticated;

-- ============================================================================
-- 4. Enable Supabase Realtime Replication for Event Configuration
-- ============================================================================
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'event_configurations'
  ) then
    alter publication supabase_realtime add table public.event_configurations;
  end if;
exception
  when undefined_object then
    null;
end $$;

-- ============================================================================
-- 5. Trusted Server Time & Gate Status RPC (Read-Only for Mobile & Public)
-- ============================================================================
create or replace function public.get_event_gate_status(p_event_id text default 'global_diwali')
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  config record;
  caller uuid := auth.uid();
  is_admin boolean := false;
  event_started boolean := false;
begin
  select * into config from public.event_configurations where id = p_event_id;
  if not found then
    return jsonb_build_object(
      'server_time', now(),
      'id', p_event_id,
      'event_name', 'Event Not Found',
      'target_time', now(),
      'is_active', false,
      'test_mode', false,
      'is_started', false,
      'is_admin', false
    );
  end if;

  if caller is not null then
    select exists(select 1 from public.admin_users where user_id = caller) into is_admin;
  end if;

  -- An event is started only if:
  -- 1. is_active is TRUE
  -- 2. Current server time has passed the target time
  -- 3. If test_mode is TRUE, only verified admins may unlock
  if config.is_active and now() >= config.target_time then
    if config.test_mode then
      event_started := is_admin;
    else
      event_started := true;
    end if;
  else
    event_started := false;
  end if;

  return jsonb_build_object(
    'server_time', now(),
    'id', config.id,
    'event_name', config.event_name,
    'target_time', config.target_time,
    'is_active', config.is_active,
    'test_mode', config.test_mode,
    'is_started', event_started,
    'is_admin', is_admin
  );
end;
$$;

revoke all on function public.get_event_gate_status(text) from public;
grant execute on function public.get_event_gate_status(text) to anon, authenticated;

-- ============================================================================
-- 6. Protected Administrative RPC (For Web Admin Dashboard)
-- ============================================================================
create or replace function public.admin_update_event_config(
  p_event_id text,
  p_target_time timestamptz,
  p_is_active boolean,
  p_test_mode boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  caller uuid := auth.uid();
  admin_email text;
begin
  if caller is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select email into admin_email from public.admin_users where user_id = caller;
  if not found then
    raise exception 'Unauthorized: Administrator access required' using errcode = '42501';
  end if;

  update public.event_configurations set
    target_time = p_target_time,
    is_active = p_is_active,
    test_mode = p_test_mode,
    updated_at = now(),
    updated_by = admin_email
  where id = p_event_id;

  return jsonb_build_object(
    'success', true,
    'updated_at', now(),
    'updated_by', admin_email
  );
end;
$$;

revoke all on function public.admin_update_event_config(text, timestamptz, boolean, boolean) from public, anon;
grant execute on function public.admin_update_event_config(text, timestamptz, boolean, boolean) to authenticated;

-- ============================================================================
-- 7. Storage Bucket & Policies for Player Avatars
-- ============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('player-avatars', 'player-avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = true,
  file_size_limit = 5242880;

-- Bucket read access is public
drop policy if exists "Public read avatars" on storage.objects;
create policy "Public read avatars" on storage.objects
  for select using (bucket_id = 'player-avatars');

-- User-scoped upload, update and delete
drop policy if exists "Users upload own avatar" on storage.objects;
create policy "Users upload own avatar" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'player-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users update own avatar" on storage.objects;
create policy "Users update own avatar" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'player-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users delete own avatar" on storage.objects;
create policy "Users delete own avatar" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'player-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

commit;

