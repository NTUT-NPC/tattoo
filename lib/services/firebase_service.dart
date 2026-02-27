/// Global toggle for Firebase features.
///
/// This constant determines if Firebase should be initialized in `main.dart`
/// and if Firebase service should expose a real service instance.
///
/// Defaults to `false` to disable Firebase features by default and avoid
/// package name mismatch issues in debug mode (`club.ntut.tattoo.debug`).
///
/// Can be overridden via: `--dart-define=USE_FIREBASE=true`
const bool useFirebase = bool.fromEnvironment(
  'USE_FIREBASE',
  defaultValue: false,
);
