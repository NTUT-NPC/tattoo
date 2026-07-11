# VS Code Setup

This project uses specific VS Code configurations for consistent development experience.

## Quick Start

Install recommended extensions (VS Code will prompt you, or search `@recommended` in the Extensions panel)

- **Dart** (`dart-code.dart-code`) — Dart language support: analysis, debugging, code completion
- **Flutter** (`dart-code.flutter`) — Flutter development tools: hot reload, device management, widget inspector
- **Mise** (`hverlin.mise-vscode`) — Integration with [mise](https://mise.jdx.dev/) for tool version management (`mise.toml`)
- **YAML** (`redhat.vscode-yaml`) — YAML language support with schema validation (`pubspec.yaml`, slang i18n files)

## Shared Configuration

### `launch.json`

Shared launch configurations for the project:

| Configuration | Mode | Flags |
| --- | --- | --- |
| Debug | debug | `cronetHttpNoPlay=true` |
| Debug with Firebase | debug | `USE_FIREBASE=true`, `cronetHttpNoPlay=true` |
| Profile | profile | `cronetHttpNoPlay=true` |
| Profile with Firebase | profile | `USE_FIREBASE=true`, `cronetHttpNoPlay=true` |
| Release | release | `cronetHttpNoPlay=true` |
| Release with Firebase | release | `USE_FIREBASE=true`, `cronetHttpNoPlay=true` |

- **`USE_FIREBASE`** — enables Firebase Analytics and Crashlytics (requires Firebase configs from `tool/credentials.dart`)
- **`cronetHttpNoPlay`** — bundles Cronet directly instead of using Google Play Services (~2MB APK increase), so AOSP devices (e.g., GrapheneOS) work on campus Wi-Fi

## Switching Flutter SDK after a bump

When `mise.toml`'s `flutter` version changes (e.g. a Renovate bump), VS Code keeps using its previously-resolved SDK. To switch:

1. Set `dart.flutterSdkPaths` in your `settings.json` to the mise tarball directory so VS Code can discover installed SDKs:

   ```json
   {
     "dart.flutterSdkPaths": ["~/.local/share/mise/http-tarballs/"]
   }
   ```

   On Windows, use `~/AppData/Local/mise/http-tarballs/` instead. Use `~` and `/` separators even on Windows.

2. Run **Dart: Change Flutter SDK** from the command palette and pick the version matching `mise.toml`. Reload the window if prompted.

## Optional Configuration

### `settings.json`

This file is gitignored. To run integration tests from the VS Code test runner, create `.vscode/settings.json` with:

```json
{
  "dart.flutterTestAdditionalArgs": [
    "--dart-define-from-file=test/test_config.json"
  ]
}
```
