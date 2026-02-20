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

### ios build_ipa

```sh
[bundle exec] fastlane ios build_ipa
```

Build and sign release IPA

### ios upload_pr_preview

```sh
[bundle exec] fastlane ios upload_pr_preview
```

Build and upload PR preview to TestFlight Internal Testing

----


## Android

### android build_apk

```sh
[bundle exec] fastlane android build_apk
```

Build and sign release APK

### android build_aab

```sh
[bundle exec] fastlane android build_aab
```

Build and sign release AAB

### android setup_keystore

```sh
[bundle exec] fastlane android setup_keystore
```

Setup credentials for environment

### android upload_dev_firebase

```sh
[bundle exec] fastlane android upload_dev_firebase
```

Distribute development build to Firebase App Distribution (Android)

### android upload_release_playstore

```sh
[bundle exec] fastlane android upload_release_playstore
```

Distribute release build to Google Play Console

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
