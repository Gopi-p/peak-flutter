# Peak Flutter — agent guide

Local-first mobile workout tracker. Single user, no auth, no backend.
Flutter rewrite of [peak-web](../peak-web). The web sibling is being repurposed as
an analytics dashboard for the same data.

## Stack

- Flutter 3.41 (stable) + Dart 3.9
- Riverpod 2 (state), go_router (routing)
- Drift / SQLite (local-only DB) — `lib/data/db/`
- fl_chart for analytics
- google_fonts (Lexend body, Epilogue display)
- flutter_local_notifications + vibration for the rest timer
- file_picker + share_plus for JSON export / import

## Storage

Single SQLite file at `<app docs>/peak.sqlite`. iOS auto-backs it up to iCloud.
No server. No accounts. Each install is a fresh world.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate drift / freezed
flutter analyze
flutter test
flutter run -d <ios device>
```

## Layout

```
lib/
  main.dart                # bootstrap
  router.dart              # go_router + onboarding gate
  core/                    # MuscleGroup enum, formatWeight, epley1RM
  data/
    db/                    # Drift database + tables
    exercise_catalog.dart  # bundled exercises.json loader
    repositories/          # one repo per aggregate
  analytics/               # pure functions ported from peak-web
  providers/providers.dart # Riverpod wiring
  services/                # notifications, export/import
  ui/
    theme/                 # Midnight Studio colors/type/spacing
    widgets/               # PeakButton, MuscleGrid, RestTimer, StepperPad
    pages/                 # one folder per feature
    shell.dart             # bottom tab bar layout
assets/data/exercises.json # canonical exercise seed (mirror of peak-web)
```

## Conventions

- **Local-only writes.** All persistence is the local Drift DB. No queues, no
  retries, no "syncing" UI — that complexity belongs to the orphaned web app.
- **No auth, ever.** `AppSettings.displayName` is the only identity. Do not
  introduce a `User` table.
- **Numeric input.** Never use the iOS keyboard for weight/reps. Use
  `StepperPad` (the only sanctioned path). 56 px tap targets between sets.
- **Tabular numerics.** Wrap any number the user reads at a glance with
  `PeakType.tabular(...)`. Tabular figures are baked into the numeric type styles.
- **Theme.** Midnight Studio — `#131316` background, `#D4AF37` gold accent.
  Always dark. CSS-var equivalents are in `lib/ui/theme/colors.dart`.
- **Soft-delete.** Sessions / goals / body-weight hide via `deletedAt`. Sets
  inside an active session hard-delete (swipe-to-delete with no confirm).
- **Reactivity.** Watchable lists use Drift's `.watch()`; one-shot reads use
  `FutureProvider`. Prefer streams for anything the user can mutate while open.

## Domain notes

- **Volume math** counts working sets only. Secondary muscle contributions count
  at 0.5×.
- **Progressive overload** is RPE-aware (`overload.dart`): ≤7 bump 2.5kg,
  =8 add a rep, ≥9 hold.
- **PR detection** runs inside `SessionRepository.logSet()` and writes to
  `PersonalRecords`. Same logic as `peak-web/lib/analytics/pr.ts`.
- **Combination classifier** uses fixed muscle groupings — see `combo.dart`.
- **Deload detection** flags > 30 % WoW total-volume drop.
- **Plate calculator** greedy from `[25, 20, 15, 10, 5, 2.5, 1.25]`.

## What not to do

- Don't add a backend. Don't add HTTP clients. Don't add auth.
- Don't add cardio, nutrition, or social features.
- Don't introduce sync — local-only, manual JSON export/import is the contract.
- Don't ship UI that opens the iOS keyboard for weight/reps.
- Don't import from peak-web — it's an orphan. Port logic if needed.

## First-launch

- New user → name → Today
- Existing user → file picker → import JSON → Today

Flag persists in `SharedPreferences.peak.onboarded`. Settings has a "Reset
first-launch" action for testing the flow without wiping data.

## Related

- `../peak-web/` — original Next.js implementation. Reference for design intent
  and the seeded `exercises.json`. Don't run against its API.
- `assets/data/exercises.json` — canonical seed, copied from peak-web.
