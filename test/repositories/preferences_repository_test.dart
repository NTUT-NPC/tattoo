import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tattoo/repositories/preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrefKey.showErrorDialog', () {
    test('has expected type and default value', () {
      expect(PrefKey.showErrorDialog.type, PrefType.boolean);
      expect(PrefKey.showErrorDialog.defaultValue, kDebugMode);
    });

    test('can be written and read from TypedPreferenceStore', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final store = TypedPreferenceStore(SharedPreferencesAsync());

      expect(await store.read(PrefKey.showErrorDialog), isNull);

      await store.write(PrefKey.showErrorDialog, true);
      expect(await store.read(PrefKey.showErrorDialog), isTrue);

      await store.write(PrefKey.showErrorDialog, false);
      expect(await store.read(PrefKey.showErrorDialog), isFalse);

      await store.remove(PrefKey.showErrorDialog);
      expect(await store.read(PrefKey.showErrorDialog), isNull);
    });
  });
}
