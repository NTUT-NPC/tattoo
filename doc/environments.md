# Multi-Environment Build Configuration & Release Guide

This document describes the multi-environment build configuration architecture, configuration matrix, local development workflow, and CI/CD release pipelines for the Tattoo project.

---

## 1. Architecture Overview (Pure JSON Build Config Pattern)

Tattoo adopts **FatJohn's Pure JSON Build Config Pattern** to manage multi-environment builds across Android, iOS, and Dart/Flutter.

### Why Not Native Flutter Flavors?

Traditional Flutter flavor setups (`flutter run --flavor dev`) rely heavily on platform-native mechanisms:
- Android product flavors (`productFlavors`) inside Gradle.
- iOS Xcode schemes and duplicated build configurations (`Debug-dev`, `Release-prod`, etc.).

This native flavor approach introduces significant maintenance friction:
- Combinatorial explosions in Xcode project schemes and configurations.
- CocoaPods and SPM dependency linking issues across custom configuration names.
- Fragile CI scripts having to synchronize flavor names across Gradle, Xcode, Fastlane, and Flutter CLI.
- Build issues when third-party Flutter plugins only expect standard `Debug` and `Release` configurations.

### The Pure JSON Approach

Instead of native flavors, Tattoo uses centralized, schema-validated JSON files in `build_config/` as the single source of truth:

```
build_config/
├── schema.json          # JSON Schema defining configuration rules
├── development.json     # Development environment settings
├── production.json      # Production environment settings
├── dev.json -> development.json (alias)
└── prod.json -> production.json (alias)
```

Configuration variables are passed into builds through two complementary layers:

1. **Dart / Flutter Compilation Layer**:
   - Passed via `--dart-define-from-file=build_config/development.json` (or `production.json`).
   - Provides compile-time environment variables (`ENV`, `FLAVOR`, `APP_NAME`, etc.).
   - `lib/firebase_options.dart` detects `ENV` / `FLAVOR` at compile time and switches between development and production Firebase configurations without runtime overhead or package mismatch.

2. **Native Platform Layer (Android & iOS)**:
   - Synchronized before build using `dart run tool/credentials.dart configure --env=<dev|prod>` (or `fetch`).
   - **Android**:
     - `tool/credentials.dart configure` writes `android/app/app.properties`.
     - `android/app/build.gradle.kts` dynamically reads `app.properties` (or falls back to decoded `dart-defines`).
     - Dynamically sets `defaultConfig.applicationId` (`club.ntut.tattoo` vs `club.ntut.npc.tat`).
     - Injects `manifestPlaceholders["appLabel"]` for `AndroidManifest.xml` (`${appLabel}`).
     - Overlays `androidResDir` (`android/app/src/dev/res`) onto `sourceSets["main"]` for dev launcher icons.
     - Automatically registers `copyGoogleServices` to align `google-services.json`.
   - **iOS**:
     - `tool/credentials.dart configure` writes `ios/Flutter/AppConfig.xcconfig`.
     - Included directly in `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig`.
     - Dynamically overrides `PRODUCT_BUNDLE_IDENTIFIER`, `APP_CONFIG_NAME`, `BUNDLE_DISPLAY_NAME`, and `ASSETCATALOG_COMPILER_APPICON_NAME`.
     - `Info.plist` uses `$(APP_CONFIG_NAME)` and `$(PRODUCT_BUNDLE_IDENTIFIER)`.

---

## 2. Environment Matrix (4 Combinations)

Tattoo supports 2 environments (Development vs Production) across 2 platforms (Android vs iOS):

| Parameter | Dev Android | Dev iOS | Prod Android | Prod iOS |
|---|---|---|---|---|
| **Environment** | `development` (`dev`) | `development` (`dev`) | `production` (`prod`) | `production` (`prod`) |
| **App Name / Label** | Tattoo | Tattoo | TAT | TAT |
| **Package / Bundle ID** | `club.ntut.tattoo` | `club.ntut.tattoo` | `club.ntut.npc.tat` | `com.ntut.tatflutter` |
| **Launcher / App Icon** | `android/app/src/dev/res` (wireframe dev icon) | `AppIcon-dev` (`ios/Runner/AppIcon-dev.icon`) | `android/app/src/main/res` (classic TAT artwork) | `AppIcon` (`ios/Runner/Assets.xcassets`) |
| **Firebase Project** | `npc-tattoo` | `npc-tattoo` | `npc-tattoo-prod` | `npc-tattoo-prod` |
| **Firebase Storage** | `npc-tattoo.firebasestorage.app` | `npc-tattoo.firebasestorage.app` | `npc-tattoo-prod.firebasestorage.app` | `npc-tattoo-prod.firebasestorage.app` |

### Environment Details

1. **Dev Android (`club.ntut.tattoo`)**:
   - Application ID: `club.ntut.tattoo`
   - Label: `Tattoo`
   - Launcher Icon: Wireframe dev icon located in `android/app/src/dev/res`
   - Firebase: `npc-tattoo`

2. **Dev iOS (`club.ntut.tattoo`)**:
   - Bundle Identifier: `club.ntut.tattoo`
   - Display Name: `Tattoo`
   - App Icon: `AppIcon-dev` (wireframe dev icon)
   - Firebase: `npc-tattoo`

3. **Prod Android (`club.ntut.npc.tat`)**:
   - Application ID: `club.ntut.npc.tat` (legacy TAT Android package name for store upgrade continuity)
   - Label: `TAT`
   - Launcher Icon: Classic TAT icon located in `android/app/src/main/res`
   - Firebase: `npc-tattoo-prod`

4. **Prod iOS (`com.ntut.tatflutter`)**:
   - Bundle Identifier: `com.ntut.tatflutter` (legacy TAT iOS bundle identifier for App Store continuity)
   - Display Name: `TAT`
   - App Icon: `AppIcon` (classic TAT icon)
   - Firebase: `npc-tattoo-prod`

---

## 3. Local Development & Commands

### 3.1 Validating Build Configurations

Ensure all JSON configuration files match `build_config/schema.json`:

```bash
dart run tool/credentials.dart validate
```

### 3.2 Configuring the Environment

Generate native configuration files (`android/app/app.properties`, `ios/Flutter/AppConfig.xcconfig`, and placeholder Firebase configs if missing):

```bash
# Configure development environment
dart run tool/credentials.dart configure --env=dev

# Configure production environment
dart run tool/credentials.dart configure --env=prod
```

> **Note**: `dart run tool/credentials.dart generate --env=...` is an alias for `configure`.

### 3.3 Fetching & Decrypting Credentials

If you have access to the private credentials repository (`tattoo-credentials`):

```bash
# Fetch credentials for development
dart run tool/credentials.dart fetch --env=dev

# Fetch credentials for production
dart run tool/credentials.dart fetch --env=prod
```

**Offline / No Repo Access**:
If you do not have credentials repo access, `tool/credentials.dart configure --env=dev` automatically creates safe local stub files for `google-services.json` and `GoogleService-Info.plist` with dummy keys matching the package/bundle ID. This allows local compilation and UI development without access to production secrets.

### 3.4 Running Locally with Flutter CLI

Always run using `--dart-define-from-file` corresponding to your target environment:

```bash
# Run in Development mode (default)
dart run tool/credentials.dart configure --env=dev
flutter run --dart-define-from-file=build_config/development.json

# Run in Production mode
dart run tool/credentials.dart configure --env=prod
flutter run --dart-define-from-file=build_config/production.json
```

### 3.5 Building Locally with Flutter CLI

```bash
# Build Development APK
dart run tool/credentials.dart configure --env=dev
flutter build apk --dart-define-from-file=build_config/development.json

# Build Production Android App Bundle (AAB)
dart run tool/credentials.dart configure --env=prod
flutter build appbundle --dart-define-from-file=build_config/production.json

# Build Production iOS IPA
dart run tool/credentials.dart configure --env=prod
flutter build ipa --dart-define-from-file=build_config/production.json
```

---

## 4. CI/CD Release Workflows

Tattoo uses GitHub Actions and Fastlane to automate testing, build generation, and release distributions.

### 4.1 Production Release Workflow (`.github/workflows/production-release.yaml`)

This workflow prepares and releases **Production Release Candidates (RC)** for store deployment.

- **Triggers**:
  - Git tag push matching `v*` (e.g. `v2.0.0`, `v2.0.0-rc.1`).
  - Manual trigger via `workflow_dispatch` (with options for `dry_run`, `force_build`, specific branch or commit SHA).
- **Environment**: Configures `production` (`--env=prod`).
- **Distribution Targets**:
  - **Android**: Builds production AAB (`club.ntut.npc.tat`) and uploads to **Google Play Store Internal Testing Track**. Also builds release APK attached to the GitHub release.
  - **iOS**: Builds production IPA (`com.ntut.tatflutter`) and uploads to **TestFlight for Internal Testers ONLY** (`distribute_external: false`). Also attaches the `.ipa` to the GitHub release.

### 4.2 Daily Release Workflow (`.github/workflows/daily-release.yaml`)

This workflow generates nightly preview and development builds for internal and external testers.

- **Triggers**:
  - Scheduled daily at 05:00 UTC+8 (`0 21 * * *` UTC).
  - Manual trigger via `workflow_dispatch`.
- **Environment**: Configures `development` (`--env=dev`).
- **Distribution Targets**:
  - **Android**: Builds development APK (`club.ntut.tattoo`) for **Firebase App Distribution** (`dev-tester` group) and development AAB for Google Play Store testing.
  - **iOS**: Builds development IPA (`club.ntut.tattoo`) and uploads to **TestFlight** for internal and external testing groups.

### 4.3 Fastlane Lanes

Fastlane commands in `fastlane/Fastfile` are environment-aware:

#### iOS Lanes
- `fastlane ios release_prod`:
  - Builds production archive with `env: "prod"`, `bundle_identifier: "com.ntut.tatflutter"`.
  - Sets `internal_only: true` and `distribute_external: false` (uploads to TestFlight for Internal Testers only).
- `fastlane ios upload_testflight`:
  - General TestFlight upload lane supporting `env: "dev"` or `env: "prod"`.

#### Android Lanes
- `fastlane android release_prod`:
  - Builds production App Bundle with `env: "prod"`, `package_name: "club.ntut.npc.tat"`.
  - Uploads to Google Play Console on the Internal track (`track: "internal"`).
- `fastlane android build_apk`:
  - Builds APK for the specified `env` (`dev` or `prod`).
- `fastlane android build_appbundle`:
  - Builds App Bundle (AAB) for the specified `env`.
- `fastlane android upload_playstore`:
  - Uploads AAB to the designated Google Play track (`internal`, `beta`, etc.).
- `fastlane android upload_firebase`:
  - Uploads APK/AAB to Firebase App Distribution.
