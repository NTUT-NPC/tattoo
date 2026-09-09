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

Build and upload to TestFlight

### ios release_production

```sh
[bundle exec] fastlane ios release_production
```

Build and upload the production flavor to internal TestFlight

----


## Android

### android build_apk

```sh
[bundle exec] fastlane android build_apk
```



### android build_appbundle

```sh
[bundle exec] fastlane android build_appbundle
```



### android preview

```sh
[bundle exec] fastlane android preview
```

Build and upload PR preview to Firebase App Distribution

### android release

```sh
[bundle exec] fastlane android release
```

Build and upload to Google Play Console & Firebase

### android release_production

```sh
[bundle exec] fastlane android release_production
```

Build and upload the production flavor to Google Play Internal

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
