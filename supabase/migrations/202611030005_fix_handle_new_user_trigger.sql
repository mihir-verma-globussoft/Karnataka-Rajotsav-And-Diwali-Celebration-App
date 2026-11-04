begin;

-- In migration 002, table public.player_stats was renamed to player_game_stats
-- with a composite primary key (user_id, game_slug).
-- Update handle_new_user() trigger function to insert into player_game_stats.
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

  insert into public.player_game_stats (user_id, game_slug)
  values (new.id, 'flappy_bird')
  on conflict (user_id, game_slug) do nothing;
  return new;
end;
$$;

commit;

