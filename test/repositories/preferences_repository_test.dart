import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tattoo/repositories/preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrefKey', () {
    test('all keys have expected types and defaults', () {
      expect(PrefKey.demoMode.type, PrefType.boolean);
      expect(PrefKey.demoMode.defaultValue, false);

      expect(PrefKey.showDangerZone.type, PrefType.boolean);
      expect(PrefKey.showDangerZone.defaultValue, false);

      expect(PrefKey.showWeblateButton.type, PrefType.boolean);
      expect(PrefKey.showWeblateButton.defaultValue, false);

      expect(PrefKey.showWifiButton.type, PrefType.boolean);
      expect(PrefKey.showWifiButton.defaultValue, false);

      expect(PrefKey.showErrorDialog.type, PrefType.boolean);
      expect(PrefKey.showErrorDialog.defaultValue, kDebugMode);

      expect(PrefKey.showCourseSchedule.type, PrefType.boolean);
      expect(PrefKey.showCourseSchedule.defaultValue, true);

      expect(PrefKey.showVoteButton.type, PrefType.boolean);
      expect(PrefKey.showVoteButton.defaultValue, false);

      expect(PrefKey.showScannerButton.type, PrefType.boolean);
      expect(PrefKey.showScannerButton.defaultValue, true);

      expect(PrefKey.showPortalButton.type, PrefType.boolean);
      expect(PrefKey.showPortalButton.defaultValue, true);

      expect(PrefKey.showCalendarButton.type, PrefType.boolean);
      expect(PrefKey.showCalendarButton.defaultValue, true);

      expect(PrefKey.showChangePasswordButton.type, PrefType.boolean);
      expect(PrefKey.showChangePasswordButton.defaultValue, true);

      expect(PrefKey.showChangeAvatarButton.type, PrefType.boolean);
      expect(PrefKey.showChangeAvatarButton.defaultValue, true);
    });

    test('can be written and read from TypedPreferenceStore', () async {
      final originalInstance = SharedPreferencesAsyncPlatform.instance;
      addTearDown(() {
        SharedPreferencesAsyncPlatform.instance = originalInstance;
      });

      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final store = TypedPreferenceStore(SharedPreferencesAsync());

      for (final key in PrefKey.values) {
        expect(await store.read(key), isNull);

        if (key.type == PrefType.boolean) {
          await store.write(key as PrefKey<bool>, true);
          expect(await store.read(key), isTrue);

          await store.write(key, false);
          expect(await store.read(key), isFalse);
        }

        await store.remove(key);
        expect(await store.read(key), isNull);
      }
    });
  });
}
