-- PulseQR demo seed — DEMO PROJECTS ONLY.
-- Creates three confirmed demo auth users and their linked, active profiles:
--
--   student@pulseqr.demo   / PulseQR-Demo-2026!  (student,  BIT/BT/24/ME/009)
--   lecturer@pulseqr.demo  / PulseQR-Demo-2026!  (lecturer, FAC-DEMO-0001)
--   admin@pulseqr.demo     / PulseQR-Demo-2026!  (admin,    ADM-DEMO-0001)
--
-- plus two UNCLAIMED registrar-roster rows so the Create Account flow can be
-- demonstrated end-to-end (signing up with one of these emails claims the roster
-- entry via the handle_new_user trigger):
--
--   newstudent@pulseqr.demo  -> student  (BIT/BT/24/ME/042, Chipo Banda)
--   newlecturer@pulseqr.demo -> lecturer (FAC-2026-0042, Limbani Phiri)
--
-- auth.users.encrypted_password uses pgcrypto's bcrypt (crypt/gen_salt('bf')).
-- confirmed_at and identities.email are GENERATED columns in current Supabase and
-- must not be inserted. Run with: psql $DATABASE_URL -f supabase/seed.sql

begin;

do $$
declare
  demo record;
  uid uuid;
begin
  for demo in
    select * from (values
      ('student@pulseqr.demo',  'Tadala Chirwa',     'student'::public.user_role,  'BIT/BT/24/ME/009'),
      ('lecturer@pulseqr.demo', 'Limbani Phiri',     'lecturer'::public.user_role, 'FAC-DEMO-0001'),
      ('admin@pulseqr.demo',    'Demo Administrator','admin'::public.user_role,    'ADM-DEMO-0001')
    ) as t(email, full_name, role, school_id)
  loop
    if exists (select 1 from auth.users where lower(email) = lower(demo.email)) then
      continue;
    end if;

    insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, is_anonymous)
    values (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            demo.email, crypt('PulseQR-Demo-2026!', gen_salt('bf')), now(), now(), now(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            jsonb_build_object('full_name', demo.full_name), false, false)
    returning id into uid;

    insert into auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (uid::text, uid,
            jsonb_build_object('sub', uid::text, 'email', demo.email, 'email_verified', true, 'phone_verified', false),
            'email', now(), now(), now());

    insert into public.profiles (auth_user_id, school_id, school_email, full_name, role, active)
    values (uid, demo.school_id, demo.email, demo.full_name, demo.role, true)
    on conflict (school_id) do nothing;
  end loop;
end $$;

insert into public.profiles (school_id, school_email, full_name, role, active) values
  ('BIT/BT/24/ME/042', 'newstudent@pulseqr.demo',  'Chipo Banda',   'student',  false),
  ('FAC-2026-0042', 'newlecturer@pulseqr.demo', 'Limbani Phiri', 'lecturer', false)
on conflict (school_id) do nothing;

commit;

-- Repair (2026-11-21): this project's auth.instances was empty, which made
-- GoTrue fail every sign-in with {"code":"unexpected_failure","message":"Database error querying schema"}.
-- Hosted projects normally carry exactly one instance row. Idempotent guard:
insert into auth.instances (id, uuid, raw_base_config, created_at, updated_at)
select '00000000-0000-0000-0000-000000000000', gen_random_uuid(), '{}', now(), now()
where not exists (select 1 from auth.instances);
