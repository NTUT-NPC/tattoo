import 'package:riverpod/riverpod.dart';

/// Runtime toggle for demo mode.
///
/// When true, the application uses mock services and data instead of
/// communicating with the real NTUT servers.
///
/// This is a runtime-only toggle managed by Riverpod. It is enabled when
/// logging in with the demo account ([demoUsername]) and remains active
/// until the session is destroyed (logout).
///
/// Note: Compile-time demo mode (via `--dart-define`) is no longer supported.
class DemoNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enable() => state = true;
  void disable() => state = false;
}

final isDemoProvider = NotifierProvider<DemoNotifier, bool>(DemoNotifier.new);

/// Demo account credentials.
///
/// These are used exclusively with mock services during demo mode and do not
/// correspond to real NTUT portal credentials.
const String demoUsername = '111592347';
const String demoPassword = 'password';

/// Whether the given credentials should trigger demo mode.
///
/// For convenience, this only checks if the username matches [demoUsername].
/// The password is not validated here, but [demoPassword] is used internally
/// by [AuthRepository] to satisfy mock service requirements.
bool isDemoCredentials(String username, String password) =>
    username == demoUsername;
