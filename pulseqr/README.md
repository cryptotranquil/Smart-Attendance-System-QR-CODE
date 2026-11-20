# PulseQR

Flutter starter adapting the Stitch Monochrome Neo-Tech concept. The sign-in, account claim, email verification, and password reset screens are UI-only. The role selector and timetable/check-in screens are a design preview, not authentication or attendance processing.

With the Flutter SDK installed, run `flutter create --platforms=android,ios,web .` to generate platform runners, then `flutter pub get` and `flutter run -d chrome`. The source in `lib/` should be preserved by the generator. No credentials are stored in this repository.

## Supabase sign-in

For the connected build, copy the project URL and **publishable** key from the Supabase dashboard Connect dialog. Do not use `service_role`, secret keys, or a database password. On your computer, run:

```sh
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=https://vjnczngqljtvwjgmpgbo.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Without these defines the app opens in UI preview mode. Connected sign-in requires an existing confirmed Supabase Auth user and an active `public.users` row with a matching UUID and assigned `user_type` (`student`, `lecturer`, or `admin`). The school must provision those profiles via trusted backend access. Sign-up and password recovery remain preview-only; dashboard data is still sample data.
