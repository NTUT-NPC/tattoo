# Project Tattoo

A modern reimplementation of TAT — the course helper app for Taipei Tech students

## What is this?

Project Tattoo is a work-in-progress Flutter app that helps Taipei Tech (NTUT) students access their course schedules and academic information. This is a ground-up reimplementation with a focus on:

- Modern, maintainable code — Clean architecture and best practices
- Developer-friendly — Easy for future club members to understand and contribute
- Concise implementation — No unnecessary complexity

## Getting Started

This project uses [mise](https://mise.jdx.dev/) to manage development tools (Flutter, Java, Android SDK, Ruby).

```bash
# Install mise (if not already installed)
# https://mise.jdx.dev/getting-started.html

# Install all required tools
mise install

# Install Flutter dependencies
flutter pub get

# Install Ruby dependencies (fastlane)
bundle install

# Run the app
flutter run
```

mise automatically activates the correct tool versions when you enter the project directory. No additional IDE configuration needed.

**VS Code users:** See [.vscode/README.md](.vscode/README.md) for project-specific setup instructions.

## Project Context

This project exists alongside two other implementations:

- [NEO-TAT/tat_flutter](https://github.com/NEO-TAT/tat_flutter) — The original TAT app
- [NTUT-NPC/tat2_flutter](https://github.com/NTUT-NPC/tat2_flutter) (QAQ) — A feature-rich alternative with offline mode, smart session management, and advanced UI

Project Tattoo aims to take lessons learned from both and create a clean, maintainable foundation for future development.
