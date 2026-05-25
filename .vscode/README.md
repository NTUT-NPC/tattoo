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
| Debug | debug | — |
| Debug with Firebase | debug | `USE_FIREBASE=true` |
| Profile | profile | — |
| Profile with Firebase | profile | `USE_FIREBASE=true` |
| Release | release | — |
| Release with Firebase | release | `USE_FIREBASE=true` |

- **`USE_FIREBASE`** — enables Firebase Analytics and Crashlytics (requires Firebase configs from `tool/credentials.dart`)

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
