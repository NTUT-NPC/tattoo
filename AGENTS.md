# Tattoo - NTUT Course Assistant

Flutter app for NTUT students: course schedules, scores, enrollment, announcements.

Follow @CONTRIBUTING.md for git operation guidelines.

**Last updated:** 2026-03-21. If stale (>7 days), verify Status section against codebase.

## Status

**Done:**

- PortalService (auth+SSO, getSsoUrl for system browser auth, changePassword, getAvatar, uploadAvatar, getCalendar), CourseService (HTML parsing), ISchoolPlusService (getStudents, getMaterials, getMaterial), StudentQueryService (getAcademicPerformance, getRegistrationRecords, getGradeRanking, getStudentProfile, getGpa), GitHubService
- Service integration tests (copy `test/test_config.json.example` to `test/test_config.json`, then run `flutter test --dart-define-from-file=test/test_config.json -r failures-only`)
- Drift database schema with all tables, views (ScoreDetails, UserAcademicSummaries)
- Service DTOs migrated to Dart 3 records
- AuthRepository implementation (login, logout, lazy auth via `withAuth<T>()`, session persistence via flutter_secure_storage, SSO coalescing via Completer, re-auth coalescing via Completer), PreferencesRepository, CourseRepository: getSemesters, getCourseTable (with TTL caching), getCourse (single course lookup with TTL)
- Session-scoped providers: `sessionProvider` (bool) drives router guard and repository lifecycle. Auth failure destroys session → router redirects to login → session-scoped repositories are recreated with fresh state
- StudentRepository: getSemesterRecords (scores, GPA, rankings with TTL caching, parallel course code resolution)
- Session expiry detection: per-service Dio interceptors detect NTUT fake-200 expired sessions, throw `SessionExpiredException` for `withAuth` retry
- Riverpod setup (manual providers, no codegen — riverpod_generator incompatible with Drift-generated types)
- go_router navigation setup
- UI: intro screen, login screen, home screen with bottom navigation bar and three tabs (table, score, profile), about, easter egg, ShowcaseShell. Home uses `StatefulShellRoute` with `AnimatedShellContainer` for tab state preservation and cross-fade transitions. Each tab owns its own `Scaffold`.
- i18n (zh_TW, en_US) via slang
- Mock NTUT service implementations (MockPortalService, MockCourseService, MockISchoolPlusService, MockStudentQueryService) for repository unit tests and future demo/offline mode

**Todo - Service Layer:**

- ISchoolPlusService: getCourseAnnouncement, getCourseAnnouncementDetail, courseSubscribe, getCourseSubscribe, getSubscribeNotice
- CourseService: getDepartmentMap, getCourseCategory
- CourseService (English): Parse English Course System (`/course/en/`) for English names (syllabus, teacher profiles)
- StudentQueryService (sa_003_oauth - 學生查詢專區):
  - getMidtermWarnings (期中預警查詢)
  - getStudentAffairs (獎懲、缺曠課、請假查詢)
  - getStudentLoan (就學貸款資料查詢)
  - getGeneralEducationDimension (查詢已修讀博雅課程向度)
  - getEnglishProficiency (查詢英語畢業門檻登錄資料)
  - getExamScores (查詢會考電腦閱卷成績)
  - getClassAndMentor (註冊編班與導師查詢)
  - updateContactInfo (維護個人聯絡資料)
  - getGraduationQualifications (查詢畢業資格審查)

**Todo - Repository Layer:**

- Implement remaining CourseRepository methods (materials, rosters, announcements)
- Implement remaining StudentRepository methods (midterm warnings, student affairs, graduation status)

**Todo - App:**

- UI: course table, course detail, scores
- File downloads (progress tracking, notifications, cancellation)
- Global `connectivityProvider` for offline state (e.g., connectivity banner) — separate from auth

## Architecture

MVVM pattern with Riverpod for DI and reactive state (manual providers, no codegen — riverpod_generator incompatible with Drift-generated types):

- UI calls repository actions directly via constructor providers (`ref.read`)
- UI observes data through screen-level FutureProviders (`ref.watch`)
- Repositories encapsulate business logic, coordinate Services (HTTP) and Database (Drift)

**Code generation:** Run `dart run build_runner build` (Drift, Riverpod) and `dart run slang` (i18n) after modifying annotated source files or i18n YAMLs. Commit generated files (`.g.dart`) alongside source changes.

**Credentials:** `tool/credentials.dart` manages encrypted credentials from the `tattoo-credentials` Git repo. Run `dart run tool/credentials.dart fetch` to decrypt and place Firebase configs, Android keystore, and service account. Config from env vars or `.env` file.

**Structure:**

- `lib/components/` - Reusable UI widgets (AppSkeleton, notices, OptionEntryTile, SectionHeader)
- `lib/database/` - Drift schema and database class
- `lib/i18n/` - slang i18n YAML sources and generated strings
- `lib/models/` - Shared domain enums (DayOfWeek, Period, CourseType, ScoreStatus)
- `lib/repositories/` - Repository class + constructor provider (DI wiring)
- `lib/router/` - go_router config and AnimatedShellContainer for tab transitions
- `lib/screens/` - Screen widgets organized by feature (welcome/, main/). Home uses `StatefulShellRoute` with `AnimatedShellContainer` for tab state preservation and cross-fade transitions. Each tab owns its own `Scaffold`.
- `lib/services/` - Clients that talk to external systems (NTUT HTTP services, Firebase, etc.)
- `lib/shells/` - Layout shells (AnimatedShellContainer for tab transitions, ShowcaseShell for onboarding)
- `lib/utils/` - HTTP utilities (cookie jar, interceptors)
- `tool/` - Dart CLI tools (credentials management)

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

- **Architecture:** NTUT services (Portal, Course, ISchoolPlus, StudentQuery) use `abstract interface class` with concrete implementations (e.g., `NtutPortalService`) to enable mock implementations for repository unit tests and future demo/offline mode. Files are grouped by subdirectory (e.g., `lib/services/portal/`). Interfaces, DTOs, and providers live in the interface file, while logic lives in the implementation file. Consumers only import the interface file.
- PortalService - Portal auth, SSO (auth+SSO, getSsoUrl, changePassword, getAvatar, uploadAvatar, getCalendar - academic calendar events via calModeApp.do JSON API)
- CourseService - 課程系統 (`aa_0010-oauth`) — HTML parsing
- ISchoolPlusService - 北科i學園PLUS (`ischool_plus_oauth`) — getStudents, getMaterials, getMaterial
- StudentQueryService - 學生查詢專區 (`sa_003_oauth`) — getAcademicPerformance, getRegistrationRecords, getGradeRanking, getStudentProfile, getGpa
- GitHubService - fetches repo contributors, filters bots
- FirebaseService - Unified wrapper for Firebase Analytics and Crashlytics. Gated by compile-time `USE_FIREBASE` flag (`--dart-define=USE_FIREBASE=true`), defaults to `false` to avoid package name mismatch in debug builds. Callers use null-aware access (`firebase.analytics?.logAppOpen()`)
- NTUT services share single cookie jar (NTUT session state)
- NTUT services return DTOs as records (UserDto, SemesterDto, ScheduleDto, etc.) - no database writes
- DTOs are typedef'd records co-located with service interfaces
- **Integration tests:** copy `test/test_config.json.example` to `test/test_config.json`, then run `flutter test --dart-define-from-file=test/test_config.json -r failures-only`

**Repositories:**

- AuthRepository - User identity, session, profile. Implemented: login, logout, `withAuth<T>()` (lazy auth with re-auth coalescing, never-completing future on auth failure), session persistence via flutter_secure_storage
- PreferencesRepository - Typed `PrefKey<T>` enum with SharedPreferencesAsync
- CourseRepository - Implemented: getSemesters, getCourseTable (with TTL caching, DB persistence, bilingual names), getCourse (single course lookup with TTL). Stubs: getCourseOffering, getCourseDetails, getMaterials, getStudents
- StudentRepository - Implemented: getSemesterRecords (scores, GPA, rankings with TTL caching, parallel course code resolution via CourseRepository.getCourse). Uses Drift views (ScoreDetails, UserAcademicSummaries) as domain models.
- Transform DTOs into relational DB tables
- Return DTOs or domain models to UI
- Handle data persistence and caching strategies
- **Method pattern (AuthRepository):** `getX({refresh})` methods use `fetchWithTtl` helper for smart caching - returns cached data if fresh (within TTL), fetches from network if stale. Set `refresh: true` to bypass TTL (pull-to-refresh). Internal `_fetchXFromNetwork()` methods handle network fetch logic. Special cases that only need partial data (e.g., `getAvatar()` only needs `avatarFilename`) query DB directly. Follow this pattern when implementing other repositories.

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
|---|---|---|---|
| NTUT services | Integration (real server) | None — tests hit real NTUT | Only with credentials |
| Repositories | Unit | Mock NTUT service interfaces (return canned DTOs) | Always |
| Utils | Unit | None needed (pure functions) | Always |
| Database views | Unit (in-memory SQLite) | None needed (Drift test utilities) | Always |
| Widgets | Widget tests | Low priority | Always |

- **NTUT services** (Portal, Course, ISchoolPlus, StudentQuery) have `abstract interface class` — mock implementations return canned DTOs for repository unit tests and future demo/offline mode
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

**Session Lifecycle:** `sessionProvider` (`Notifier<bool>`) drives auth state. `true` = authenticated, `false` = unauthenticated. Router guard watches it for redirect. Repository providers `ref.watch(sessionProvider)` to be recreated with fresh state when the session ends. On auth failure, `withAuth` destroys the session and returns a never-completing `Completer<T>().future` — callers never see auth errors, only `DioException` for network failures.

**InvalidCookieFilter:** iSchool+ returns malformed cookies; custom interceptor filters them.

**Connection: close:** PortalService uses `Connection: close` header. NTUT portal servers close keep-alive connections after multipart uploads, causing stale socket errors if Dart's HTTP client tries to reuse them.

### NTUT Portal apOu Codes

All available SSO service codes are in to `doc/ntut_sso_codes.md`.

These apOu codes are the SSO target identifiers used by PortalService to obtain service-specific entry URLs/tickets for each NTUT subsystem.
