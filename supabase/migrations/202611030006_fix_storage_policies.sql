begin;

-- In migration 003, storage policies on storage.objects checked owner_id
-- (which can be null depending on storage version) and omitted a SELECT policy,
-- causing upsert/read failures.
-- This migration ensures SELECT is allowed and UPDATE/DELETE check foldername.

drop policy if exists player_avatars_select on storage.objects;
create policy player_avatars_select
on storage.objects for select
using (bucket_id = 'player-avatars');

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
  and (storage.foldername(name))[1] = (select auth.uid())::text
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
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

update storage.buckets
set file_size_limit = 5242880,
    allowed_mime_types = null,
    public = true
where id = 'player-avatars';

commit;

