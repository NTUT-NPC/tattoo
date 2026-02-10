# Tattoo - NTUT Course Assistant

Flutter app for NTUT students: course schedules, scores, enrollment, announcements.

Follow @CONTRIBUTING.md for git operation guidelines.

**Last updated:** 2026-02-10. If stale (>30 days), verify Status section against codebase.

## Status

**Done:**

- PortalService (auth+SSO, changePassword), CourseService (HTML parsing), ISchoolPlusService (getStudents, getMaterials, getMaterial)
- StudentQueryService (getAcademicPerformance, getRegistrationRecords, getGradeRanking, getStudentProfile)
- HTTP utils, InvalidCookieFilter interceptor
- Drift database schema with all tables
- Service DTOs migrated to Dart 3 records
- Repository stubs (AuthRepository, CourseRepository)
- Riverpod setup (manual providers, no codegen — riverpod_generator incompatible with Drift-generated types)
- Service integration tests (copy `test/test_config.json.example` to `test/test_config.json`, then run `flutter test --dart-define-from-file=test/test_config.json`)
- AuthRepository implementation (login, logout, lazy auth via `withAuth<T>()`, session persistence via flutter_secure_storage)
- go_router navigation setup
- UI: intro screen, login screen, home screen with bottom navigation bar and three tabs (table, score, profile). Uses `StatefulShellRoute` with `AnimatedShellContainer` for tab state preservation and cross-fade transitions. Each tab owns its own `Scaffold`.

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
- i18n (zh_TW, en_US)
- File downloads (progress tracking, notifications, cancellation)

## Architecture

MVVM pattern with Riverpod for DI and reactive state:
- UI calls repository actions directly via constructor providers (`ref.read`)
- UI observes data through screen-level FutureProviders (`ref.watch`)
- Repositories encapsulate business logic, coordinate Services (HTTP) and Database (Drift)

**Structure:**

- `lib/models/` - Shared domain enums (DayOfWeek, Period, CourseType, ScoreStatus)
- `lib/repositories/` - Repository class + constructor provider (DI wiring)
- `lib/services/` - HTTP clients, parse responses, return DTOs (as records)
- `lib/database/` - Drift schema and database class
- `lib/utils/` - HTTP utilities (cookie jar, interceptors)
- `lib/components/` - Reusable UI widgets (AppSkeleton)
- `lib/router/` - go_router config and AnimatedShellContainer for tab transitions
- `lib/screens/` - Screen widgets organized by feature (welcome/, main/)

**Provider placement:**
- Constructor providers (DI wiring) are co-located with the classes they construct (services, database, repositories)
- Screen-specific providers live alongside the screen that consumes them (e.g., `screens/main/course_table/course_table_providers.dart`)
- Shared providers used by multiple screens in a feature live one level up (e.g., `screens/main/course_providers.dart`)
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
- Design principle: Match NTUT's actual system boundaries. Each service corresponds to one NTUT SSO target.
- All share single cookie jar (NTUT session state)
- Return DTOs as records (UserDto, SemesterDto, ScheduleDto, etc.) - no database writes
- DTOs are typedef'd records co-located with service implementation

**Repositories:**

- AuthRepository - User identity, session, profile
- CourseRepository - Course schedules, catalog, materials, rosters, announcements
- StudentRepository (TODO) - Grades, GPA, rankings, warnings, graduation status
- Transform DTOs into relational DB tables
- Return DTOs or domain models to UI
- Handle data persistence and caching strategies

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

## NTUT-Specific Patterns

**HTML Parsing:** NTUT has no REST APIs. Parse HTML responses with `html` package.

**Shared Cookie Jar:** Single cookie jar across all clients for simpler implementation.

**SSO Flow:** PortalService centralizes auth services.

**User-Agent:** PortalService uses `app.ntut.edu.tw` endpoints designed for the official NTUT iOS app (`User-Agent: Direk ios App`). This bypasses login captcha that the web portal (`nportal.ntut.edu.tw`) requires. Without the correct User-Agent, the server will refuse requests. Browser-based testing of these endpoints won't work.

**InvalidCookieFilter:** iSchool+ returns malformed cookies; custom interceptor filters them.

### NTUT Portal apOu Codes

All available SSO service codes from nportal.ntut.edu.tw (50 total):

#### 教務系統 (Academic Affairs - aa)

- `aa_0010-oauth` - 課程系統 (Course System)
- `aa_003_LB_oauth` - 學業成績查詢專區 (Grade Inquiry) - redirects to `sa_003_oauth`
- `aa_003_oauth` - 學業成績查詢專區[二機] (Grade Inquiry - Server 2) - redirects to `sa_003_oauth`
- `aa_StuPhoto_oauth` - 新生電子大頭照上傳系統 (New Student Photo Upload)
- `aa_016_oauth` - 新生網路選課系統 (Freshman Course Selection)
- `aa_017_oauth` - 新生網路選課系統[二機] (Freshman Course Selection - Server 2)
- `aa_009_oauth` - 期末網路教學評量系統 (Teaching Evaluation)
- `aa_009_2_oauth` - 期末網路教學評量系統（二機） (Teaching Evaluation - Server 2)
- `aa_038_oauth` - 傑出教學獎票選系統 (Teaching Award Voting)
- `aa_011_oauth` - 期末網路預選系統 (Pre-selection)
- `aa_012_oauth` - 期末網路預選系統[二機] (Pre-selection - Server 2)
- `aa_030_oauth` - 開學後網路加退選系統 (Add/Drop Courses)
- `aa_030_2_oauth` - 開學後網路加退選系統[二機] (Add/Drop - Server 2)
- `aa_030_3_oauth` - 開學後網路加退選系統[三機] (Add/Drop - Server 3)
- `aa_Online+Course+Withdrawal+System_stu_oauth` - 期中網路撤選系統（學生） (Course Withdrawal)
- `aa_015_oauth` - 暑修需求登錄 (Summer Course Registration)
- `aa_029_oauth` - 製作暑修選課繳費單系統 (Summer Course Payment)
- `aa-gradu_oauth` - 畢業生離校系統 (Graduate Checkout)
- `aa_ParentSystem_oauth` - 家長系統（學生） (Parent System)
- `aa_easytest_oauth` - Easy test線上學習測驗平台
- `aa_027_oauth` - 外語中心資訊系統 (Language Center)
- `ischool_plus_oauth` - 北科i學園PLUS (iSchool Plus)
- `ar_OAUTH` - 新學術資源網 (Academic Resources)
- `StuETA_oauth` - 英文畢業門檻考試報名系統 (English Graduation Exam)
- `ezcard_oauth` - 學生證掛失及補發系統 (Student ID Loss Report)

#### 學務系統 (Student Affairs - sa)

- `sa_003_oauth` - 學生查詢專區 (Student Inquiry)
- `sa_005` - 學生停車證申請系統 (Parking Permit)
- `sa_007_oauth` - 學生宿舍登錄（抽籤）系統 (Dormitory Registration)
- `sa_009_oauth` - 器材租借系統 (Equipment Rental)
- `sa_010_oauth` - 學生請假系統 (Leave Request)
- `sa_SLAS_oauth` - 就學貸款申請系統 (Student Loan)
- `NTUT_exemption_OCE_oauth` - 學雜費減免及弱勢助學申請系統（進修部） (Tuition Exemption - Continuing Ed)
- `NTUT_exemption_oauth` - 學雜費減免及弱勢助學申請系統 (Tuition Exemption)
- `NTUT_scholarship_oauth` - 獎助學金申請系統 (Scholarship)
- `counseling_oauth` - 諮商預約系統 (Counseling Appointment)
- `Counselors_Activity_System_oauth` - 入班輔導活動系統 (Class Counseling Activity)

#### 總務系統 (General Affairs - ga)

- `ga_008_oauth` - 建物與設備維修通報單錄案系統 (Facility Maintenance Report)
- `ga_ghs_oauth` - 化學物質GHS管理系統 (Chemical GHS Management)
- `OnlinePayment_oauth` - 線上繳費系統 (Online Payment)

#### 研發系統 (Research & Development - rd)

- `rd_001_oauth` - 教師評鑑及基本資料庫 (Faculty Evaluation)
- `rd_003` - 產學合作資訊系統 (Industry-University Cooperation)
- `rnd-rs-oauth` - 研究獎助生申請系統 (Research Assistant)
- `rd_aes_oauth` - 學術倫理管理系統 (Academic Ethics)

#### 人事系統 (Personnel - per)

- `per_001_oauth` - 網路投票系統 (Online Voting)

#### 資訊服務 (Information Services - inf)

- `ipmac_oauth` - 網路與資訊安全管理系統 (Network & Info Security)
- `inf_vcp_oauth` - 北科 VCP-AI 運算平台 (VCP-AI Computing Platform)
- `inf001_oauth` - 校園授權軟體 (Campus Licensed Software)

#### 圖書館系統 (Library - lib)

- `lib_002_oauth2` - 圖書館入口網站 (Library Portal)

#### 其他 (Other)

- `zimbrasso_oauth` - 電子郵件 / 網路郵局WebMail (Email)
- `test_postman` - 臺北科大小郵差 (NTUT Postman)
