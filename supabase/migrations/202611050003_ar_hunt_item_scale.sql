-- Habba Hunt: an organiser can choose how big each diya or flag is when placing
-- it. 1 is the standard size. The six-argument place function stays, unchanged,
-- so older apps keep working and get the standard size.
begin;

alter table public.ar_hunt_items
  add column if not exists scale double precision not null default 1
  check (scale between 0.25 and 4);

create or replace function public.ar_admin_place_item(
  p_zone text,
  p_kind text,
  p_x double precision,
  p_y double precision,
  p_z double precision,
  p_scale double precision,
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
  insert into ar_hunt_items (zone, kind, x, y, z, hint, scale, created_by)
  values (p_zone, p_kind, p_x, p_y, p_z, nullif(trim(p_hint), ''), p_scale, caller)
  returning * into item;
  return jsonb_build_object(
    'id', item.id,
    'zone', item.zone,
    'kind', item.kind,
    'x', item.x,
    'y', item.y,
    'z', item.z,
    'hint', item.hint,
    'scale', item.scale,
    'found', false
  );
end;
$$;

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
            'scale', i.scale,
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

revoke all on function public.ar_admin_place_item(
  text, text, double precision, double precision, double precision, double precision, text
) from public, anon;
grant execute on function public.ar_admin_place_item(
  text, text, double precision, double precision, double precision, double precision, text
) to authenticated;

commit;
