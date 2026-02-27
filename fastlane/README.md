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

### ios device

```sh
[bundle exec] fastlane ios device
```

Build, install on connected device, and upload dSYMs

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight

----


## Android

### android preview

```sh
[bundle exec] fastlane android preview
```

Build and upload PR preview to Firebase App Distribution

### android release

```sh
[bundle exec] fastlane android release
```

Build and upload to Google Play Console

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
