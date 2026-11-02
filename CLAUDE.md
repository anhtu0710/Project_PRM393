# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GenzCinema Hotel — a cinema hotel booking app (Flutter). **Branch `sqlite`:** there is no server. All data lives in a local SQLite database on the phone, so the APK works offline on any Android device. (The Spring Boot + SQL Server version is on `main`.)

## Commands (run inside `mobile/`)

```bash
flutter pub get              # Install dependencies
flutter run                  # Run on Android emulator/device (sqflite does NOT run on Chrome)
flutter build apk            # Build APK -> build/app/outputs/flutter-apk/app-release.apk
flutter analyze              # Lint
flutter test                 # Run tests
flutter emulators --launch Medium_Phone   # Start the Android emulator
```

## Architecture (Flutter + Riverpod + sqflite)

Screen → Provider → Service → SQLite.

- `database.sql` (directly in `mobile/`, declared in `pubspec.yaml` assets) — the ONLY place tables and sample data are defined (merged from the old `SQLQuery1.sql` + `sprint_foundation.sql`, SQLite syntax). It must stay inside `mobile/`: Flutter cannot bundle assets from outside the package folder. Test accounts and their shared password are listed in its header.
- `lib/database/database_helper.dart` — opens `genz_cinema_hotel.db`; on first launch runs `database.sql` statement by statement (split on `;`, `--` comment lines skipped — never put `;` inside data or comments). Also `hashPassword()` (SHA-256).
- `lib/services/` — one service per feature (auth, room, hotel, booking, price_config, voucher, review, admin). They run SQL with sqflite and return the models in `lib/models/`. Errors are thrown as Vietnamese `String`s; `BookingService.errorMessage` / `AdminService.errorMessage` read them. Business rules (price from PriceConfig, overlap check, voucher check, cancel rules, admin stats) live here.
- `lib/providers/` — Riverpod providers wrapping the services.
- `lib/config/router.dart` — GoRouter; redirects by login status and role (`ADMIN` → `/admin`, `STAFF` → `/staff`, else `/home`). Guests may visit `/home`, `/rooms`, `/rooms/:id`, `/saved`; everything else (including `/rooms/:id/booking`) redirects to `/login`.
- `lib/config/app_config.dart` — role names, booking/room status constants, storage keys.
- Logged-in user is saved in FlutterSecureStorage (`AppConfig.userKey`); `AuthService.getCurrentUser()` re-checks the DB (locked/deleted users are logged out, role refreshed).

## Development Notes

- Changing `mobile/database.sql` only takes effect on a fresh install (uninstall the app first) because it runs in `onCreate`.
- Dates are stored as ISO text (`2026-11-05T19:00:00`); compare them in Dart with `DateTime.parse`. Sample bookings use `strftime(..., 'now', 'localtime', ...)` so they are always relative to the install date.
- Forgot password works offline: `requestPasswordReset` returns the reset token and the screen opens `/reset-password?token=...` directly (no email).
- Each phone has its own data; uninstalling the app deletes it.
- The team is new to coding: keep code simple (plain SQL, `db.query` / `db.rawQuery`, small helper functions, Vietnamese comments).
- Booking statuses (`AppConfig.booking*`): `PENDING, CONFIRMED, REJECTED, CHECKED_IN, COMPLETED, CANCELLED`. Room statuses (`AppConfig.room*`): `Trống, Đang dùng, Đang dọn`.
- After modifying any Riverpod `@riverpod`-annotated provider, run `flutter pub run build_runner build`.
