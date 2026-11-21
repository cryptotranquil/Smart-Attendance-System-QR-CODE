-- PulseQR core schema (canonical).
-- Applied live to the "QR code" project (ref: vjnczngqljtvwjgmpgbo) via migration
-- "recreate_pulseqr_schema" on 2026-11-21.
--
-- This migration is destructive by design: it drops the legacy public tables
-- (users / profiles / departments / programs / courses / class_sessions /
-- attendance / system_alerts / system_settings) and rebuilds the schema cleanly:
--   * full teaching-catalogue schema (departments -> attendance_records)
--   * school-provisioned public.profiles claimed by the matching auth user
--     via the handle_new_user trigger (roster claim on sign-up)
--   * system_settings preserved with its four original rows
--   * row level security everywhere; teaching tables are not client-accessible
--     until scoped policies are added
--
-- Demo auth users are NOT created here; see supabase/seed.sql.

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user() cascade;
drop function if exists public.is_admin() cascade;
drop function if exists public.update_updated_at_column() cascade;

drop table if exists public.attendance cascade;
drop table if exists public.class_sessions cascade;
drop table if exists public.courses cascade;
drop table if exists public.departments cascade;
drop table if exists public.programs cascade;
drop table if exists public.system_alerts cascade;
drop table if exists public.system_settings cascade;
drop table if exists public.users cascade;
drop table if exists public.profiles cascade;
drop table if exists public.programmes cascade;
drop table if exists public.terms cascade;
drop table if exists public.course_offerings cascade;
drop table if exists public.enrollments cascade;
drop table if exists public.venues cascade;
drop table if exists public.timetable_slots cascade;
drop table if exists public.sessions cascade;
drop table if exists public.attendance_records cascade;

drop type if exists public.user_role cascade;
drop type if exists public.session_type cascade;
drop type if exists public.session_status cascade;
drop type if exists public.attendance_status cascade;

-- Enums
create type public.user_role as enum ('student','lecturer','admin');
create type public.session_type as enum ('in_person','online','hybrid');
create type public.session_status as enum ('scheduled','open','closed','cancelled','not_held');
create type public.attendance_status as enum ('present','late','absent','excused');

-- Catalogue
create table public.departments (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  head_of_department text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.programmes (
  id uuid primary key default gen_random_uuid(),
  department_id uuid not null references public.departments,
  code text unique not null,
  name text not null,
  years integer not null default 4,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Profiles (school-provisioned; claimed by the matching auth user on sign-up)
create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users on delete set null,
  school_id text unique not null,
  school_email text not null,
  full_name text not null,
  role public.user_role not null,
  programme_id uuid references public.programmes,
  active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index profiles_school_email on public.profiles (lower(school_email));
create index profiles_role on public.profiles (role);
create index profiles_auth_user_id on public.profiles (auth_user_id);

-- Terms & teaching structure
create table public.terms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  starts_on date not null,
  ends_on date not null check (ends_on >= starts_on)
);
create table public.courses (
  id uuid primary key default gen_random_uuid(),
  department_id uuid not null references public.departments,
  code text unique not null,
  title text not null,
  programme_id uuid references public.programmes,
  year integer,
  semester integer,
  credit_hours integer,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.course_offerings (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses,
  term_id uuid not null references public.terms,
  lecturer_id uuid not null references public.profiles
);
create table public.enrollments (
  offering_id uuid not null references public.course_offerings,
  student_id uuid not null references public.profiles,
  primary key (offering_id, student_id)
);
create table public.venues (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  radius_m integer not null check (radius_m > 0)
);
create table public.timetable_slots (
  id uuid primary key default gen_random_uuid(),
  offering_id uuid not null references public.course_offerings,
  venue_id uuid references public.venues,
  day_of_week integer not null check (day_of_week between 1 and 7),
  starts_at time not null,
  ends_at time not null check (ends_at > starts_at),
  kind public.session_type not null,
  check (kind = 'online' or venue_id is not null)
);
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  slot_id uuid references public.timetable_slots,
  offering_id uuid not null references public.course_offerings,
  venue_id uuid references public.venues,
  scheduled_at timestamptz not null,
  opened_at timestamptz,
  closed_at timestamptz,
  kind public.session_type not null,
  status public.session_status not null default 'scheduled',
  replaces_session_id uuid references public.sessions,
  policy_snapshot jsonb not null default '{}',
  reason text,
  unique (slot_id, scheduled_at)
);
create table public.attendance_records (
  session_id uuid not null references public.sessions,
  student_id uuid not null references public.profiles,
  status public.attendance_status not null,
  recorded_at timestamptz not null default now(),
  distance_m double precision,
  accuracy_m double precision,
  flags text[] not null default '{}',
  primary key (session_id, student_id)
);

-- System settings (admin / service-role only)
create table public.system_settings (
  id uuid primary key default gen_random_uuid(),
  setting_key text unique not null,
  setting_value text not null,
  description text,
  updated_by uuid,
  updated_at timestamptz not null default now()
);
insert into public.system_settings (setting_key, setting_value, description) values
  ('qr_time_limit_minutes', '15', 'Default time limit in minutes for marking attendance via QR code'),
  ('attendance_threshold_percentage', '75', 'Attendance percentage threshold for generating alerts'),
  ('auto_backup_enabled', 'true', 'Enable automatic daily backups'),
  ('geo_location_enabled', 'false', 'Enable GPS location tracking for attendance');

-- Helpers
create or replace function public.update_updated_at_column()
returns trigger language plpgsql as $$
begin
  NEW.updated_at = now();
  return NEW;
end $$;

-- security definer so the admin check does not recurse through profiles RLS
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where auth_user_id = auth.uid() and role = 'admin' and active
  );
$$;

-- Roster claim: when someone signs up with an email present on the registrar
-- roster (an unclaimed public.profiles row), link it to the new auth user and
-- activate it. Matching is case-insensitive on school_email.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.profiles
     set auth_user_id = new.id,
         active = true,
         updated_at = now()
   where lower(school_email) = lower(new.email)
     and auth_user_id is null;
  return new;
end $$;

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.update_updated_at_column();
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Row level security: core teaching tables stay locked down until scoped policies are added.
do $$ declare entry text; begin
  foreach entry in array array['departments','programmes','terms','courses','course_offerings','enrollments','venues','timetable_slots','sessions','attendance_records','system_settings'] loop
    execute format('alter table public.%I enable row level security', entry);
    execute format('revoke all on table public.%I from public, anon, authenticated', entry);
  end loop;
end $$;

alter table public.profiles enable row level security;
revoke all on table public.profiles from public, anon, authenticated;
grant select on public.profiles to authenticated;

create policy profiles_select_own on public.profiles
  for select using (auth.uid() = auth_user_id);
create policy profiles_admin_select_all on public.profiles
  for select using (public.is_admin());

revoke execute on function public.handle_new_user() from public, anon, authenticated;
