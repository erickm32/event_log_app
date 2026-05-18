# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

The Flutter Android consumer app for the `sidekiqtraining` Rails API — a personal activity tracker that lets users log events (e.g., "ran 5km", "read 30 pages") and view their processing status.

The Rails backend runs separately at `http://localhost:5000` (or the deployed URL). This repo is the frontend only.

## Flutter Version

This project uses [FVM](https://fvm.app/) pinned to the `stable` channel (`.fvmrc`). Prefix all Flutter commands with `fvm`:

```bash
fvm flutter run          # Run on connected device/emulator
fvm flutter test         # Run all tests
fvm flutter test test/widget_test.dart   # Run a single test file
fvm flutter analyze      # Static analysis (flutter_lints rules)
fvm flutter build apk    # Build Android APK
fvm flutter pub get      # Install dependencies
```

## API Contract

The app talks to the Rails JSON API. Key behaviours to preserve:

- `POST /api/events` → `201 Created`, body contains event with `status: "pending"`
- Poll `GET /api/events/:id` until `status` transitions to `"processed"`
- Not-found errors: `{ "error": "message" }`
- Validation errors: field-keyed hash, e.g. `{ "name": ["can't be blank"] }`

### Domain Models

**Event** — `id`, `name` (required), `category_id`, `observation` (optional), `timestamp` (optional, defaults to `created_at`), `status` (`pending | processing | processed | failed`), `processed_at`

**Category** — `id`, `name` (required). Deleting a category is blocked if it has events.

### All Endpoints

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/events` | List all |
| GET | `/api/events/:id` | Single event |
| POST | `/api/events` | Create → triggers async processing |
| PATCH/PUT | `/api/events/:id` | Update |
| DELETE | `/api/events/:id` | Delete |
| GET | `/api/categories` | List all |
| GET | `/api/categories/:id` | Single category |
| POST | `/api/categories` | Create |
| PATCH/PUT | `/api/categories/:id` | Update |
| DELETE | `/api/categories/:id` | Delete (blocked if events exist) |

The full OpenAPI spec lives in the Rails project root (`openapi.yml`). To generate a Dart/Dio client from it:

```bash
openapi-generator generate -i ../sidekiqtraining/openapi.yml -g dart-dio -o lib/api
```

## Architecture (lib/)

```
lib/
  models/        # Event, Category — fromJson/toJson only, no logic
  services/      # ApiService — all HTTP calls, throws ApiException on errors
  screens/       # One file per screen, thin widgets that call services
  main.dart      # App shell with BottomNavigationBar (Events | Categories)
```

`ApiService` is instantiated once and passed down via `Provider`. Screens never call `http` directly — always through `ApiService`.

For Android emulator, use `http://10.0.2.2:5000` as base URL (emulator loopback to host). For a physical device or deployed API, swap the constant in `lib/services/api_service.dart`.

## Development Plan

| Level | Focus | Status |
|-------|-------|--------|
| 1 | Infrastructure: models, ApiService, app shell with bottom nav | ✅ Done |
| 2 | Events list screen — `GET /api/events`, status chips, loading/empty states | — |
| 3 | Create event — `POST /api/events`, form validation, inline API errors | — |
| 4 | Status polling — `Timer.periodic` on event detail after creation | — |
| 5 | Full CRUD — edit/delete events, categories screen | — |
| 6 | Riverpod migration — `AsyncNotifierProvider`, invalidate on mutation | — |
