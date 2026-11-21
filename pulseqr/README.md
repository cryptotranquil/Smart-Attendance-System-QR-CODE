# PulseQR

School attendance for students, lecturers and administrators. Flutter app (Android, iOS, web) backed by Supabase. The auth experience (Create Account / Sign In) follows the Monochrome Neo-Tech design in `DESIGN.md`.

## Demo credentials

The live demo project (`QR code`, ref `vjnczngqljtvwjgmpgbo`) has three confirmed demo accounts. **All share the password `PulseQR-Demo-2026!`** — rotate or delete them before any real deployment.

| Email | Role | Profile ID |
| --- | --- | --- |
| `student@pulseqr.demo` | Student | `REG-DEMO-0001` |
| `lecturer@pulseqr.demo` | Lecturer | `FAC-DEMO-0001` |
| `admin@pulseqr.demo` | Admin | `ADM-DEMO-0001` |

Two **unclaimed** registrar-roster rows exist so the Create Account flow can be demonstrated end-to-end:

| Roster email | Role | Profile ID |
| --- | --- | --- |
| `newstudent@pulseqr.demo` | Student | `REG-2026-0042` |
| `newlecturer@pulseqr.demo` | Lecturer | `FAC-2026-0042` |

Signing up with one of those emails triggers the `handle_new_user` trigger, which links the new auth user to the roster profile and activates it. Any other email creates an auth user with **no** profile (the app signs them out and asks them to contact the Registrar) — this mirrors the school-provisioned roster model.

Demo seed lives in `supabase/seed.sql`. It is written for demo projects only.

## Database

Canonical schema: `supabase/migrations/20261121000100_pulseqr_core_schema.sql`.

The migration is intentionally destructive (`DROP … IF EXISTS … CASCADE`): it replaces the legacy `public.users` / dual-profile layout with a single clean schema —

- teaching catalogue: `departments`, `programmes`, `terms`, `courses`, `course_offerings`, `enrollments`, `venues`, `timetable_slots`, `sessions`, `attendance_records`
- `profiles` — school-provisioned roster (`auth_user_id` is null until claimed); readable by the owner (`profiles_select_own`) and by active admins (`profiles_admin_select_all` via `is_admin()`)
- `system_settings` — locked to the service role; contains `qr_time_limit_minutes=15`, `attendance_threshold_percentage=75`, `auto_backup_enabled=true`, `geo_location_enabled=false`
- everything else (`handle_new_user`, `is_admin`, `update_updated_at_column`) and RLS enabled everywhere; teaching tables have no client policies yet

Applied live on 2026-11-21 as migration `recreate_pulseqr_schema`. The earlier draft folder (`pulseqr-database-draft/`) and superseded migrations were removed — the file above is the single source of truth.

## Supabase sign-in

For the connected build, copy the project URL and **publishable** key from the Supabase dashboard Connect dialog. Do not use `service_role`, secret keys, or a database password. On your computer, run:

```sh
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=https://vjnczngqljtvwjgmpgbo.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Without these defines the app opens in UI preview mode (any credentials “work”, nothing is sent).

Connected behaviour:

- **Sign In** requires a confirmed auth user with an active `public.profiles` row (role `student`, `lecturer` or `admin`).
- **Create Account** calls `auth.signUp`. The `handle_new_user` trigger claims a matching unclaimed roster profile by email and activates it. If no roster row matches, the account is created but stays locked until the Registrar adds the entry.
- Email confirmation behavior follows the project’s auth settings.

## Running locally

With the Flutter SDK installed, run `flutter create --platforms=android,ios,web .` to generate platform runners, then `flutter pub get` and `flutter run -d chrome`. The source in `lib/` should be preserved by the generator. No credentials are stored in this repository.

Note: the analytics/telemetry values shown on the dashboard after sign-in are sample placeholders until attendance sync ships; auth, roster claiming and role routing are fully wired.
