# VS Code Setup

This project uses specific VS Code configurations for consistent development experience.

## Quick Start

1. Install recommended extensions (VS Code will prompt you, or search `@recommended` in the Extensions panel)

## Optional Configuration

### `launch.json`

If you need to use a MITM proxy for debugging network requests, create a `launch.json` in the `.vscode/` directory with:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "tattoo",
      "request": "launch",
      "type": "dart",
      "toolArgs": [
        "--dart-define=ALLOW_BAD_CERTIFICATES=true"
      ]
    }
  ]
}
```

## Why These Files Are Gitignored

These files may contain environment-specific settings that differ between developers' machines. Each developer should create their own local copies as needed
