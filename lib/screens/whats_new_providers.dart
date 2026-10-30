import 'package:pub_semver/pub_semver.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/repositories/preferences_repository.dart';

final whatsNewPromptProvider = NotifierProvider<WhatsNewPromptNotifier, bool>(
  WhatsNewPromptNotifier.new,
);

class WhatsNewPromptNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markPromptScheduled() => state = true;

  Future<bool> shouldPrompt(String version) async {
    if (state) return false;
    final release = _releaseVersion(version);
    final preferences = ref.read(preferencesRepositoryProvider);
    final seen = await preferences.get(PrefKey.lastSeenWhatsNewVersion);
    if (seen.isEmpty) {
      // Establish a baseline without prompting on first initialization.
      await markSeen(version);
      return false;
    }
    try {
      if (_releaseVersion(seen) >= release) return false;
    } on FormatException {
      // Invalid stored versions do not prevent showing the current release.
    }
    final count = await _promptCount(version);
    return !state && count < 5;
  }

  Future<void> recordPromptVisible(String version) async {
    final preferences = ref.read(preferencesRepositoryProvider);
    final count = await _promptCount(version);
    await preferences.set(PrefKey.whatsNewPromptCount, count + 1);
  }

  Future<void> markSeen(String version) => ref
      .read(preferencesRepositoryProvider)
      .set(PrefKey.lastSeenWhatsNewVersion, version);

  Future<int> _promptCount(String version) async {
    final release = _releaseVersion(version);
    final preferences = ref.read(preferencesRepositoryProvider);
    final prompted = await preferences.get(PrefKey.lastPromptedWhatsNewVersion);
    final count = await preferences.get(PrefKey.whatsNewPromptCount);
    try {
      if (_releaseVersion(prompted) == release) return count;
    } on FormatException {
      // Missing or invalid prompt history starts a new release's count.
    }
    await preferences.set(PrefKey.whatsNewPromptCount, 0);
    await preferences.set(
      PrefKey.lastPromptedWhatsNewVersion,
      release.toString(),
    );
    return 0;
  }
}

Version _releaseVersion(String version) {
  final parsed = Version.parse(version);
  return Version(parsed.major, parsed.minor, 0);
}
