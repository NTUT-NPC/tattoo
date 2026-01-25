# Project Tattoo

A modern reimplementation of TAT — the course helper app for Taipei Tech students

## What is this?

Project Tattoo is a work-in-progress Flutter app that helps Taipei Tech (NTUT) students access their course schedules and academic information. This is a ground-up reimplementation with a focus on:

- Modern, maintainable code — Clean architecture and best practices
- Developer-friendly — Easy for future club members to understand and contribute
- Concise implementation — No unnecessary complexity

## Getting Started

This project uses [FVM](https://fvm.app/) to manage Flutter versions.

```bash
# Install FVM (if not already installed)
# See https://fvm.app/documentation/getting-started/installation

# Use the project's Flutter version
fvm use

# Install dependencies
fvm flutter pub get

# Run the app
fvm flutter run
```

For IDE configuration (VS Code, Android Studio, IntelliJ), see [FVM IDE Configuration](https://fvm.app/documentation/guides/workflows#ide-configuration).

**VS Code users:** See [.vscode/README.md](.vscode/README.md) for project-specific setup instructions.

## Project Context

This project exists alongside two other implementations:

- [NEO-TAT/tat_flutter](https://github.com/NEO-TAT/tat_flutter) — The original TAT app
- [NTUT-NPC/tat2_flutter](https://github.com/NTUT-NPC/tat2_flutter) (QAQ) — A feature-rich alternative with offline mode, smart session management, and advanced UI

Project Tattoo aims to take lessons learned from both and create a clean, maintainable foundation for future development.
