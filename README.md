# Peak

Personal mobile workout tracker. Flutter rewrite of [peak-web](https://github.com/Gopi-p/peak-web).
**Local-first** — every install is its own DB; no servers, no auth, no network in
the hot path. Designed for one user, in the gym, between rest periods.

> Log every rep. Climb every peak.

## What it does

- **Frictionless logging** — Start a session, pick a muscle, pick an exercise,
  tap weight/reps with a custom stepper, log the set. Auto rest timer. Repeat.
- **Fluid muscle selection** — Change muscles mid-session. The combination
  classifier flags the day as Push / Pull / Legs / Upper / Mixed at the end.
- **Progressive overload** — RPE-aware suggestion for next session's weight
  and reps. Rule-based, not ML.
- **PR detection** — A gold pill flashes when a working set beats a prior
  weight-for-reps or estimated 1RM record.
- **Weekly volume analytics** — Sets per muscle with MEV / MAV / MRV
  thresholds, volume trend, deload alert if WoW volume drops > 30 %.
- **Goals & body weight** — Optional lift / sets / frequency / weight goals.
  Body-weight log with trend.
- **Export / import JSON** — Move data between devices via the iOS share
  sheet. iCloud backs up the SQLite file automatically.

## Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.41 stable |
| Language | Dart 3.9 |
| State | Riverpod 2 |
| Routing | go_router |
| Database | Drift (SQLite) — `lib/data/db/` |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |
| Fonts | Google Fonts (Lexend body, Epilogue display) |

## Storage model

Local-only. The whole app reads/writes a single SQLite database in
`Documents/peak.sqlite`. iOS backs that file up to iCloud automatically as part
of app-data backup. No accounts, no sync server.

Tables (see [`lib/data/db/tables.dart`](lib/data/db/tables.dart)):

- `Sessions` — top-level workout (start/end, classification, muscle list).
- `ExerciseEntries` — one row per exercise inside a session.
- `WorkoutSets` — one row per logged set, references entry + session.
- `BodyWeights` — daily weight log.
- `Goals` — lift / weekly-sets / frequency / body-weight goals.
- `PersonalRecords` — auto-generated when `checkPr()` triggers on save.
- `AppSettings` — singleton (rest timer default, RPE on/off, display name).

## First-launch flow

- **New user → Start over** → ask for display name → straight into Today.
- **Existing user → Import data** → file picker → choose a JSON exported from
  another install → confirm + replace → into Today.

Re-trigger the wizard from Settings → "Reset first-launch (testing)" — useful
when testing the import path. This does not delete data.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d <device>
```

## iOS build

Requires macOS + Xcode. From a Mac:

```bash
cd ios && pod install && cd ..
flutter build ios --release
```

Run `dart run flutter_launcher_icons` after editing
`assets/icon/peak-icon.png` to regenerate iOS launcher assets.

Run `dart run tool/make_assets.dart` to regenerate the master icon + splash
PNGs.

## Project layout

```
lib/
  main.dart                # bootstrap, ProviderScope, NotificationService.init
  router.dart              # go_router config + onboarding gate
  core/
    constants.dart         # MuscleGroup, VolumeGuidance, etc.
    utils.dart             # formatWeight, epley1RM, startOfWeek
  data/
    db/
      database.dart        # Drift database + onCreate seeding
      tables.dart          # Drift tables
    exercise_catalog.dart  # loader for assets/data/exercises.json + ranking
    repositories/          # one repository per aggregate
  analytics/
    volume.dart            # rollupByWeek, setsByMuscleForSession, undertrained
    overload.dart          # suggestNext — RPE-aware progression
    pr.dart                # checkPr — weight-for-reps + estimated 1RM
    combo.dart             # classifyCombination — Push/Pull/Legs/etc.
    deload.dart            # detectDeload — > 30% WoW drop
    plate_calc.dart        # plates per side
  providers/providers.dart # Riverpod wiring (db, repos, settings stream)
  services/
    notification_service.dart    # rest-timer local notifications
    export_import_service.dart   # JSON export + share, file pick + import
  ui/
    theme/                  # colors, typography, spacing, theme.dart
    widgets/                # PeakButton, PeakCard, MuscleGrid, RestTimer, etc.
    pages/                  # one folder per feature, mirrors peak-web routes
    shell.dart              # bottom tab bar + safe-area layout
assets/
  data/exercises.json       # seeded exercise database (copied from peak-web)
  icon/peak-icon.png        # launcher source
  icon/peak-splash.png      # splash source
tool/make_assets.dart       # pure-Dart icon + splash PNG generator
```

## Conventions

- **Local-first.** Every write hits SQLite immediately. No queues, no retries,
  no "syncing" state to design for.
- **Single user, no auth.** `AppSettings.displayName` is the only identity.
  No server, no users table, no login flow.
- **Numeric input.** Never the iOS keyboard for weight/reps — only the
  `StepperPad`. Big buttons, haptic on press.
- **Tap targets.** 56 px tall for between-set actions; standard 44 px elsewhere.
- **Tabular numerics.** Apply `PeakType.tabular(...)` to any number the user
  reads at a glance.
- **Validation.** Repositories validate at the boundary; analytics expect
  pre-cleaned input.
- **Soft delete.** Sessions / goals / body-weight entries hide via
  `deletedAt`. Sets inside an active session hard-delete.

## What not to do

- Don't add a backend. The web sibling is for analytics dashboards if needed.
- Don't introduce auth or accounts. Each install is its own world.
- Don't ship UI that opens the iOS keyboard for weight/reps.
- Don't add cardio, nutrition, or social features.
- Don't let the analytics drift from rules to ML.

## License

Private project. Not for distribution.
