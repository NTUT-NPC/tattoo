import 'package:go_router/go_router.dart';

/// Reports named screens from committed routes, including retained tab revisits.
///
/// Attach once per router. The delegate owns the listener until router disposal.
/// Route templates exclude query values and concrete path parameters.
void trackScreenViews(
  GoRouter router, {
  required void Function(String screenName) onScreenView,
}) {
  String? previousScreen;

  void reportScreen() {
    final delegate = router.routerDelegate;
    if (delegate.currentConfiguration.isEmpty ||
        delegate.currentConfiguration.isError) {
      return;
    }
    final screenName = delegate.state.fullPath;
    if (screenName == null ||
        screenName.isEmpty ||
        screenName == previousScreen) {
      return;
    }
    previousScreen = screenName;
    onScreenView(screenName);
  }

  router.routerDelegate.addListener(reportScreen);
  reportScreen();
}
