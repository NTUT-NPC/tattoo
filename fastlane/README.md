fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Build an iOS IPA and stage its Crashlytics inputs

### ios upload_testflight

```sh
[bundle exec] fastlane ios upload_testflight
```

Upload an existing IPA to TestFlight

### ios upload_symbols

```sh
[bundle exec] fastlane ios upload_symbols
```

Upload an existing dSYM archive to Firebase Crashlytics

----


## Android

### android build

```sh
[bundle exec] fastlane android build
```

Build an Android App Bundle and optionally an APK

### android upload_firebase

```sh
[bundle exec] fastlane android upload_firebase
```

Upload an existing App Bundle to Firebase App Distribution

### android upload_play_store

```sh
[bundle exec] fastlane android upload_play_store
```

Upload an existing App Bundle to Google Play

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
