import 'package:riverpod/riverpod.dart';

/// Compile-time override for demo mode.
///
/// When building with `--dart-define=DEMO=true`, the app starts in demo mode
/// automatically.
const _demoOverride = bool.fromEnvironment('DEMO', defaultValue: false);

/// Runtime toggle for demo mode.
///
/// When true, the application uses mock services and data instead of
/// communicating with the real NTUT servers.
///
/// Enabled automatically via `--dart-define=DEMO=true`, or at runtime
/// by logging in with demo credentials ([demoUsername] / [demoPassword]).
/// Active until logout.
class DemoNotifier extends Notifier<bool> {
  @override
  bool build() => _demoOverride;

  void enable() => state = true;
  void disable() => state = false;
}

final isDemoProvider = NotifierProvider<DemoNotifier, bool>(DemoNotifier.new);

/// Demo account credentials. Only used with mock services — not real NTUT
/// credentials.
const String demoUsername = '111592347';
const String demoPassword = 'password';

/// Whether the given credentials match the demo account.
bool isDemoCredentials(String username, String password) =>
    username == demoUsername && password == demoPassword;
