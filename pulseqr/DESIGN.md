# PulseQR Design System
_Supersedes the Monochrome Neo-Tech system. Source of truth: `PulseQR Redesign.pdf` (9 pages, 2026-11-22). Implemented in `lib/src/theme.dart` (`C` palette + `PulseTheme`) and `lib/src/widgets.dart`._

## Personality
Calm campus utility. Plain language, big type, one confident accent. Semantic colors appear only for status. Never shout: no gradients, no glassmorphism, no emoji.

## Color tokens
| Token | Hex | Use |
|---|---|---|
| `bg` | `#F5F6F8` | Scaffold background |
| `card` | `#FFFFFF` | Cards, app bar, fields on cards |
| `ink` | `#101828` | Text, near-black buttons (`brand`) |
| `muted` | `#667085` | Secondary text |
| `faint` | `#98A2B3` | Section labels, placeholders, disabled |
| `hairline` | `#E4E7EC` | Card borders, dividers |
| `accent` | `#155EEF` | Links, focus rings, active nav, selected states |
| `brand` | `#101828` | Primary buttons, dark hero cards, logo mark |
| `success` | `#067647` on `#ECFDF3` | Approved, on campus, present, Active |
| `warn` | `#B54708` on `#FFFAEB` | With lecturer, late, no-class days, off-campus nudge |
| `danger` | `#B42318` on `#FEF3F2` | Below 75%, refused, Suspended, error copy |
| `infoSoft` | `#EFF4FF` | Info banners (automatic excuses, upgrade prompts) |

## Shape & type
- Radius: cards `20`, fields `14`, buttons `12–14`, pills `999`.
- Typeface: system/Inter, heavy weights. Display 38–46 px/w800/letterSpacing −1.2 · title 26/w800 · card value 30–46/w800 · body 12–14 · section label 10.5/w800/+1.3 tracking uppercase.
- Cards: white, 1 px hairline border, no shadow. Dark hero cards (`brand` fill) for the "Open now" and "Up next" moments.
- Tap targets ≥ 44 px. Tables collapse under 760 px; top bar switches to bottom navigation below 760 px.

## Voice (examples from the PDF)
"Mark your attendance in seconds." · "Here is how your attendance looks this term." · "Missed a class? Tell us why within 7 days." · "You can\'t miss many more" · "Everyone gets an automatic excuse and is told."
Errors are specific and kind: "You're not on campus. Turn on location, walk outside for a moment and try again."

## Screen map → code
| PDF page | Screen | Code |
|---|---|---|
| 1 Welcome | Sign in / Create account, role preview chips | `lib/src/sign_in_screen.dart` |
| 2 Student Home | Open now card, 86% card, excuses left, courses, today | `lib/src/student_screens.dart` (`_HomeTab`) |
| 3 Check in | QR / typed code + geofence + 3 error copy blocks | `lib/src/student_screens.dart` (`_CheckInTab`) |
| 4 Excuses | 3-step flow (class → reason → proof ≤10 MB), auto-excuse banner, my excuses | `lib/src/student_screens.dart` (`_ExcusesTab`) |
| 5 Lecturer Today | Up next hero, Opens at… / Finished states, cancel | `lib/src/lecturer_screens.dart` (`_TodayTab`) |
| 6 Live class | QR + typed code 794 281, 12:40 countdown, 38/48, live feed | `lib/src/lecturer_screens.dart` (`_LiveClassTab`) |
| 7 Admin People | CSV in/out, stats (1420 / 68 / 212), filter tabs, search, table + pagination | `lib/src/admin_screens.dart` (`_PeopleTab`) |
| 8 Campus & timetable | 300 m geofence circle, radius −/+, timetable table, no-class days (exam break) | `lib/src/admin_screens.dart` (`_CampusTab`) |
| 9 Rules & activity | Stepper rows (75 / 15 / 15 / 15 / 7 / 2 / 2), Activity feed w/ filter tabs | `lib/src/admin_screens.dart` (`_RulesTab`) |

## Data model notes
- Redesigned screens ship with demo datasets (`lib/src/demo_data.dart`); auth + profile routing are live against Supabase.
- Backend additions backing the redesign: migration `20261122000100_pulseqr_redesign_schema.sql` — `campus_config` (single-row geofence), `no_class_days`, `session_codes` (rotating typed codes), `excuses` (auto vs lecturer-decided), `activity_log`, Rules `system_settings` keys, and the security-definer RPCs `check_in_with_code()` and `send_excuse()` so codes/proofs are enforced server-side. See README → Database.
