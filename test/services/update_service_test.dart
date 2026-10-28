import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/services/update_service.dart';
import 'package:tattoo/utils/pref_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseService originalFirebaseService;

  void setCurrentVersion(String version) {
    PackageInfo.setMockInitialValues(
      appName: 'Tattoo',
      packageName: 'club.ntut.tattoo',
      version: version,
      buildNumber: '1',
      buildSignature: '',
    );
  }

  setUp(() {
    originalFirebaseService = firebaseService;
    setCurrentVersion('2.2.0');
  });

  tearDown(() => firebaseService = originalFirebaseService);

  for (final isForced in [false, true]) {
    for (final requiredVersion in ['2.2', 'latest']) {
      test(
        'startup skips malformed $requiredVersion with force=$isForced',
        () async {
          firebaseService = _UpdateFirebaseService(
            requiredVersion: requiredVersion,
            isForced: isForced,
          );
          final container = ProviderContainer();
          addTearDown(container.dispose);

          await UpdateService.init(container);

          expect(container.read(updateConfigProvider), isNull);
        },
      );
    }

    for (final (currentVersion, needsUpdate) in [
      ('2.1.0', true),
      ('2.2.0-pr.1', true),
      ('2.2.0', false),
      ('2.3.0', false),
    ]) {
      test(
        '$currentVersion against 2.2.0 with force=$isForced',
        () async {
          setCurrentVersion(currentVersion);
          firebaseService = _UpdateFirebaseService(isForced: isForced);

          expect(
            await checkForUpdate(),
            needsUpdate
                ? (
                    isForcedUpdate: isForced,
                    requiredVersion: '2.2.0',
                    detail: 'Release notes',
                  )
                : null,
          );
        },
      );
    }
  }

  test('skips update when the installed version is malformed', () async {
    setCurrentVersion('invalid');
    firebaseService = const _UpdateFirebaseService(isForced: true);

    expect(await checkForUpdate(), isNull);
  });
}

class _UpdateFirebaseService extends FirebaseService {
  const _UpdateFirebaseService({
    this.requiredVersion = '2.2.0',
    required this.isForced,
  });

  final String requiredVersion;
  final bool isForced;

  @override
  ({Object? value, bool isRemote}) getRemoteConfigTyped(
    String key,
    PrefType type,
  ) => switch (key) {
    'latestVersionName' => (value: requiredVersion, isRemote: true),
    'isForceUpdate' => (value: isForced, isRemote: true),
    'updateNote' => (value: 'Release notes', isRemote: true),
    _ => (value: null, isRemote: false),
  };
}
