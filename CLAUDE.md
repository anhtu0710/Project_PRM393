# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GenzCinema Hotel — a cinema hotel booking system with a Spring Boot REST API backend and Flutter mobile client.

## Commands

### Backend (Spring Boot — `backend/`)

```bash
cd backend
./mvnw spring-boot:run       # Start server at http://localhost:8080/api
./mvnw clean install         # Build
./mvnw test                  # Run all tests
./mvnw package               # Build JAR to target/
```

### Mobile (Flutter — `mobile/`)

```bash
cd mobile
flutter pub get              # Install dependencies
flutter run                  # Run on emulator/device
flutter build apk            # Build Android APK
flutter analyze              # Lint
flutter test                 # Run tests
flutter pub run build_runner build   # Regenerate Riverpod code after provider changes
```

## Architecture

### Backend (Java 17 + Spring Boot 3.5.6 + SQL Server)

Layered: Controller → Service → Repository → Entity. All responses are wrapped in `ApiResponse<T>`.

- `controller/` — REST endpoints (Auth, Room, Booking)
- `service/` — Business logic (AuthService, EmailService)
- `security/` — JWT pipeline: `JwtService` generates/validates tokens, `JwtAuthFilter` attaches auth to each request, `SecurityConfig` defines public vs protected routes
- `entity/` — JPA entities mapped to SQL Server (User, Room, Booking, Hotel, Role, TypeRoom, TypeBooking, PriceConfig, PasswordResetToken)
- `dto/` — Request/response objects (LoginRequest, LoginResponse, RegisterRequest, ResetPasswordDto, ApiResponse)
- `repository/` — Spring Data JPA interfaces
- `exception/GlobalExceptionHandler.java` — Centralized error handling

JWT claims embed: `userId`, `fullName`, `role`, `roleId`. Routes under `/api/auth/**` are public; all others require a valid token.

### Mobile (Flutter + Riverpod + Dio)

- `main.dart` — Entry point; wraps app in `ProviderScope`
- `config/router.dart` — GoRouter; listens to `authProvider` and redirects on login status and role (`ADMIN` → admin dashboard, `CUSTOMER` → room list)
- `config/app_config.dart` — Central constants: base API URL, role names, storage keys
- `services/api_client.dart` — Dio singleton; interceptor auto-attaches `Authorization: Bearer {token}` from FlutterSecureStorage
- `providers/auth_provider.dart` — `StateNotifierProvider<AuthNotifier, AuthState>`; holds user, isLoading, error, isInitialized flags
- `screens/` — Organized by role: `auth/`, `customer/room/`, `admin/`, `home/`

State flow: login → `authProvider` updates → GoRouter redirects based on role.

## Key Configuration

**Backend** (`backend/src/main/resources/application.properties`):
- Server: port `8080`, context path `/api`
- Database: SQL Server at `localhost:1433`, DB name `GenzCinemaHotel`
- JWT expiry: 24 hours (`app.jwt.expiration=86400000`)
- Password reset token expiry: 15 minutes

**Mobile** — API base URL and role constants are in `mobile/lib/config/app_config.dart`. Update the base URL here when switching environments (local vs device vs emulator — emulator uses `10.0.2.2` to reach host localhost). `baseUrl` can also be overridden without editing code: `flutter run -d chrome --dart-define=API_URL=http://localhost:8080/api` (Chrome must run on port 3000 to pass the backend CORS list: `--web-port 3000`).

## API Surface

```
POST  /api/auth/login              # public
POST  /api/auth/register           # public
POST  /api/auth/request-reset      # public
GET   /api/auth/verify-token       # public
POST  /api/auth/reset-password     # public

GET   /api/rooms                   # authenticated
GET   /api/rooms/available
GET   /api/rooms/hotel/{hotelId}
GET   /api/rooms/{id}
POST  /api/rooms                   # ADMIN, STAFF
PUT   /api/rooms/{id}              # ADMIN, STAFF
DELETE /api/rooms/{id}             # ADMIN, STAFF

GET   /api/bookings                # ADMIN, STAFF
GET   /api/bookings/user/{userId}
GET   /api/bookings/{id}
POST  /api/bookings                # status is always set to PENDING
PUT   /api/bookings/{id}/status    # ADMIN, STAFF

GET   /api/admin/users             # ADMIN only (whole AdminController)
PUT   /api/admin/users/{id}/role?roleId=CUSTOMER|STAFF   # cannot touch ADMIN accounts
PUT   /api/admin/users/{id}/lock?locked=true|false       # locked users cannot log in; old tokens stop working
GET   /api/admin/stats?period=day|week|month             # StatsService: 7 days / 8 weeks / 6 months, revenue = COMPLETED bookings by checkIn date
```

## Development Notes

- Error messages and email templates are in Vietnamese (UTF-8)
- `spring.jpa.hibernate.ddl-auto=none` — Hibernate does not change the schema. Run `SQLQuery1.sql`, then `sprint_foundation.sql` (repo root) once (tables Voucher/Review/Notification, `User.IsLocked`, test accounts, sample data).
- The team is new to Spring/Java: keep code simple (plain entities, derived repository methods, `FetchType.EAGER`, no custom JPQL or advanced annotations).
- Booking statuses: `constant/BookingStatus` / `AppConfig.booking*` — `PENDING, CONFIRMED, REJECTED, CHECKED_IN, COMPLETED, CANCELLED`. Room statuses: `constant/RoomStatus` / `AppConfig.room*` — `Trống, Đang dùng, Đang dọn`.
- `@EnableMethodSecurity` is on, so `@PreAuthorize("hasRole(...)")` works (`ROLE_` + RoleId). SecurityConfig paths are relative to the `/api` context path: `/auth/**`, not `/api/auth/**`.
- After modifying any Riverpod `@riverpod`-annotated provider, run `build_runner build` to regenerate `.g.dart` files
