begin;

create extension if not exists pgcrypto;

-- 1. If harshsharmavardhan6749@gmail.com already exists in auth.users, update password & ensure email is confirmed
update auth.users
set encrypted_password = crypt('harshsharmavardhan6749@gmail.com', gen_salt('bf')),
    email_confirmed_at = coalesce(email_confirmed_at, now()),
    updated_at = now()
where email = 'harshsharmavardhan6749@gmail.com';

-- 2. If user does not exist in auth.users yet, create with this email & password
insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
select
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'harshsharmavardhan6749@gmail.com',
  crypt('harshsharmavardhan6749@gmail.com', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"name":"Harsh Vardhan Sharma"}'::jsonb,
  now(),
  now()
where not exists (
  select 1 from auth.users where email = 'harshsharmavardhan6749@gmail.com'
);

-- 3. Register user in public.admin_users table so they have admin privileges
insert into public.admin_users (user_id, email, role)
select id, email, 'admin' from auth.users where email = 'harshsharmavardhan6749@gmail.com'
on conflict (email) do update set user_id = excluded.user_id, role = 'admin';

commit;
