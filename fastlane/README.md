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

Build and upload build to TestFlight

----


## Android

### android upload_dev_firebase

```sh
[bundle exec] fastlane android upload_dev_firebase
```

Build and upload development build to Firebase App Distribution

### android upload_release_playstore

```sh
[bundle exec] fastlane android upload_release_playstore
```

Build and upload release build to Google Play Console

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
