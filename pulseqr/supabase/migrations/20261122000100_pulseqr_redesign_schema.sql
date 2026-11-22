-- PulseQR redesign migration (PulseQR Redesign.pdf, 2026-11-22).
-- ADDITIVE ONLY — nothing is dropped, renamed or rewritten. Safe to run on the
-- live "QR code" project (vjnczngqljtvwjgmpgbo).
--
-- What it adds, mapped to the redesigned screens:
--   * system_settings keys for the Rules screen steppers
--       minimum_attendance_percent 75 · late_after_minutes 15 · checkin_open_minutes 15
--       session_code_interval_minutes 15 (10–20) · excuse_window_days 7
--       automatic_excuses_per_course 2 · late_cancel_hours 2
--   * campus_config      single-row geofence circle (drag pin + radius, default 300 m)
--   * no_class_days      exam break 14–18 Dec 2026, whole school (students are told)
--   * session_codes      rotating typed codes ("794 281", "New code in 12:40")
--   * excuses            "What happened?" + proof upload, automatic vs lecturer-decided
--   * activity_log       admin Activity feed (refused check-ins / changes)
--   * two security-definer RPCs so the client never sees codes it must not see:
--       check_in_with_code(...)  QR/typed-code check-in with geofence enforcement
--       send_excuse(...)         excuse flow with automatic-excuse counting
--
-- Client access: everything new is RLS-locked; only what each role needs is granted.

-- ---------------------------------------------------------------- settings
insert into public.system_settings (setting_key, setting_value, description) values
  ('minimum_attendance_percent',   '75', 'Attendance percentage required for exam eligibility'),
  ('late_after_minutes',           '15', 'Minutes after the start before a check-in counts as late'),
  ('checkin_open_minutes',         '15', 'How long after the start check-in stays open'),
  ('session_code_interval_minutes','15', 'How often the typed class code rotates, in minutes (10-20)'),
  ('excuse_window_days',           '7',  'Days a student has to send an excuse after a missed class'),
  ('automatic_excuses_per_course', '2',  'Excuses accepted automatically per course per term'),
  ('late_cancel_hours',            '2',  'Window before the start within which a cancellation counts against the lecturer')
on conflict (setting_key) do nothing;

-- ---------------------------------------------------------------- campus_config (Campus & timetable)
create table if not exists public.campus_config (
  id boolean primary key default true check (id),
  latitude  double precision not null default -13.9626 check (latitude between -90 and 90),
  longitude double precision not null default 33.7741 check (longitude between -180 and 180),
  radius_m  integer not null default 300 check (radius_m between 100 and 800),
  updated_by uuid references public.profiles,
  updated_at timestamptz not null default now()
);
insert into public.campus_config (id) values (true) on conflict (id) do nothing;

drop trigger if exists campus_config_set_updated_at on public.campus_config;
create trigger campus_config_set_updated_at before update on public.campus_config
  for each row execute function public.update_updated_at_column();

-- ---------------------------------------------------------------- no_class_days
create table if not exists public.no_class_days (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  scope text not null default 'whole_school' check (scope in ('whole_school', 'department', 'course')),
  department_id uuid references public.departments,
  course_id uuid references public.courses,
  starts_on date not null,
  ends_on date not null check (ends_on >= starts_on),
  created_by uuid references public.profiles,
  created_at timestamptz not null default now()
);
insert into public.no_class_days (name, scope, starts_on, ends_on)
select 'Exam break', 'whole_school', date '2026-12-14', date '2026-12-18'
where not exists (
  select 1 from public.no_class_days
  where name = 'Exam break' and starts_on = date '2026-12-14'
);

-- ---------------------------------------------------------------- session_codes
create table if not exists public.session_codes (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions on delete cascade,
  code text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);
create index if not exists session_codes_session_created on public.session_codes (session_id, created_at desc);

-- ---------------------------------------------------------------- excuses
do $$ begin
  create type public.excuse_status as enum ('auto_approved', 'pending_lecturer', 'approved', 'declined');
exception when duplicate_object then null;
end $$;

create table if not exists public.excuses (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions on delete cascade,
  student_id uuid not null references public.profiles,
  reason text not null,
  details text,
  proof_url text,
  status public.excuse_status not null default 'pending_lecturer',
  automatic boolean not null default false,
  created_at timestamptz not null default now(),
  reviewed_by uuid references public.profiles,
  reviewed_at timestamptz
);
create index if not exists excuses_student on public.excuses (student_id);
create index if not exists excuses_session on public.excuses (session_id);

-- ---------------------------------------------------------------- activity_log
create table if not exists public.activity_log (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles,
  kind text not null check (kind in ('refused_checkin', 'change', 'info')),
  title text not null,
  ref text,
  created_at timestamptz not null default now()
);
create index if not exists activity_log_created on public.activity_log (created_at desc);

-- ------------------------------------------------------- automatic-excuse helper
create or replace function public.automatic_excuses_used(p_student uuid, p_offering uuid)
returns integer
language sql stable security definer set search_path = public as $$
  select count(*)::integer
  from public.excuses e
  join public.sessions s on s.id = e.session_id
  join public.course_offerings co on co.id = s.offering_id
  join public.terms t on t.id = co.term_id
  where e.student_id = p_student
    and co.id = p_offering
    and e.automatic
    and t.starts_on <= now()::date
    and t.ends_on >= now()::date;
$$;
revoke execute on function public.automatic_excuses_used(uuid, uuid) from public, anon, authenticated;

-- ------------------------------------------------------- check-in RPC (QR + typed code)
create or replace function public.check_in_with_code(
  p_session uuid,
  p_code text,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_accuracy double precision default null
)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_session public.sessions%rowtype;
  v_code text;
  v_code_expires timestamptz;
  v_distance double precision;
  v_radius integer;
  v_student uuid;
  v_student_name text;
  v_course_code text;
  v_late_after integer;
  v_now timestamptz := now();
begin
  select id, full_name into v_student, v_student_name
    from public.profiles where auth_user_id = auth.uid();
  if v_student is null then
    return jsonb_build_object('ok', false, 'code', 'no_profile');
  end if;

  select * into v_session from public.sessions where id = p_session;
  if not found then
    return jsonb_build_object('ok', false, 'code', 'session_not_found');
  end if;

  select c.code into v_course_code
    from public.course_offerings co
    join public.courses c on c.id = co.course_id
   where co.id = v_session.offering_id;

  if v_session.status <> 'open' then
    insert into public.activity_log (actor_id, kind, title, ref)
    values (v_student, 'refused_checkin', 'Check-in refused: class is not open', v_student_name || ' · ' || coalesce(v_course_code, '?'));
    return jsonb_build_object('ok', false, 'code', 'closed');
  end if;

  select code, expires_at into v_code, v_code_expires
    from public.session_codes
   where session_id = p_session
   order by created_at desc
   limit 1;

  if v_code is null or v_code <> p_code then
    insert into public.activity_log (actor_id, kind, title, ref)
    values (v_student, 'refused_checkin', 'Check-in refused: code did not match', v_student_name || ' · ' || coalesce(v_course_code, '?'));
    return jsonb_build_object('ok', false, 'code', 'bad_code');
  end if;

  if v_code_expires < v_now then
    insert into public.activity_log (actor_id, kind, title, ref)
    values (v_student, 'refused_checkin', 'Check-in refused: code had expired', v_student_name || ' · ' || coalesce(v_course_code, '?'));
    return jsonb_build_object('ok', false, 'code', 'code_expired');
  end if;

  if v_session.kind = 'in_person' then
    if p_latitude is null or p_longitude is null then
      return jsonb_build_object('ok', false, 'code', 'missing_location');
    end if;
    select c.radius_m into v_radius from public.campus_config c where c.id = true;
    select 6371000 * acos(least(1.0,
             cos(radians(c.latitude)) * cos(radians(p_latitude)) * cos(radians(p_longitude) - radians(c.longitude))
             + sin(radians(c.latitude)) * sin(radians(p_latitude))))
      into v_distance
      from public.campus_config c where c.id = true;
    if v_distance > v_radius then
      insert into public.activity_log (actor_id, kind, title, ref)
      values (v_student, 'refused_checkin', 'Check-in refused: outside campus', v_student_name || ' · ' || coalesce(v_course_code, '?'));
      return jsonb_build_object('ok', false, 'code', 'not_on_campus', 'distance_m', round(v_distance::numeric, 1));
    end if;
  end if;

  select coalesce((select setting_value::integer from public.system_settings where setting_key = 'late_after_minutes'), 15)
    into v_late_after;

  insert into public.attendance_records (session_id, student_id, status, distance_m, accuracy_m)
  values (
    p_session,
    v_student,
    case when v_now > v_session.scheduled_at + make_interval(mins => v_late_after) then 'late'::public.attendance_status
         else 'present'::public.attendance_status end,
    v_distance,
    p_accuracy
  )
  on conflict (session_id, student_id) do nothing;

  return jsonb_build_object('ok', true, 'code', 'checked_in', 'status',
    case when v_now > v_session.scheduled_at + make_interval(mins => v_late_after) then 'late' else 'present' end);
end $$;
revoke execute on function public.check_in_with_code(uuid, text, double precision, double precision, double precision) from public, anon;
grant execute on function public.check_in_with_code(uuid, text, double precision, double precision, double precision) to authenticated;

-- ------------------------------------------------------- excuse RPC (automatic vs lecturer)
create or replace function public.send_excuse(
  p_session uuid,
  p_reason text,
  p_details text default null,
  p_proof_url text default null
)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_session public.sessions%rowtype;
  v_student uuid;
  v_student_name text;
  v_course_code text;
  v_offering uuid;
  v_window integer;
  v_auto_limit integer;
  v_used integer;
  v_status public.excuse_status;
  v_automatic boolean;
begin
  if coalesce(trim(p_reason), '') = '' then
    return jsonb_build_object('ok', false, 'code', 'missing_reason');
  end if;

  select id, full_name into v_student, v_student_name
    from public.profiles where auth_user_id = auth.uid();
  if v_student is null then
    return jsonb_build_object('ok', false, 'code', 'no_profile');
  end if;

  select * into v_session from public.sessions where id = p_session;
  if not found then
    return jsonb_build_object('ok', false, 'code', 'session_not_found');
  end if;
  v_offering := v_session.offering_id;

  select coalesce((select setting_value::integer from public.system_settings where setting_key = 'excuse_window_days'), 7)
    into v_window;
  if now() > v_session.scheduled_at + make_interval(days => v_window) then
    return jsonb_build_object('ok', false, 'code', 'window_closed');
  end if;

  select c.code into v_course_code
    from public.course_offerings co join public.courses c on c.id = co.course_id
   where co.id = v_offering;

  v_auto_limit := coalesce((select setting_value::integer from public.system_settings where setting_key = 'automatic_excuses_per_course'), 2);
  v_used := public.automatic_excuses_used(v_student, v_offering);

  if v_used < v_auto_limit then
    v_status := 'auto_approved';
    v_automatic := true;
  else
    v_status := 'pending_lecturer';
    v_automatic := false;
  end if;

  insert into public.excuses (session_id, student_id, reason, details, proof_url, status, automatic)
  values (p_session, v_student, trim(p_reason), nullif(trim(coalesce(p_details, '')), ''), p_proof_url, v_status, v_automatic);

  -- Automatic excuses count immediately; lecturer-decided ones flip the
  -- attendance row only after the lecturer approves.
  if v_automatic then
    insert into public.attendance_records (session_id, student_id, status)
    values (p_session, v_student, 'excused')
    on conflict (session_id, student_id) do update set status = 'excused';
  end if;

  insert into public.activity_log (actor_id, kind, title, ref)
  values (
    v_student,
    'change',
    case when v_automatic then 'Excuse accepted automatically' else 'Excuse sent to lecturer' end,
    v_student_name || ' · ' || coalesce(v_course_code, '?')
  );

  return jsonb_build_object('ok', true, 'code', v_status, 'automatic', v_automatic,
    'automatic_used', v_used + (case when v_automatic then 1 else 0 end),
    'automatic_limit', v_auto_limit);
end $$;
revoke execute on function public.send_excuse(uuid, text, text, text) from public, anon;
grant execute on function public.send_excuse(uuid, text, text, text) to authenticated;

-- ---------------------------------------------------------------- RLS
do $$ declare entry text; begin
  foreach entry in array array['campus_config','no_class_days','session_codes','excuses','activity_log'] loop
    execute format('alter table public.%I enable row level security', entry);
    execute format('revoke all on table public.%I from public, anon, authenticated', entry);
  end loop;
end $$;

-- campus_config: everyone signed in can read (to know they are on campus); only admins write.
grant select on public.campus_config to authenticated;
grant update on public.campus_config to authenticated;
create policy campus_config_select on public.campus_config for select to authenticated using (true);
create policy campus_config_admin_update on public.campus_config for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- no_class_days: readable by everyone signed in; admins manage.
grant select on public.no_class_days to authenticated;
grant insert, delete on public.no_class_days to authenticated;
create policy no_class_days_select on public.no_class_days for select to authenticated using (true);
create policy no_class_days_admin_insert on public.no_class_days for insert to authenticated with check (public.is_admin());
create policy no_class_days_admin_delete on public.no_class_days for delete to authenticated using (public.is_admin());

-- session_codes: NO client read at all — codes rotate server-side; the client
-- only checks in through the check_in_with_code() RPC. (Select intentionally not granted.)

-- excuses: student reads/creates their own; lecturer reads/decides for their
-- offerings; admin sees all.
grant select, insert, update on public.excuses to authenticated;
create policy excuses_read on public.excuses for select to authenticated using (
  public.is_admin()
  or exists (select 1 from public.profiles p where p.auth_user_id = auth.uid() and p.id = excuses.student_id)
  or exists (select 1
             from public.profiles p
             join public.course_offerings co on co.lecturer_id = p.id
             join public.sessions s on s.offering_id = co.id
             where p.auth_user_id = auth.uid() and s.id = excuses.session_id)
);
create policy excuses_insert_own on public.excuses for insert to authenticated with check (
  exists (select 1 from public.profiles p where p.auth_user_id = auth.uid() and p.id = excuses.student_id)
);
create policy excuses_decide on public.excuses for update to authenticated using (
  public.is_admin()
  or exists (select 1
             from public.profiles p
             join public.course_offerings co on co.lecturer_id = p.id
             join public.sessions s on s.offering_id = co.id
             where p.auth_user_id = auth.uid() and s.id = excuses.session_id)
) with check (
  public.is_admin()
  or exists (select 1
             from public.profiles p
             join public.course_offerings co on co.lecturer_id = p.id
             join public.sessions s on s.offering_id = co.id
             where p.auth_user_id = auth.uid() and s.id = excuses.session_id)
);

-- activity_log: admin read-only; written by RPCs / service role only.
grant select on public.activity_log to authenticated;
create policy activity_log_admin_read on public.activity_log for select to authenticated using (public.is_admin());

-- ------------------------------------------------------- proof storage bucket
-- The redesign uploads a photo/PDF proof (max 10 MB). If storage is unavailable
-- this whole block is skipped instead of failing the migration.
do $$
begin
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('excuse-proofs', 'excuse-proofs', false, 10485760,
          array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
  on conflict (id) do nothing;

  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'excuse_proofs_insert_own') then
    create policy excuse_proofs_insert_own on storage.objects for insert to authenticated
      with check (bucket_id = 'excuse-proofs' and (storage.foldername(name))[1] = auth.uid()::text);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'excuse_proofs_read_authenticated') then
    create policy excuse_proofs_read_authenticated on storage.objects for select to authenticated
      using (bucket_id = 'excuse-proofs');
  end if;
exception when others then
  raise notice 'excuse-proofs storage bucket skipped: %', sqlerrm;
end $$;
