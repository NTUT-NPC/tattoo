# Tattoo - NTUT Course Assistant

Flutter app for NTUT students: course schedules, scores, enrollment, announcements.

Follow @CONTRIBUTING.md for git operation guidelines.

**Last updated:** 2026-02-27. If stale (>30 days), verify Status section against codebase.

## Status

**Done:**

- PortalService (auth+SSO, getSsoUrl for system browser auth, changePassword, getAvatar, uploadAvatar), CourseService (HTML parsing), ISchoolPlusService (getStudents, getMaterials, getMaterial)
- StudentQueryService (getAcademicPerformance, getRegistrationRecords, getGradeRanking, getStudentProfile)
- HTTP utils, InvalidCookieFilter interceptor
- Drift database schema with all tables
- Service DTOs migrated to Dart 3 records
- Repository stubs (AuthRepository, CourseRepository)
- Riverpod setup (manual providers, no codegen — riverpod_generator incompatible with Drift-generated types)
- Service integration tests (copy `test/test_config.json.example` to `test/test_config.json`, then run `flutter test --dart-define-from-file=test/test_config.json -r failures-only`)
- AuthRepository implementation (login, logout, lazy auth via `withAuth<T>()`, session persistence via flutter_secure_storage)
- go_router navigation setup
- UI: intro screen, login screen, home screen with bottom navigation bar and three tabs (table, score, profile). Uses `StatefulShellRoute` with `AnimatedShellContainer` for tab state preservation and cross-fade transitions. Each tab owns its own `Scaffold`.
- i18n (zh_TW, en_US) via slang

**Todo - Service Layer:**

- ISchoolPlusService: getCourseAnnouncement, getCourseAnnouncementDetail, courseSubscribe, getCourseSubscribe, getSubscribeNotice
- CourseService: getDepartmentMap, getCourseCategory
- CourseService (English): Parse English Course System (`/course/en/`) for English names (courses, teachers, syllabus)
- StudentQueryService (sa_003_oauth - 學生查詢專區):
  - getGPA (學期及歷年GPA查詢)
  - getMidtermWarnings (期中預警查詢)
  - getStudentAffairs (獎懲、缺曠課、請假查詢)
  - getStudentLoan (就學貸款資料查詢)
  - getGeneralEducationDimension (查詢已修讀博雅課程向度)
  - getEnglishProficiency (查詢英語畢業門檻登錄資料)
  - getExamScores (查詢會考電腦閱卷成績)
  - getClassAndMentor (註冊編班與導師查詢)
  - updateContactInfo (維護個人聯絡資料)
  - getGraduationQualifications (查詢畢業資格審查)
- PortalService: getCalendar

**Todo - Repository Layer:**

- Implement CourseRepository methods (schedules, materials, rosters, caching)
- StudentRepository stub and implementation (grades, GPA, rankings)

**Todo - App:**

- UI: course table, course detail, scores
- File downloads (progress tracking, notifications, cancellation)

## Architecture

MVVM pattern with Riverpod for DI and reactive state:

- UI calls repository actions directly via constructor providers (`ref.read`)
- UI observes data through screen-level FutureProviders (`ref.watch`)
- Repositories encapsulate business logic, coordinate Services (HTTP) and Database (Drift)

**Credentials:** `tool/credentials.dart` manages encrypted credentials from the `tattoo-credentials` Git repo. Run `dart run tool/credentials.dart fetch` to decrypt and place Firebase configs, Android keystore, and service account. Compatible with match_keystore encryption format (AES-256-CBC, PBKDF2). Config from env vars or `.env` file.

**Structure:**

- `tool/` - Dart CLI tools (credentials management)
- `lib/models/` - Shared domain enums (DayOfWeek, Period, CourseType, ScoreStatus)
- `lib/repositories/` - Repository class + constructor provider (DI wiring)
- `lib/services/` - Clients that talk to external systems (NTUT HTTP services, Firebase, etc.)
- `lib/database/` - Drift schema and database class
- `lib/utils/` - HTTP utilities (cookie jar, interceptors)
- `lib/i18n/` - slang i18n YAML sources and generated strings
- `lib/components/` - Reusable UI widgets (AppSkeleton, notices, OptionEntryTile, SectionHeader)
- `lib/router/` - go_router config and AnimatedShellContainer for tab transitions
- `lib/screens/` - Screen widgets organized by feature (welcome/, main/)

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

- PortalService - Portal auth, SSO
- CourseService - 課程系統 (`aa_0010-oauth`)
- ISchoolPlusService - 北科i學園PLUS (`ischool_plus_oauth`)
- StudentQueryService - 學生查詢專區 (`sa_003_oauth`)
- FirebaseService - Unified wrapper for Firebase Analytics and Crashlytics with global `useFirebase` toggle
- NTUT services share single cookie jar (NTUT session state)
- NTUT services return DTOs as records (UserDto, SemesterDto, ScheduleDto, etc.) - no database writes
- DTOs are typedef'd records co-located with service implementation

**Repositories:**

- AuthRepository - User identity, session, profile
- CourseRepository - Course schedules, catalog, materials, rosters, announcements
- StudentRepository (TODO) - Grades, GPA, rankings, warnings, graduation status
- Transform DTOs into relational DB tables
- Return DTOs or domain models to UI
- Handle data persistence and caching strategies
- **Method pattern (AuthRepository):** `getX({refresh})` methods use `fetchWithTtl` helper for smart caching - returns cached data if fresh (within TTL), fetches from network if stale. Set `refresh: true` to bypass TTL (pull-to-refresh). Internal `_fetchXFromNetwork()` methods handle network fetch logic. Special cases that only need partial data (e.g., `getAvatar()` only needs `avatarFilename`) query DB directly. Follow this pattern when implementing other repositories.

## Database Performance

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

## NTUT-Specific Patterns

**HTML Parsing:** NTUT has no REST APIs. Parse HTML responses with `html` package.

**Shared Cookie Jar:** Single cookie jar across all clients for simpler implementation.

**SSO Flow:** PortalService centralizes auth services. The SSO uses OAuth2 authorization code flow: `ssoIndex.do` returns an auto-submitting form that POSTs to `oauth2Server.do`, which 302-redirects to the target service's login endpoint with a `code` parameter (e.g., `LoginOAuthCourseCH.jsp?code=...`). This code URL is **reusable** and **cookie-independent** — any HTTP client (including a system browser) can open it to establish an authenticated session. `PortalService.getSsoUrl(apOu)` captures this URL by cloning the Dio instance without `RedirectInterceptor` to intercept the 302 Location header.

**User-Agent:** PortalService uses `app.ntut.edu.tw` endpoints designed for the official NTUT iOS app (`User-Agent: Direk ios App`). This bypasses login captcha that the web portal (`nportal.ntut.edu.tw`) requires. Without the correct User-Agent, the server will refuse requests. Browser-based testing of these endpoints won't work.

**InvalidCookieFilter:** iSchool+ returns malformed cookies; custom interceptor filters them.

**Connection: close:** PortalService uses `Connection: close` header. NTUT portal servers close keep-alive connections after multipart uploads, causing stale socket errors if Dart's HTTP client tries to reuse them.

### NTUT Portal apOu Codes

All available SSO service codes are in to `doc/ntut_sso_codes.md`.

These apOu codes are the SSO target identifiers used by PortalService to obtain service-specific entry URLs/tickets for each NTUT subsystem.
