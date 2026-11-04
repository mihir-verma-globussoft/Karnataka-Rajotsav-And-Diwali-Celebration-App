// Runs every Supabase migration in order on an in-memory Postgres, then checks
// the Habba Hunt rules. Needs no server or Docker:
//   cd apps/ar_hunt/tool && npm i --no-save @electric-sql/pglite && node test_migration.mjs
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PGlite } from '@electric-sql/pglite';

const dir = join(dirname(fileURLToPath(import.meta.url)), '../../../supabase/migrations');
const db = new PGlite();

// The small part of Supabase the migrations rely on.
await db.exec(`
  create role anon; create role authenticated; create role service_role;
  create schema auth; create schema storage; create schema extensions;
  create table auth.users (
    id uuid primary key default gen_random_uuid(), email text unique,
    raw_user_meta_data jsonb default '{}', created_at timestamptz default now()
  );
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('test.uid', true), '')::uuid $$;
  create table storage.buckets (
    id text primary key, name text, public boolean, file_size_limit bigint,
    allowed_mime_types text[]
  );
  create table storage.objects (
    id uuid primary key default gen_random_uuid(), bucket_id text, name text, owner uuid, owner_id text
  );
  alter table storage.objects enable row level security;
  create function storage.foldername(name text) returns text[] language sql as
    $$ select string_to_array(name, '/') $$;
  create publication supabase_realtime;
`);

// 0008 writes a real account's password into auth.users; not needed here.
const files = readdirSync(dir).filter((f) => f.endsWith('.sql') && !f.includes('set_admin_user_credentials')).sort();
for (const f of files) {
  try {
    await db.exec(readFileSync(join(dir, f), 'utf8'));
  } catch (e) {
    throw new Error(`${f}: ${e.message}`);
  }
}
console.log(`applied ${files.length} migrations`);

const user = async (email) =>
  (await db.query('insert into auth.users (email) values ($1) returning id', [email])).rows[0].id;
const admin = await user('admin@test.dev');
const asha = await user('asha@test.dev');
const ravi = await user('ravi@test.dev');
await db.query('insert into public.admin_users (user_id, email) values ($1, $2)', [admin, 'admin@test.dev']);

// Runs one RPC as a signed-in client: non-superuser, with auth.uid() set.
async function as(uid, sql, params = []) {
  await db.exec(`set test.uid = '${uid ?? ''}'; set role authenticated;`);
  try {
    return (await db.query(sql, params)).rows;
  } finally {
    await db.exec('reset role;');
  }
}
const fails = async (fn, pattern) => assert.rejects(fn, pattern);
const place = (uid, zone = 'a', kind = 'diya') =>
  as(uid, 'select public.ar_admin_place_item($1, $2, 1, 0.5, -2, $3) as r', [zone, kind, ' by the coffee machine ']);
const collect = async (uid, id) =>
  (await as(uid, 'select public.ar_collect_item($1) as r', [id]))[0].r;
const state = async (uid) => (await as(uid, 'select public.ar_hunt_state() as r'))[0].r;
// Moves a player's last find into the past, so the speed limit doesn't apply.
const wait = (uid) =>
  db.query("update public.ar_hunt_finds set found_at = now() - interval '1 minute' where user_id = $1", [uid]);

// Only admins place items; values are validated.
await fails(() => place(asha), /Administrator access required/);
await fails(() => place(null), /Administrator access required/);
const first = (await place(admin))[0].r;
assert.equal(first.hint, 'by the coffee machine');
assert.equal(first.found, false);
await fails(() => place(admin, 'BAD ZONE'), /check constraint/);
await fails(() => place(admin, 'a', 'lamp'), /check constraint/);
const second = (await place(admin, 'b', 'flag'))[0].r;

// Tables are closed to clients; only the RPCs work.
await fails(() => as(asha, 'select * from public.ar_hunt_items'), /permission denied/);
await fails(() => as(asha, "insert into public.ar_hunt_finds (item_id, user_id, points) values ($1, $2, 999)", [first.id, asha]), /permission denied/);

// State reflects each player, and admins are told apart.
assert.equal((await state(asha)).is_admin, false);
assert.equal((await state(admin)).is_admin, true);
assert.equal((await state(asha)).items.length, 2);
await fails(() => as(null, 'select public.ar_hunt_state()'), /Authentication required/);

// First finder earns the bonus, a retry never scores twice.
let r = await collect(asha, first.id);
assert.deepEqual([r.points, r.first_finder, r.already_found, r.total_points], [15, true, false, 15]);
await wait(asha);
r = await collect(asha, first.id);
assert.deepEqual([r.points, r.already_found, r.total_points], [0, true, 15]);
assert.equal((await state(asha)).items.find((i) => i.id === first.id).found, true);
assert.equal((await state(ravi)).items.find((i) => i.id === first.id).found, false);

// The second finder gets base points only.
r = await collect(ravi, first.id);
assert.deepEqual([r.points, r.first_finder, r.total_points], [10, false, 10]);

// A find straight after another one is refused, and costs nothing.
await fails(() => collect(ravi, second.id), /too_fast/);
await wait(ravi);
r = await collect(ravi, second.id);
assert.deepEqual([r.points, r.first_finder, r.total_points], [15, true, 25]);

// Admins can test the collect flow without entering the leaderboard.
r = await collect(admin, first.id);
assert.deepEqual([r.is_admin, r.points], [true, 0]);

// The shared leaderboard and stats RPCs see the hunt, ordered by points.
const board = await as(asha, "select * from public.get_leaderboard('ar_hunt', 0, 50)");
assert.deepEqual(board.map((b) => [b.user_id, b.high_score, Number(b.rank)]), [[ravi, 25, 1], [asha, 15, 2]]);
const mine = (await as(asha, "select public.get_my_stats('ar_hunt') as r"))[0].r;
assert.deepEqual([mine.high_score, mine.total_games, mine.global_rank], [15, 1, 2]);

// Hunt points never leak into another game's board.
const flappy = await as(asha, "select * from public.get_leaderboard('flappy_bird', 0, 50)");
assert.ok(flappy.every((b) => b.high_score === 0));

// Removing an item hides it but keeps points already earned.
await fails(() => as(asha, 'select public.ar_admin_remove_item($1)', [first.id]), /Administrator access required/);
await as(admin, 'select public.ar_admin_remove_item($1)', [first.id]);
assert.equal((await state(asha)).items.length, 1);
await wait(asha);
await fails(() => collect(asha, first.id), /item_not_found/);
assert.equal((await as(asha, "select public.get_my_stats('ar_hunt') as r"))[0].r.high_score, 15);

// Closing the hunt stops scoring but keeps everything readable.
await db.exec("update public.games set is_active = false where slug = 'ar_hunt'");
await wait(asha);
await fails(() => collect(asha, second.id), /hunt_closed/);
assert.equal((await state(asha)).is_active, false);

// A player joining with only a name: no email, and the trigger makes a profile.
const named = (await db.query(
  `insert into auth.users (raw_user_meta_data) values ('{"name": "Sharuk"}') returning id`,
)).rows[0].id;
const board2 = await as(asha, "select * from public.get_leaderboard('ar_hunt', 0, 50)");
assert.ok(board2.every((b) => b.user_id !== named), 'no points yet, so not ranked yet');
assert.equal((await db.query('select username, email from public.profiles where id = $1', [named])).rows[0].username, 'Sharuk');
await db.exec("update public.games set is_active = true where slug = 'ar_hunt'");
r = await collect(named, second.id);
assert.deepEqual([r.points, r.first_finder], [10, false]);
const withName = await as(asha, "select * from public.get_leaderboard('ar_hunt', 0, 50)");
assert.equal(withName.find((b) => b.user_id === named).username, 'Sharuk');

// Admin by PIN: nothing unlocks it until one is set, and clients cannot set it.
const unlock = async (uid, pin) =>
  (await as(uid, 'select public.ar_admin_unlock($1) as r', [pin]))[0].r;
const organiser = await user('organiser@test.dev');
assert.equal(await unlock(organiser, '123456'), false);
await fails(() => as(organiser, "select public.ar_set_admin_pin('123456')"), /permission denied/);
await fails(() => as(organiser, 'select * from public.ar_hunt_settings'), /permission denied/);
await fails(() => as(organiser, 'select public.ar_hunt_is_admin($1)', [organiser]), /permission denied/);
await fails(() => db.query("select public.ar_set_admin_pin('12')"), /6 to 12 digits/);
await fails(() => db.query("select public.ar_set_admin_pin('abcdef')"), /6 to 12 digits/);
await db.query("select public.ar_set_admin_pin('123456')");
assert.notEqual((await db.query('select admin_pin_hash from public.ar_hunt_settings')).rows[0].admin_pin_hash, '123456');

assert.equal(await unlock(organiser, '000000'), false);
assert.equal((await state(organiser)).is_admin, false);
assert.equal(await unlock(organiser, '123456'), true, 'a wrong try does not block the right PIN');
assert.equal((await state(organiser)).is_admin, true);
const pinPlaced = (await place(organiser, 'c', 'diya'))[0].r;
assert.equal(pinPlaced.zone, 'c');
await as(organiser, 'select public.ar_admin_remove_item($1)', [pinPlaced.id]);
r = await collect(organiser, second.id);
assert.deepEqual([r.is_admin, r.points], [true, 0], 'PIN admins do not score either');

// A hunt PIN never reaches the app-wide event controls.
assert.equal((await db.query('select count(*)::int as n from public.admin_users where user_id = $1', [organiser])).rows[0].n, 0);
await fails(
  () => as(organiser, "select public.admin_update_event_config('x', now(), false, false)"),
  /Administrator access required/,
);

// Guessing gets locked out after five wrong tries, even with the right PIN.
const guesser = await user('guesser@test.dev');
for (let i = 0; i < 5; i++) assert.equal(await unlock(guesser, `00000${i}`), false);
await fails(() => unlock(guesser, '123456'), /too_many_attempts/);
assert.equal((await state(guesser)).is_admin, false);
await db.query("update public.ar_hunt_pin_tries set tried_at = now() - interval '11 minutes' where user_id = $1", [guesser]);
assert.equal(await unlock(guesser, '123456'), true);

console.log('all Habba Hunt database rules hold');
