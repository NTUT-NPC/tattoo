import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

export 'package:url_launcher/url_launcher.dart' hide launchUrl;

/// Launches a URL, catching [PlatformException]s that would otherwise be fatal.
///
/// Set [inExternalApplication] to open in the system browser instead of an
/// in-app browser (e.g. to preserve login session cookies).
///
/// When using the default in-app mode, falls back to the external browser if
/// the in-app browser fails (e.g. SFSafariViewController on some iOS versions).
Future<void> launchUrl(Uri url, {bool inExternalApplication = false}) async {
  if (inExternalApplication) {
    await ul.launchUrl(url, mode: .externalApplication);
    return;
  }
  try {
    await ul.launchUrl(url);
  } on PlatformException {
    await ul.launchUrl(url, mode: .externalApplication);
  }
}
