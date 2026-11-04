begin;

alter table public.profiles
  add column if not exists character_avatar_url text;

revoke update on public.profiles from anon, authenticated;
grant update (username, character_avatar_url) on public.profiles to authenticated;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
) values (
  'player-avatars',
  'player-avatars',
  true,
  2097152,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists player_avatars_insert_own on storage.objects;
create policy player_avatars_insert_own
on storage.objects for insert to authenticated
with check (
  bucket_id = 'player-avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists player_avatars_update_own on storage.objects;
create policy player_avatars_update_own
on storage.objects for update to authenticated
using (
  bucket_id = 'player-avatars'
  and owner_id = (select auth.uid())::text
)
with check (
  bucket_id = 'player-avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists player_avatars_delete_own on storage.objects;
create policy player_avatars_delete_own
on storage.objects for delete to authenticated
using (
  bucket_id = 'player-avatars'
  and owner_id = (select auth.uid())::text
);

create or replace function public.get_leaderboard(
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
    stats.user_id,
    profile.username,
    coalesce(profile.character_avatar_url, profile.avatar_url) as avatar_url,
    stats.high_score
  from public.player_game_stats as stats
  join public.profiles as profile on profile.id = stats.user_id
  where stats.game_slug = p_game_slug
  order by stats.high_score desc,
    stats.high_score_achieved_at asc nulls last, stats.user_id asc
  offset greatest(coalesce(p_offset, 0), 0)
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
end;
$$;

commit;
