---
name: flutter-upgrade
description: Finish the migration commit on a Renovate-generated Flutter version PR — patch, minor, or major bumps. Use whenever a `renovate/flutter-*` PR appears, when the user says things like "do the flutter upgrade" or "bump flutter X to Y", or any time `mise.toml`'s `flutter = "X.Y.Z"` value changes.
---

## 1. Check out the PR

```bash
gh pr checkout <PR>
mise trust ./mise.toml         # mise.toml on a Renovate branch is not yet trusted
```

Use `gh pr checkout`, not `git worktree add origin/renovate/flutter-3.x` — the latter creates a parallel local branch that won't push back to the PR.

Read `mise.toml` to find the new Flutter version (the value of the `flutter` key). Use that version everywhere `<new-version>` appears below.

## 2. Update the hardcoded version references

Renovate only edits `mise.toml`. Two other files hardcode the same version and need to match — edit each one:

- **`.github/actions/setup-project/action.yml`** — find the version-guard line `if [ "$FLUTTER_VERSION" != "X.Y.Z" ]; then` and replace `X.Y.Z` with `<new-version>`. The line exists specifically to fail CI when these refs go out of sync.
- **`.github/renovate.json`** — under `"constraints"`, set `"flutter"` to `<new-version>`. Drives Renovate's pub-version resolution (<https://docs.renovatebot.com/configuration-options/#constraints>).

## 3. Reconcile Android NDK / CMake / SDK with runner image and Flutter

The Android SDK cache in `setup-project/action.yml` (currently keyed at `/usr/local/lib/android/sdk/cmake/3.22.1`) only works when three sources agree:

1. **Flutter's expected versions** at the new tag — read `FlutterExtension.kt`:

   ```bash
   gh api -H "Accept: application/vnd.github.raw" \
     "repos/flutter/flutter/contents/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt?ref=<new-version>"
   ```

   Look for `compileSdkVersion`, `minSdkVersion`, `targetSdkVersion`, `ndkVersion`. The CMake version comes from the project's `android/app/build.gradle.kts` or Flutter's gradle plugin defaults.

2. **What the runner image ships** — the Android SDK section of the runner README lists every preinstalled NDK and CMake version:
   - `ubuntu-latest` (currently Ubuntu 24.04): <https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md>
   - `macos-26`: <https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md>

3. **What the project pins** — read `android/app/build.gradle.kts`, `android/build.gradle.kts`, `android/settings.gradle.kts`, and the cache path in `.github/actions/setup-project/action.yml`. Look for `ndkVersion`, `compileSdk`, `minSdk`, `targetSdk`, and `cmake`.

If the runner image already ships the version Flutter expects, drop that path from the cache list in `action.yml` — caching what's preinstalled is wasted work. If the runner image doesn't ship it, keep or update the cache entry at the new path so Flutter's on-demand download persists between runs.

## 4. Diff against a fresh template

Generate a clean Flutter project from the new SDK and look for adoptable changes (gradle wrapper version, AGP/Kotlin pins, Podfile boilerplate, `MainActivity.kt`/`AppDelegate.swift` regen, etc.):

```bash
cd /tmp
rm -rf flutter_template_check
flutter create --org com.example --platforms android,ios flutter_template_check
diff -ruN flutter_template_check/ "$OLDPWD/" \
  | grep -vE '^Only in|\.dart_tool|/build/|\.lock$|\.g\.dart|\.firebase|GeneratedPluginRegistrant|test_config' \
  | less
```

Adopt template-driven updates selectively — never overwrite project files wholesale. Common things worth picking up: `android/gradle/wrapper/gradle-wrapper.properties` version, AGP version in `android/settings.gradle.kts` `plugins` block, `ios/Podfile` `platform :ios` floor.

List the upstream template content at the new tag:

```bash
gh api "repos/flutter/flutter/contents/packages/flutter_tools/templates/app?ref=<new-version>"
```

## 5. Update all lockfiles

```bash
flutter pub get
( cd ios && pod install )
git diff pubspec.yaml pubspec.lock ios/Podfile.lock
```

- `pubspec.yaml` — bump `environment.sdk` if the new Flutter's bundled Dart minor exceeds the current floor. Find the bundled Dart in the Flutter release notes (<https://docs.flutter.dev/install/archive>) or by reading `bin/cache/dart-sdk/version` after running any `flutter` command at the new version.
- `pubspec.lock` — `flutter pub get` rewrites this. The `sdks: dart:` line tracks `pubspec.yaml`.
- `ios/Podfile.lock` — `pod install` rewrites this. CI's `ios-drift` step (`flutter build ios --config-only --no-pub --no-codesign` then `git diff --quiet ios/`) is the source of truth; if you can't run `pod install` locally with the same Xcode CI uses (`Xcode_26.4.app`), let CI report drift via the `ios-drift.patch` artifact and apply it:

  ```bash
  gh run download <run-id> -n ios-drift.patch && git apply ios-drift.patch
  ```

## 6. Commit, push, watch CI

Per `CONTRIBUTING.md`: type `chore` for dependency/config bumps. One follow-up commit on the Renovate branch — leave Renovate's `mise.toml` commit intact.

Stage `.github/actions/setup-project/action.yml` and `.github/renovate.json`. Also stage `pubspec.yaml`, `pubspec.lock`, and `ios/Podfile.lock` if step 5 produced diffs, plus any `android/` or `ios/` changes from step 4.

Commit message: `chore: update hardcoded Flutter version references` — or, when the Dart SDK constraint also moves, `chore: update hardcoded Flutter version references and Dart SDK constraint`.

```bash
git push
gh pr checks <PR>
```

The CI matrix is `prepare`, `analyze`, `android`, `ios`. Wait for all four to pass.
