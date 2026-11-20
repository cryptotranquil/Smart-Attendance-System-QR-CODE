-- Draft foundation; deliberately grants no client access until scoped policies are added.
create type public.user_role as enum ('student','lecturer','admin');
create type public.session_type as enum ('in_person','online','hybrid');
create type public.session_status as enum ('scheduled','open','closed','cancelled','not_held');
create type public.attendance_status as enum ('present','late','absent','excused');
create table public.departments (id uuid primary key default gen_random_uuid(), code text unique not null, name text not null);
create table public.programmes (id uuid primary key default gen_random_uuid(), department_id uuid not null references public.departments, code text unique not null, name text not null);
create table public.profiles (id uuid primary key default gen_random_uuid(), auth_user_id uuid unique references auth.users on delete set null, school_id text unique not null, school_email text not null, full_name text not null, role public.user_role not null, programme_id uuid references public.programmes, active boolean not null default false);
create unique index profiles_school_email on public.profiles (lower(school_email));
create table public.terms (id uuid primary key default gen_random_uuid(), name text not null, starts_on date not null, ends_on date not null check (ends_on >= starts_on));
create table public.courses (id uuid primary key default gen_random_uuid(), department_id uuid not null references public.departments, code text unique not null, title text not null);
create table public.course_offerings (id uuid primary key default gen_random_uuid(), course_id uuid not null references public.courses, term_id uuid not null references public.terms, lecturer_id uuid not null references public.profiles);
create table public.enrollments (offering_id uuid references public.course_offerings, student_id uuid references public.profiles, primary key (offering_id, student_id));
create table public.venues (id uuid primary key default gen_random_uuid(), name text unique not null, latitude double precision not null check (latitude between -90 and 90), longitude double precision not null check (longitude between -180 and 180), radius_m integer not null check (radius_m > 0));
create table public.timetable_slots (id uuid primary key default gen_random_uuid(), offering_id uuid not null references public.course_offerings, venue_id uuid references public.venues, day_of_week integer not null check (day_of_week between 1 and 7), starts_at time not null, ends_at time not null check (ends_at > starts_at), kind public.session_type not null, check (kind = 'online' or venue_id is not null));
create table public.sessions (id uuid primary key default gen_random_uuid(), slot_id uuid references public.timetable_slots, offering_id uuid not null references public.course_offerings, venue_id uuid references public.venues, scheduled_at timestamptz not null, opened_at timestamptz, closed_at timestamptz, kind public.session_type not null, status public.session_status not null default 'scheduled', replaces_session_id uuid references public.sessions, policy_snapshot jsonb not null default '{}', reason text, unique (slot_id, scheduled_at));
create table public.attendance_records (session_id uuid references public.sessions, student_id uuid references public.profiles, status public.attendance_status not null, recorded_at timestamptz not null default now(), distance_m double precision, accuracy_m double precision, flags text[] not null default '{}', primary key (session_id, student_id));
do $$ declare entry text; begin
foreach entry in array array['departments','programmes','profiles','terms','courses','course_offerings','enrollments','venues','timetable_slots','sessions','attendance_records'] loop
execute format('alter table public.%I enable row level security',entry);
execute format('revoke all on table public.%I from public, anon, authenticated',entry);
end loop;
end $$;
