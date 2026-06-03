# Tattoo - NTUT Course Assistant

Flutter app for NTUT students: course schedules, scores, enrollment, announcements.

Follow @CONTRIBUTING.md for git operation guidelines.

When making changes that add, remove, or alter conventions, patterns, or architectural structure described here, update this document in the same PR.

## Architecture

MVVM pattern with Riverpod for DI and reactive state (manual providers, no codegen):

- UI calls repository actions directly via constructor providers (`ref.read`)
- UI observes data through screen-level StreamProviders backed by Drift `.watch()` queries (`ref.watch`)
- Repositories encapsulate business logic, coordinate Services (HTTP) and Database (Drift)

**Code generation:** Run `dart run build_runner build` (Drift) and `dart run slang` (i18n) after modifying annotated source files or i18n YAMLs. Commit generated files (`.g.dart`) alongside source changes.

**Credentials:** `tool/credentials.dart` manages encrypted credentials from the `tattoo-credentials` Git repo. Run `dart run tool/credentials.dart fetch` to decrypt and place Firebase configs, Android keystore, and service account. Config from env vars or `.env` file.

**HTML snapshot capture:** `tool/html_snapshot.dart` captures raw NTUT HTML/XML responses for parser development. Supporting part files live under `tool/html_snapshot/`; presets live in `tool/html_snapshot/presets.dart`. The CLI reads `test/test_config.json` and writes local-only files under `tmp/html_snapshot/`. `capture <preset> [<preset>...] -m "<message>"` captures one or more known pages, and `capture -a -m "<message>"` captures presets that can be resolved without explicit IDs. Raw captures may contain personal data and must not be committed before de-identification. Promoted snapshots must keep a meaningful metadata `message`; replace a `message:` TODO placeholder before promotion because message-less snapshots are not accepted. The parser expected-result TODO is separate from `message` and may remain until the HTML-based test code is complete.
Use `-q` / `--quiet` on capture commands when request paths or errors may expose sensitive URL content; this suppresses HTTP request logs and redacts request URLs in quiet-mode Dio errors.

**Structure:**

- `lib/components/` - Reusable UI widgets
- `lib/database/` - Drift schema, database class, and views
- `lib/i18n/` - slang i18n YAML sources and generated strings
- `lib/models/` - Shared domain enums and types
- `lib/repositories/` - Repository class + constructor provider (DI wiring)
- `lib/router/` - go_router config (`app_router.dart`)
- `lib/screens/` - Screen widgets organized by feature: `welcome/` (intro, login) and `main/` (home, course_table, score, calendar, portal, scanner, kiosk_login, profile). 4-tab `StatefulShellRoute` with `AnimatedShellContainer` for tab state preservation. Each tab owns its own `Scaffold`.
- `lib/services/` - Clients that talk to external systems (NTUT HTTP services, Firebase, etc.) and `demo_mode.dart`
- `lib/shells/` - Layout shells (AnimatedShellContainer for tab transitions, ShowcaseShell for onboarding)
- `lib/utils/` - HTTP utilities (cookie jar, interceptors, native adapter), localization, avatar payload
- `tool/` - Dart CLI tools (credentials management, HTML/XML snapshot capture)

**Provider placement:**

- Constructor providers (DI wiring) are co-located with the classes they construct (services, database, repositories)
- Screen-specific providers live alongside the screen that consumes them (e.g., `screens/main/profile/profile_providers.dart`)
- Shared providers used by multiple screens in a feature live one level up
- Repository classes take framework-agnostic dependencies (callbacks, not Riverpod notifiers)

**Data Flow Pattern (per Flutter's architecture guide):**

- Services return DTOs as records (denormalized, as-parsed from HTML)
- Repositories transform DTOs → normalized DB → return DTOs or domain models
- UI consumes domain models (Drift entities or custom query result classes)
- Repositories handle impedance mismatch between service data and DB structure

**Terminology:**

- **DTOs**: Dart records defined in service files - lightweight data transfer objects
- **Domain models**: Drift entities, Drift view data classes, or custom query result classes - what UI consumes

**Services:**

- **Architecture:** NTUT services (Portal, Course, ISchoolPlus, StudentQuery) use `abstract interface class` with concrete implementations (e.g., `NtutPortalService`). Files are grouped by subdirectory (e.g., `lib/services/portal/`). Interfaces, DTOs, and providers live in the interface file, while logic lives in the implementation file. Consumers only import the interface file. Service providers check `isDemoProvider` — when true, they return mock implementations instead of real NTUT clients.
- PortalService — Portal auth, SSO, user profile (avatar, password). Also serves academic calendar events (calModeApp.do JSON API)
- CourseService — 課程系統 (`aa_0010-oauth`). Course catalog, schedules, teacher profiles, syllabi. All HTML-parsed.
- ISchoolPlusService — 北科i學園PLUS (`ischool_plus_oauth`). Course rosters and materials.
- StudentQueryService — 學生查詢專區 (`sa_003_oauth`). Academic records, GPA, rankings, registration history.
- GitHubService — fetches repo contributors, filters bots
- FirebaseService — Unified wrapper for Firebase Analytics and Crashlytics. Gated by compile-time `USE_FIREBASE` flag (`--dart-define=USE_FIREBASE=true`), defaults to `false` to avoid package name mismatch in debug builds. Callers use null-aware access (`firebase.analytics?.logAppOpen()`)
- NTUT services share single cookie jar (NTUT session state)
- NTUT services return DTOs as records — no database writes
- DTOs are typedef'd records co-located with service interfaces
- **Integration tests:** copy `test/test_config.json.example` to `test/test_config.json`, then run `flutter test --dart-define-from-file=test/test_config.json -r failures-only`
- **Capture presets:** when adding or changing a Service-layer HTML/XML request or parser, check related integration tests and update `tool/html_snapshot/presets.dart` presets if the request is not already covered.

**Repositories:**

- AuthRepository — User identity, session, profile. Lazy auth via `withAuth<T>()` with SSO and re-auth coalescing (Completer pattern). Session persistence via flutter_secure_storage. Never-completing future on auth failure (harmless — session-scoped providers are already being disposed).
- PreferencesRepository — Typed `PrefKey<T>` enum with SharedPreferencesAsync. Cloud sync via avatar payload.
- CourseRepository — Course catalog, schedules, and offering details. Normalizes bilingual names from multiple sources (catalog vs offering). Layout computation for course table grid (multi-period spans, noon-crossing, unscheduled courses).
- CalendarRepository — Academic calendar events from NTUT portal. Sliding window caching keyed to enrolled semesters.
- StudentRepository — Academic records, GPA, rankings. Parallel course code resolution via CourseRepository.getCourse().
- **Method pattern:** `watchX()` returns a `Stream` backed by Drift `.watch()` — emits cached data immediately, then background-fetches if empty or stale (each method has its own hard-coded TTL `const`). Network errors are absorbed (stale data preferred over errors). `refreshX()` is the imperative counterpart for pull-to-refresh — fetches from network, writes to DB, and lets the stream re-emit.

**Demo mode:**

`isDemoProvider` (`Notifier<bool>`) toggles demo mode at runtime. Enabled when logging in with `demoUsername` ('111592347' — structurally invalid NTUT ID, any password accepted). When active, all four NTUT service providers return mock implementations with realistic per-semester data. Demo mode deliberately skips secure storage — session persists via DB user row check instead.

## Database

**Migrations:** No migration strategy until first release. Schema changes are made directly — the database is recreated on each install during development.

**Cache Timestamps:** For data that doesn't have its own `fetchedAt` column, add a nullable `{feature}FetchedAt` column on the parent row's table (e.g., `Semesters.courseTableFetchedAt` for per-semester course table cache). For data with no natural parent row (e.g., the semester list itself), use a column on the `Users` table.

**Indexing Strategy:**

- Avoid premature optimization - this is a personal data app with small datasets (~60-70 courses per student)
- Current indexes are minimal and focused on existing query patterns
- **When to add new indexes:** When implementing a new feature that introduces SQL queries filtering/joining on non-indexed columns
- **Junction table indexes:** Composite PKs only support left-to-right lookups. Add separate index if querying by second column alone
  - Example: `CourseOfferingStudents` PK `{courseOffering, student}` supports "students in course" but NOT "courses for student"
  - Add `course_offering_student_student` index when implementing student transcript/history queries
- **Naming convention:** `table_column` (following Drift examples)
- Monitor storage/performance before adding more indexes
- **Single-user assumption:** `UserRegistrations` view omits the `user` column — add it and update `getActiveRegistration` filter if multi-user support is introduced

## Testing Strategy

| Layer | Test type | Mock strategy | Runs in CI |
| --- | --- | --- | --- |
| NTUT services | Integration (real server) | None — tests hit real NTUT | Only with credentials |
| Repositories | Unit | Mock NTUT service interfaces (return canned DTOs) | Always |
| Utils | Unit | None needed (pure functions) | Always |
| Database views | Unit (in-memory SQLite) | None needed (Drift test utilities) | Always |
| Widgets | Widget tests | Low priority | Always |

- **NTUT services** (Portal, Course, ISchoolPlus, StudentQuery) have `abstract interface class` — mock implementations return canned DTOs for repository unit tests and demo mode
- **Non-NTUT services** (GitHubService, FirebaseService) do not need mock implementations — they have stable API contracts
- **No fixtures:** Service-layer tests stay integration-only against real NTUT servers. Fixtures (HTML snapshots) would go stale silently; integration tests are the source of truth for parsing correctness.

## NTUT-Specific Patterns

**HTML Parsing:** NTUT has no REST APIs. Parse HTML responses with `html` package.

**Shared Cookie Jar:** Single cookie jar across all clients for simpler implementation.

**SSO Flow:** PortalService centralizes auth services. The SSO uses OAuth2 authorization code flow: `ssoIndex.do` returns an auto-submitting form that POSTs to `oauth2Server.do`, which 302-redirects to the target service's login endpoint with a `code` parameter (e.g., `LoginOAuthCourseCH.jsp?code=...`). This code URL is **reusable** and **cookie-independent** — any HTTP client (including a system browser) can open it to establish an authenticated session. `PortalService.getSsoUrl(apOu)` captures this URL by cloning the Dio instance without `RedirectInterceptor` to intercept the 302 Location header.

**User-Agent:** PortalService uses `app.ntut.edu.tw` endpoints designed for the official NTUT iOS app (`User-Agent: Direk ios App`). This bypasses login captcha that the web portal (`nportal.ntut.edu.tw`) requires. Without the correct User-Agent, the server will refuse requests. Browser-based testing of these endpoints won't work.

**Localized String Helper:** `localized(zh, en)` in `lib/utils/localized.dart` picks the appropriate string based on device locale — Chinese (zh_TW) prefers `zh` with `en` fallback, all other locales prefer `en` with `zh` fallback. Use this when NTUT services return both Chinese and English data.

**Session Expiry Detection:** NTUT services return HTTP 200 with error pages instead of 401/403 when sessions expire. Per-service Dio interceptors detect known markers (e.g., "應用系統已中斷連線" for StudentQuery, "尚未登錄入口網站" for Course) and throw `SessionExpiredException`. This is a non-DioException so `withAuth` catches it and triggers re-authentication. iSchool+ returns HTTP 403 when unauthenticated, handled via `onError` interceptor.

**SSO Coalescing:** `AuthRepository._ensureSso` uses `Completer`-based coalescing — first caller creates a Completer and fires SSO, concurrent callers await the same future. Prevents redundant SSO calls during parallel repository fetches.

**Re-auth Coalescing:** `AuthRepository._reauthenticate` uses the same `Completer` pattern — first caller triggers login, concurrent callers await the same future. Prevents redundant login attempts when multiple `withAuth` calls detect session expiry simultaneously.

**Session Lifecycle:** `sessionProvider` (`Notifier<bool>`) drives auth state. `true` = authenticated, `false` = unauthenticated. Router guard watches it for redirect. Repository providers `ref.watch(sessionProvider)` to be recreated with fresh state when the session ends. On auth failure, `withAuth` destroys the session and returns a never-completing `Completer<T>().future` — session-scoped providers are already being disposed by the time callers would stall, so the hanging future is harmless. Callers only need to handle `DioException` for network failures.

**Campus Wi-Fi TLS DPI Bypass:** `native_dio_adapter` routes HTTPS through Cronet (Android) and URLSession (iOS), whose TLS ClientHello fingerprints pass campus DPI. Dart's default BoringSSL gets RST'd. Only active on Android/iOS — desktop and web use dart:io's default client.

**NullHeaderInterceptor:** `dio_cookie_manager` injects `Cookie: null` when no cookies exist for a domain. NTUT's BigIP ASM flags this as bot behavior (HTTP 403). The interceptor strips null-value Cookie headers before requests are sent.

**InvalidCookieFilter:** iSchool+ returns malformed cookies. Additionally, NativeAdapter (Cronet/URLSession) comma-joins multiple Set-Cookie values into a single header entry. The interceptor splits them before validation so one invalid cookie doesn't discard valid ones.

**Connection: close:** PortalService uses `Connection: close` header. NTUT portal servers close keep-alive connections after multipart uploads, causing stale socket errors if Dart's HTTP client tries to reuse them.

### NTUT Portal apOu Codes

All available SSO service codes are in `doc/ntut_sso_codes.md`.

These apOu codes are the SSO target identifiers used by PortalService to obtain service-specific entry URLs/tickets for each NTUT subsystem.

## Backlog

Open work is tracked in [GitHub Issues](https://github.com/NTUT-NPC/tattoo/issues). Key areas: remaining NTUT service methods (ISchoolPlus announcements, StudentQuery extensions), repository layer gaps (materials, rosters), and file download infrastructure.
