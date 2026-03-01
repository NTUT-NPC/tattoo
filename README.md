<!-- markdownlint-disable no-inline-html first-line-heading -->

<p align="center">
  <img src="doc/icon.svg" alt="Tattoo Logo" align="center" width="128" height="128">
</p>

<h1 align="center">Tattoo</h1>

<p align="center">
  A modern reimplementation of TAT — the course helper app for Taipei Tech students
</p>

<p align="center">
  <a href="https://ntut.club">
    <img
      alt="An NPC Project"
      src="https://img.shields.io/badge/An_NPC_Project-333?logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0iI2ZmZiI%2BPHBhdGggZD0iTTQgNHYyNGw4LTggMTYgOFY0bC04IDh6Ii8%2BPC9zdmc%2B"
    >
  </a>
  <a href="https://flutter.dev">
    <img
      alt="Made with Flutter"
      src="https://img.shields.io/badge/Made_with-Flutter-02569B?logo=flutter"
    >
  </a>
  <img
    alt="Works on my machine"
    src="https://img.shields.io/badge/Works_on-My_machine-dark_green"
  >
  <a href="https://translate.ntut.club">
    <img
      alt="Crowdin Translation Progress"
      src="https://badges.crowdin.net/project-tattoo/localized.svg"
    >
  </a>
</p>
  
**Help us translate!** We use [Crowdin](https://translate.ntut.club) to manage localizations. Join the project and help us bring Tattoo to your language!
  
## What is this?

Project Tattoo is a work-in-progress Flutter app that helps Taipei Tech (NTUT) students access their course schedules and academic information. This is a ground-up reimplementation with a focus on:

- Modern, maintainable code — Clean architecture and best practices
- Developer-friendly — Easy for future club members to understand and contribute
- Concise implementation — No unnecessary complexity

## Getting Started

This project uses [mise](https://mise.jdx.dev/) to manage development tools (Flutter, Java, Ruby).

```bash
# Install and activate mise (if not already)
# See: https://mise.jdx.dev/getting-started.html

# Install Flutter, Java, and Ruby
mise install

# Install Flutter dependencies
flutter pub get

# Install Ruby dependencies (fastlane)
bundle install

# Fetch credentials (Firebase configs, keystores)
# Requires a properly configured .env file
dart run tool/credentials.dart fetch

# Run the app
flutter run
```

## Firebase & Credentials

This project uses a private Git repository to manage sensitive credentials (signing keys, service accounts, and Firebase configuration files).

1. **Request Access:** Contact the maintainers for access to the `tattoo-credentials` repository.
2. **Configure `.env`:** Copy `.env.example` to `.env` and fill in the `MATCH_GIT_URL` and `MATCH_PASSWORD`.
3. **Fetch Configs:** Run `dart run tool/credentials.dart fetch`. This will decrypt and place files like `google-services.json` and `keystore.jks` in their respective directories.

### Firebase Setup (Maintainers only)

If you need to reconfigure Firebase:

1. Install the [Firebase CLI](https://firebase.google.com/docs/cli).
2. Install the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup).
3. Run `flutterfire configure` to update `lib/firebase_options.dart`.
4. Encrypt and push new config files using `dart run tool/credentials.dart encrypt <file> <path_in_repo>`.

## Local Development

**Android SDK:** Install [Android Studio](https://developer.android.com/studio) or let Flutter download SDK components automatically on first build.

**VS Code users:** See [.vscode/README.md](.vscode/README.md) for project-specific setup instructions.

**Contributors:** See [CONTRIBUTING.md](CONTRIBUTING.md) for commit and branch guidelines.

## Project Context

Check [AGENTS.md](AGENTS.md) to see detailed architecture notes, implementation status, and future plans.

This project exists alongside two other implementations:

- [NEO-TAT/tat_flutter](https://github.com/NEO-TAT/tat_flutter) — The original TAT app
- [NTUT-NPC/tat2_flutter](https://github.com/NTUT-NPC/tat2_flutter) (QAQ) — A feature-rich alternative with offline mode, smart session management, and advanced UI

Project Tattoo aims to take lessons learned from both and create a clean, maintainable foundation for future development.

## License

Copyright (C) 2026 NTUT Programming Club (NTUT-NPC)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See [LICENSE](LICENSE) for details.
