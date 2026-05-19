import 'package:riverpod/riverpod.dart';

/// Runtime toggle for demo mode.
///
/// When true, the application uses mock services and data instead of
/// communicating with the real NTUT servers.
///
/// This is a runtime-only toggle managed by Riverpod. It is enabled when
/// logging in with the demo account ([demoUsername]) and remains active
/// until the session is destroyed (logout).
class DemoNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final isDemoProvider = NotifierProvider<DemoNotifier, bool>(DemoNotifier.new);

/// Demo account username.
///
/// '111592347' is structurally invalid as an NTUT student ID — class "592"
/// does not exist — so it cannot collide with any real account. Any string
/// entered into the password field is accepted; the password is not validated.
const String demoUsername = '111592347';

/// Whether the given credentials should trigger demo mode.
///
/// Only the username is checked — any password is accepted for the demo
/// account (see [demoUsername]).
bool isDemoCredentials(String username, String password) =>
    username == demoUsername;
