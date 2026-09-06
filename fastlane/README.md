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

### ios upload_testflight

```sh
[bundle exec] fastlane ios upload_testflight
```

Build and upload to TestFlight (Preview, Daily, or Production RC)

### ios release_prod

```sh
[bundle exec] fastlane ios release_prod
```

Build and upload production release to TestFlight (internal only)

----


## Android

### android build_apk

```sh
[bundle exec] fastlane android build_apk
```

Build release APK

### android build_appbundle

```sh
[bundle exec] fastlane android build_appbundle
```

Build release App Bundle (AAB)

### android upload_firebase

```sh
[bundle exec] fastlane android upload_firebase
```

Upload artifact (APK or AAB) to Firebase App Distribution

### android upload_playstore

```sh
[bundle exec] fastlane android upload_playstore
```

Upload App Bundle (AAB) to Google Play Store

### android preview

```sh
[bundle exec] fastlane android preview
```

Build APK and upload PR preview to Firebase App Distribution

### android daily

```sh
[bundle exec] fastlane android daily
```

Daily release: build APK for Firebase and AAB for Google Play Store (beta track)

### android release_prod

```sh
[bundle exec] fastlane android release_prod
```

Build and upload production release to Google Play Console

### android release

```sh
[bundle exec] fastlane android release
```

Alias for daily release or full release

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
